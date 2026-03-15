# frozen_string_literal: true

module Admin
  class AssistanceRequestsController < BaseController
    before_action :set_assistance_request, only: :close

    def index
      @status_filter = normalized_status_filter
      @assistance_requests = assistance_request_scope
      @assistance_requests = @assistance_requests.where(status: @status_filter) if @status_filter.present?
    end

    def close
      @assistance_request.close!(admin_account: current_admin.admin_account)

      SystemAuditLogger.log!(
        action: "admin.assistance_requests.close",
        admin: current_admin,
        target: @assistance_request.user,
        temple: current_temple,
        metadata: {
          assistance_request_id: @assistance_request.id,
          temple_registration_id: @assistance_request.temple_registration_id
        }
      )

      redirect_back fallback_location: admin_assistance_requests_path, notice: t("admin.assistance_requests.flash.closed")
    end

    private

    def assistance_request_scope
      current_temple.temple_assistance_requests.includes(:user, :temple_registration, :closed_by_admin).recent_first
    end

    def set_assistance_request
      @assistance_request = assistance_request_scope.find(params[:id])
    end

    def normalized_status_filter
      status = params[:status].to_s
      TempleAssistanceRequest::STATUSES.include?(status) ? status : nil
    end
  end
end
