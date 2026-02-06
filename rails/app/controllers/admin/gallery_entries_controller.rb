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
        cleanup_gallery_assets
        invalidate_gallery_cache!
        redirect_to admin_gallery_entries_path, notice: t("admin.gallery_entries.notices.updated")
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

    def apply_uploaded_assets(entry, urls)
      payload = uploaded_assets_payload
      previous_ids = entry.media_asset_ids
      return if payload.empty? && previous_ids.empty?

      asset_ids = payload.map { |item| item["id"] }.compact
      records = current_temple.media_assets.where(id: asset_ids).index_by { |asset| asset.id.to_s }
      url_to_asset = {}
      payload.each do |item|
        asset = records[item["id"].to_s]
        next unless asset&.role.in?(%w[gallery_image gallery_video])

        url_to_asset[item["url"]] = asset.id
      end

      used_ids = urls.map { |url| url_to_asset[url]&.to_s }.compact
      entry.media_asset_ids = used_ids

      removed_ids = previous_ids.map(&:to_s) - used_ids
      unused_ids = (url_to_asset.values.map(&:to_s) - used_ids)
      @detached_gallery_asset_ids.concat(removed_ids + unused_ids)
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
