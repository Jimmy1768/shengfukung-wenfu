# frozen_string_literal: true

module Admin
  class TemplesController < BaseController
    before_action :ensure_temple!

    def edit
      @form = Admin::TempleProfileForm.new(temple: current_temple)
    end

    def update
      @form = Admin::TempleProfileForm.new(temple: current_temple, params: temple_params)

      if @form.save(current_admin:)
        redirect_to admin_temple_profile_path, notice: "Temple profile updated."
      else
        flash.now[:alert] = "Please review the errors below."
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def temple_params
      params.require(:temple).permit(
        :name,
        :tagline,
        :hero_copy,
        :primary_image_url,
        contact: %i[addressZh addressEn phone plusCode mapUrl],
        service_times: {}
      )
    end

    def ensure_temple!
      return if current_temple.present?

      redirect_to admin_dashboard_path, alert: "Temple profile not found. Please run db:seed."
    end
  end
end
