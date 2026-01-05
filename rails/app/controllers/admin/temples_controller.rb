# frozen_string_literal: true

module Admin
  class TemplesController < BaseController
    before_action :ensure_temple!
    before_action :set_line_pay_asset

    skip_before_action :verify_authenticity_token, only: :update

    helper_method :owner_of_current_temple?

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

    def set_line_pay_asset
      return unless current_temple

      @line_pay_asset = current_temple.media_assets.find_by(role: :line_pay_qr)
    end

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

    def owner_of_current_temple?
      return false unless current_admin&.admin_account && current_temple

      @owner_of_current_temple ||= current_admin
        .admin_account
        .admin_temple_memberships
        .where(temple_id: current_temple.id)
        .where(role: AdminTempleMembership.roles[:owner])
        .exists?
    end

    def ensure_temple!
      return if current_temple.present?

      redirect_to admin_dashboard_path, alert: "Temple profile not found. Please run db:seed."
    end
  end
end
