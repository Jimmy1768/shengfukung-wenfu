# frozen_string_literal: true

module Admin
  class GalleryEntriesController < BaseController
    before_action -> { require_capability!(:manage_gallery) }
    before_action :set_gallery_entry, only: %i[edit update destroy]

    def index
      @gallery_entries = current_temple.temple_gallery_entries.order(event_date: :desc, created_at: :desc)
    end

    def new
      @gallery_entry = current_temple.temple_gallery_entries.new(event_date: Date.current)
    end

    before_action :reset_gallery_asset_tracking, only: %i[create update]

    def create
      @gallery_entry = current_temple.temple_gallery_entries.new(gallery_entry_params)
      assign_photo_urls(@gallery_entry)

      if @gallery_entry.save
        cleanup_gallery_assets
        invalidate_gallery_cache!
        redirect_to admin_gallery_entries_path, notice: t("admin.gallery_entries.notices.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @gallery_entry.assign_attributes(gallery_entry_params)
      assign_photo_urls(@gallery_entry)

      if @gallery_entry.save
        # Archived, not destroyed: the photo stops rendering immediately and
        # stays recoverable, which is the gate that makes reclaiming its S3
        # object safe later.
        #
        # Runs after the save as the safer order, not because it is currently
        # load-bearing -- verified by moving it before the save, which changes
        # nothing today. The submitted URL list still contains the removed
        # photo, but photo_urls= only assigns status "active" to a record that
        # already holds it, so autosave writes nothing back. That is incidental,
        # so do not rely on it: keep the removal last.
        archive_removed_photos(@gallery_entry)
        restore_archived_photos(@gallery_entry)
        reorder_photos(@gallery_entry)
        destroy_archived_photos(@gallery_entry)
      end

      if @gallery_entry.persisted? && @gallery_entry.errors.empty?
        cleanup_gallery_assets
        invalidate_gallery_cache!
        redirect_after_update
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @gallery_entry.destroy
      invalidate_gallery_cache!
      redirect_to admin_gallery_entries_path, notice: t("admin.gallery_entries.notices.deleted")
    end

    private

    def set_gallery_entry
      @gallery_entry = current_temple.temple_gallery_entries.find(params[:id])
    end

    def gallery_entry_params
      permitted = params.require(:temple_gallery_entry).permit(:title, :body, :event_date)
      permitted[:event_date] = permitted[:event_date].presence
      permitted
    end

    # Which control was pressed decides where the admin lands. Every submit on
    # this form used to end at the album list, the photo controls included, so
    # moving one photo up navigated out of the album being arranged -- putting
    # twenty photos in order meant twenty trips back into the form. Only Save
    # means "done with this album".
    #
    # Keyed by the parameter each button carries, so a new photo control cannot
    # quietly inherit the Save destination: it has no entry here and would fail
    # the test that covers this.
    PHOTO_ACTION_ANCHORS = {
      "photo_move_up" => %w[moved album-photos],
      "photo_move_down" => %w[moved album-photos],
      "photo_remove" => %w[removed album-photos],
      "photo_restore" => %w[restored album-archived],
      "photo_destroy" => %w[destroyed album-archived]
    }.freeze

    def redirect_after_update
      outcome, anchor = PHOTO_ACTION_ANCHORS.find { |param, _| params[param].present? }&.last

      if outcome
        redirect_to edit_admin_gallery_entry_path(@gallery_entry, anchor:),
          notice: t("admin.gallery_entries.notices.photo_#{outcome}")
      else
        redirect_to admin_gallery_entries_path, notice: t("admin.gallery_entries.notices.updated")
      end
    end

    def archive_removed_photos(entry)
      ids = params[:photo_remove]
      return if ids.blank?

      entry.photos.where(id: Array(ids.keys)).find_each(&:archive!)
      entry.photos.reset
    end

    # Puts an archived photo back on the public page. The counterpart to
    # archive_removed_photos -- archive is only meaningfully reversible if there
    # is a way back, and without this an admin who removed a photo had no way to
    # undo it.
    def restore_archived_photos(entry)
      ids = params[:photo_restore]
      return if ids.blank?

      entry.photos.where(id: Array(ids.keys)).find_each(&:restore!)
      entry.photos.reset
    end

    # One move per submit -- each button carries its own photo id, and a click
    # submits the form, so there is never more than one. The model renumbers the
    # whole run, so positions stay contiguous however often this is used.
    def reorder_photos(entry)
      if (id = params[:photo_move_up]&.keys&.first)
        entry.photos.find_by(id:)&.move_up!
      elsif (id = params[:photo_move_down]&.keys&.first)
        entry.photos.find_by(id:)&.move_down!
      else
        return
      end

      entry.photos.reset
    end

    # The only irreversible operation here, so the scope is narrowed twice: the
    # photo must belong to this entry, and it must already be archived. The
    # archived scope is the gate itself -- a live photo cannot be destroyed by
    # any request, however it is crafted, without being taken down first.
    #
    # Destroying the photo also destroys its MediaAsset, whose after_destroy_commit
    # reclaims the S3 object. A pasted URL has no asset and nothing to reclaim.
    def destroy_archived_photos(entry)
      ids = params[:photo_destroy]
      return if ids.blank?

      entry.photos.archived.where(id: Array(ids.keys)).find_each do |photo|
        asset = photo.media_asset
        photo.destroy!
        asset&.destroy!
      end
      entry.photos.reset
    end

    def assign_photo_urls(entry)
      raw = params.dig(:temple_gallery_entry, :photo_urls_raw).to_s
      urls = raw.split(/\r?\n/).map(&:strip).reject(&:blank?)
      entry.photo_urls = urls
      apply_uploaded_assets(entry, urls)
    end

    def invalidate_gallery_cache!
      state_key = "marketing.archive.#{current_temple.slug}"
      CachePayloads::Invalidator.call(state_keys: state_key)
    rescue NameError
      Rails.logger.info("[GalleryEntriesController] Cache subsystem not initialized for #{state_key}")
    end

    def uploaded_assets_payload
      raw = params.dig(:temple_gallery_entry, :uploaded_assets_payload)
      return [] if raw.blank?

      JSON.parse(raw.to_s)
    rescue JSON::ParserError
      []
    end

    # Links each uploaded file to the photo row that shows it, and reports which
    # uploads ended up attached to nothing.
    #
    # This used to keep the link in entry.metadata["media_asset_ids"] and work
    # out what to detach by matching URL strings against the textarea. That was
    # wrong once photos became rows and deletion became real: the textarea lists
    # only live photos, so **archiving a photo made its asset look detached, and
    # the next ordinary save destroyed it and deleted the file** -- while the row
    # stayed in the archived shelf still offering Restore. Verified before the
    # fix; the S3 delete was genuinely called.
    #
    # The photo row owns the link now. An asset is detached only when no photo of
    # this entry references it, archived ones included, so the only way to
    # release a file is to destroy the photo that holds it.
    def apply_uploaded_assets(entry, urls)
      payload = uploaded_assets_payload
      return if payload.empty? && entry.photos.none?

      asset_ids = payload.filter_map { |item| item["id"] }
      records = current_temple.media_assets.where(id: asset_ids).index_by { |asset| asset.id.to_s }
      url_to_asset = {}
      payload.each do |item|
        asset = records[item["id"].to_s]
        next unless asset&.role.in?(%w[gallery_image gallery_video])

        url_to_asset[item["url"]] = asset.id
      end

      entry.photos.each do |photo|
        next if photo.marked_for_destruction?

        asset_id = url_to_asset[photo.url]
        photo.media_asset_id = asset_id if asset_id
      end

      # Surviving rows of any status keep their asset. Anything uploaded in this
      # submit that no row claims -- an image added then removed before saving --
      # is genuinely orphaned and is released.
      claimed = entry.photos.reject(&:marked_for_destruction?).filter_map(&:media_asset_id).map(&:to_s)
      dropped = entry.photos.select(&:marked_for_destruction?).filter_map(&:media_asset_id).map(&:to_s)
      unclaimed = url_to_asset.values.map(&:to_s) - claimed

      @detached_gallery_asset_ids.concat(dropped + unclaimed)
    end

    def reset_gallery_asset_tracking
      @detached_gallery_asset_ids = []
    end

    def cleanup_gallery_assets
      return if @detached_gallery_asset_ids.blank?

      MediaAsset.where(id: @detached_gallery_asset_ids, temple_id: current_temple.id).destroy_all
    end
  end
end
