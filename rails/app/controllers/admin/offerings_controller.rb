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
        redirect_to admin_offering_path(@offering), notice: "Offering created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @offering.update(offering_params)
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
      params.require(:temple_offering).permit(
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
        metadata: {}
      )
    end
  end
end
