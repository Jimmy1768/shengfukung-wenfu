# frozen_string_literal: true

module Admin
  class GatheringsController < BaseController
    before_action -> { require_capability!(:manage_offerings) }, except: :index
    before_action :set_gathering, only: %i[edit update destroy]

    def index
      @show_archived = ActiveModel::Type::Boolean.new.cast(params[:archived])
      scope = current_temple.temple_gatherings.order(
        Arel.sql("COALESCE(temple_gatherings.starts_on, DATE(temple_gatherings.created_at)) DESC, temple_gatherings.created_at DESC")
      )
      @gatherings =
        if @show_archived
          scope.where(status: "archived")
        else
          scope.where.not(status: "archived")
        end
    end

    def new
      @gathering = current_temple.temple_gatherings.new(status: "draft", currency: "TWD")
      apply_location_defaults(@gathering)
    end

    def create
      reset_detached_assets
      @gathering = current_temple.temple_gatherings.new(gathering_params)
      apply_free_pricing(@gathering)
      apply_hero_asset(@gathering, hero_asset_param)
      if @gathering.save
        cleanup_detached_assets
        redirect_to admin_gatherings_path, notice: t("admin.gatherings.notices.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      apply_location_defaults(@gathering)
    end

    def update
      reset_detached_assets
      @gathering.assign_attributes(gathering_params)
      apply_free_pricing(@gathering)
      apply_hero_asset(@gathering, hero_asset_param)
      if @gathering.errors.empty? && @gathering.save
        cleanup_detached_assets
        redirect_to admin_gatherings_path, notice: t("admin.gatherings.notices.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @gathering.update(status: "archived")
        redirect_to admin_gatherings_path, notice: t("admin.gatherings.notices.archived")
      else
        redirect_to admin_gatherings_path, alert: t("admin.gatherings.notices.delete_restricted")
      end
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
        :hero_image_url,
        :hero_asset_id,
        :free_gathering
      )
      permitted[:currency] = permitted[:currency].presence || "TWD"
      permitted[:price_cents] = nt_dollars_to_cents(permitted[:price_cents])
      permitted[:price_cents] = 0 if free_gathering_param
      permitted[:ends_on] = permitted[:ends_on].presence
      permitted[:start_time] = permitted[:start_time].presence
      permitted[:end_time] = permitted[:end_time].presence
      permitted[:location_notes] = permitted[:location_notes].presence
      permitted.delete(:free_gathering)
      permitted
    end

    def hero_asset_param
      params.dig(:temple_gathering, :hero_asset_id)
    end

    def free_gathering_param
      value = params.dig(:temple_gathering, :free_gathering)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def nt_dollars_to_cents(value)
      return 0 if value.blank?

      value.to_i * 100
    end

    def apply_free_pricing(record)
      meta = (record.metadata || {}).with_indifferent_access
      if free_gathering_param
        record.price_cents = 0
        meta["free_gathering"] = true
        record.metadata = meta
      else
        meta.delete("free_gathering")
        record.metadata = meta
      end
    end

    def default_location_name
      current_temple.name
    end

    def default_location_address
      details = current_temple.contact_details
      details["addressZh"].presence ||
        details["addressEn"].presence ||
        details["mapUrl"]
    end

    def apply_location_defaults(record)
      record.location_name = default_location_name if record.location_name.blank?
      record.location_address = default_location_address if record.location_address.blank?
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
