# frozen_string_literal: true

module Admin
  class GatheringsController < BaseController
    before_action -> { require_capability!(:manage_offerings) }
    before_action :set_gathering, only: %i[edit update destroy]

    def index
      @gatherings = current_temple.temple_gatherings.order(
        Arel.sql("COALESCE(temple_gatherings.starts_on, DATE(temple_gatherings.created_at)) DESC, temple_gatherings.created_at DESC")
      )
    end

    def new
      @gathering = current_temple.temple_gatherings.new(status: "draft", currency: "TWD")
    end

    def create
      reset_detached_assets
      @gathering = current_temple.temple_gatherings.new(gathering_params)
      apply_hero_asset(@gathering, hero_asset_param)
      if @gathering.save
        cleanup_detached_assets
        redirect_to admin_gatherings_path, notice: t("admin.gatherings.notices.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      reset_detached_assets
      @gathering.assign_attributes(gathering_params)
      apply_hero_asset(@gathering, hero_asset_param)
      if @gathering.errors.empty? && @gathering.save
        cleanup_detached_assets
        redirect_to admin_gatherings_path, notice: t("admin.gatherings.notices.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @gathering.destroy!
      redirect_to admin_gatherings_path, notice: t("admin.gatherings.notices.deleted")
    rescue ActiveRecord::DeleteRestrictionError
      redirect_to admin_gatherings_path, alert: t("admin.gatherings.notices.delete_restricted")
    end

    private

    def set_gathering
      @gathering = current_temple.temple_gatherings.find(params[:id])
    end

    def gathering_params
      permitted = params.require(:temple_gathering).permit(
        :title,
        :subtitle,
        :description,
        :starts_on,
        :ends_on,
        :start_time,
        :end_time,
        :location_name,
        :location_address,
        :location_notes,
        :status,
        :price_cents,
        :currency,
        :hero_image_url
      )
      permitted[:currency] = permitted[:currency].presence || "TWD"
      permitted[:price_cents] = permitted[:price_cents].presence&.to_i || 0
      permitted[:ends_on] = permitted[:ends_on].presence
      permitted[:start_time] = permitted[:start_time].presence
      permitted[:end_time] = permitted[:end_time].presence
      permitted[:location_notes] = permitted[:location_notes].presence
      permitted
    end

    def hero_asset_param
      params.dig(:temple_gathering, :hero_asset_id)
    end

    def apply_hero_asset(record, asset_id)
      current_asset_id = record.hero_asset_id
      return if asset_id.blank? && current_asset_id.blank?

      if asset_id.present?
        asset = current_temple.media_assets.find_by(id: asset_id)
        unless asset&.role == "gathering_hero"
          record.errors.add(:hero_image_url, t("admin.gatherings.errors.invalid_asset"))
          return
        end
        record.hero_asset_id = asset.id
        record.hero_image_url = asset.url
        queue_asset_for_removal(current_asset_id, except: asset.id)
      else
        record.hero_asset_id = nil
        queue_asset_for_removal(current_asset_id)
      end
    end

    def reset_detached_assets
      @detached_asset_ids = []
    end

    def queue_asset_for_removal(asset_id, except: nil)
      return unless asset_id.present?
      return if except.present? && asset_id.to_s == except.to_s

      @detached_asset_ids << asset_id
    end

    def cleanup_detached_assets
      return if @detached_asset_ids.blank?

      MediaAsset.where(id: @detached_asset_ids, temple_id: current_temple.id).destroy_all
    end
  end
end
