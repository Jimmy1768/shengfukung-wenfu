# frozen_string_literal: true

module Admin
  class OfferingsController < BaseController
    before_action :set_offering, only: %i[show edit update]
    before_action :require_manage_offerings!, except: %i[index show]

    def index
      @offerings = current_temple.temple_offerings.order(created_at: :desc)
    end

    def show; end

    def new
      @offering = current_temple.temple_offerings.new
    end

    def create
      @offering = current_temple.temple_offerings.new(offering_params)

      if @offering.save
        log_offering_event("admin.offerings.create")
        redirect_to admin_offering_path(@offering), notice: "Offering created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @offering.update(offering_params)
        log_offering_event("admin.offerings.update")
        redirect_to admin_offering_path(@offering), notice: "Offering updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_offering
      @offering = current_temple.temple_offerings.find(params[:id])
    end

    def require_manage_offerings!
      require_capability!(:manage_offerings)
    end

    def offering_params
      permitted = params.require(:temple_offering).permit(
        :slug,
        :offering_type,
        :title,
        :description,
        :price_cents,
        :currency,
        :period,
        :starts_on,
        :ends_on,
        :available_slots,
        :active,
        metadata_settings: %i[certificate_prefix certificate_hint ancestor_placard_hint logistics_notes]
      )
      permitted[:metadata] = sanitize_metadata_settings(permitted.delete(:metadata_settings))
      permitted
    end

    def sanitize_metadata_settings(raw)
      return {} if raw.blank?

      raw.to_h.transform_values { |value| value.is_a?(String) ? value.strip : value }.compact_blank
    end

    def log_offering_event(action)
      SystemAuditLogger.log!(
        action:,
        admin: current_admin,
        target: @offering,
        metadata: {
          offering_id: @offering.id,
          changes: @offering.previous_changes.except("updated_at", "created_at")
        },
        temple: current_temple
      )
    end
  end
end
