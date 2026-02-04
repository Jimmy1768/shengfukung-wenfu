# frozen_string_literal: true

module Admin
  class TemplesController < BaseController
    before_action :ensure_temple!
    before_action -> { require_capability!(:manage_profile) }
    skip_before_action :verify_authenticity_token, only: :update

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
        :map_link,
        hero_images: Temple::HERO_TABS,
        contact: %i[phone],
        service_times: {},
        visit_info: %i[transportation parking],
        about: [
          :hero_subtitle,
          { cards: {
            history: [:body],
            deities: [:body],
            etiquette: [:body]
          } }
        ]
      )
    end

    def ensure_temple!
      return if current_temple.present?

      redirect_to admin_dashboard_path, alert: "Temple profile not found. Please run db:seed."
    end
  end
end
