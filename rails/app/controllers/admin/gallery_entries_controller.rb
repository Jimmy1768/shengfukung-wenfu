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

    def create
      @gallery_entry = current_temple.temple_gallery_entries.new(gallery_entry_params)
      assign_photo_urls(@gallery_entry)

      if @gallery_entry.save
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
    end

    def invalidate_gallery_cache!
      state_key = "marketing.archive.#{current_temple.slug}"
      CachePayloads::Invalidator.call(state_keys: state_key)
    rescue NameError
      Rails.logger.info("[GalleryEntriesController] Cache subsystem not initialized for #{state_key}")
    end
  end
end
