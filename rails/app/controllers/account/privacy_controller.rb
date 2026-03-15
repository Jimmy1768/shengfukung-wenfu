# frozen_string_literal: true

module Account
  class PrivacyController < BaseController
    def show
      @privacy_requests = current_user.privacy_requests.order(requested_at: :desc, created_at: :desc)
    end

    def close
      ActiveRecord::Base.transaction do
        current_user.privacy_requests.create!(
          request_type: "account_closure",
          status: "completed",
          submitted_via: "web",
          requested_at: Time.current,
          resolved_at: Time.current,
          metadata: { "reason" => "self_service" }
        )
        current_user.close_account!(reason: "self_service")
      end

      destroy_user_session!
      redirect_to account_login_path, notice: t("account.privacy.flash.account_closed")
    end
  end
end
