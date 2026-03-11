# frozen_string_literal: true

module Internal
  class BaseController < ApplicationController
    layout "internal"

    helper_method :current_admin, :internal_operator_email

    before_action :authenticate_admin!
    before_action :authorize_internal_operator!

    private

    def current_admin
      return @current_admin if defined?(@current_admin)

      user_id = session[AppConstants::Sessions.key(:admin)]
      @current_admin =
        if user_id.present?
          User.includes(:admin_account).find_by(id: user_id)
        end
    end

    def authenticate_admin!
      return if current_admin&.admin_account&.active?

      redirect_to admin_login_path, alert: "Please sign in to access internal tools."
    end

    def authorize_internal_operator!
      return if internal_operator_email.present? && current_admin&.email == internal_operator_email

      redirect_to admin_dashboard_path, alert: "You do not have access to internal tools."
    end

    def internal_operator_email
      ENV["INTERNAL_PLATFORM_OPERATOR_EMAIL"].to_s.strip.downcase.presence
    end
  end
end
