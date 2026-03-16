# frozen_string_literal: true

module Account
  class PrivacyController < BaseController
    def show
      @privacy_requests = current_user.privacy_requests.order(requested_at: :desc, created_at: :desc)
      @pending_request_types = current_user.privacy_requests.open_requests.pluck(:request_type)
    end

    def close
      ActiveRecord::Base.transaction do
        request_record = current_user.privacy_requests.create!(
          request_type: "account_closure",
          status: "completed",
          submitted_via: "web",
          requested_at: Time.current,
          resolved_at: Time.current,
          metadata: { "reason" => "self_service" }
        )
        current_user.close_account!(reason: "self_service")
        log_privacy_event!(
          action: "account.privacy.account_closed",
          request_record: request_record,
          extra_metadata: { request_type: "account_closure", status: "completed" }
        )
      end

      destroy_user_session!
      redirect_to account_login_path, notice: t("account.privacy.flash.account_closed")
    end

    def request_data_deletion
      create_request!(
        request_type: "data_deletion",
        notice_key: "deletion_requested"
      )
    end

    def request_data_export
      create_request!(
        request_type: "data_export",
        notice_key: "export_requested"
      )
    end

    private

    def create_request!(request_type:, notice_key:)
      if current_user.privacy_requests.open_requests.exists?(request_type: request_type)
        return redirect_to account_privacy_path, alert: t("account.privacy.flash.request_already_open")
      end

      request_record = current_user.privacy_requests.create!(
        request_type: request_type,
        status: "pending",
        submitted_via: "web",
        requested_at: Time.current
      )

      current_user.account_lifecycle_events.create!(
        event_type: "privacy_request_submitted",
        occurred_at: Time.current,
        user_name_snapshot: current_user.native_name.presence || current_user.english_name.presence || current_user.email,
        metadata: { "request_type" => request_type }
      )

      log_privacy_event!(
        action: "account.privacy.requested",
        request_record: request_record,
        extra_metadata: { request_type: request_type, status: "pending" }
      )

      redirect_to account_privacy_path, notice: t("account.privacy.flash.#{notice_key}")
    end

    def log_privacy_event!(action:, request_record:, extra_metadata: {})
      SystemAuditLogger.log!(
        action: action,
        admin: current_user,
        target: request_record,
        temple: current_temple,
        metadata: {
          actor_type: "user",
          source: "account_privacy"
        }.merge(extra_metadata)
      )
    end
  end
end
