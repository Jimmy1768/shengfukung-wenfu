# frozen_string_literal: true

module Admin
  class OfferingOrdersController < BaseController
    before_action :require_manage_registrations!
    before_action :set_offering
    before_action :set_registration, only: :show

    def index
      @registrations = @offering.temple_event_registrations.recent
    end

    def new
      @registration = @offering.temple_event_registrations.new(quantity: 1)
    end

    def create
      builder = Payments::OfferingRegistrationBuilder.new(
        temple: current_temple,
        offering: @offering,
        admin_user: current_admin,
        attributes: registration_params
      )

      @registration = builder.create
      redirect_to admin_offering_offering_order_path(@offering, @registration), notice: "Registration created."
    rescue ActiveRecord::RecordInvalid => e
      @registration = e.record
      render :new, status: :unprocessable_entity
    end

    def show; end

    private

    def set_offering
      @offering = current_temple.temple_offerings.find(params[:offering_id])
    end

    def set_registration
      @registration = @offering.temple_event_registrations.find(params[:id])
    end

    def require_manage_registrations!
      require_capability!(:manage_registrations)
    end

    def registration_params
      permitted = params.require(:temple_event_registration).permit(
        :user_id,
        :quantity,
        :unit_price_cents,
        :currency,
        :certificate_number,
        :event_slug
      )
      permitted[:contact_payload] = parse_json_field(:contact_payload)
      permitted[:logistics_payload] = parse_json_field(:logistics_payload)
      permitted[:metadata] = parse_json_field(:metadata)
      permitted
    end

    def parse_json_field(field)
      raw = params[:temple_event_registration][field]
      return {} if raw.blank?

      JSON.parse(raw)
    rescue JSON::ParserError
      {}
    end
  end
end
