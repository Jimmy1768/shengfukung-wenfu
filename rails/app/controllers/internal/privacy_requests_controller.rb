# frozen_string_literal: true

module Internal
  class PrivacyRequestsController < BaseController
    before_action :set_privacy_request, only: :transition

    def index
      @status_filter = normalized_status_filter
      @privacy_requests = PrivacyRequest.includes(:user, :operator_user).order(requested_at: :desc, created_at: :desc)
      @privacy_requests = @privacy_requests.where(status: @status_filter) if @status_filter.present?
    end

    def transition
      next_status = normalized_next_status
      unless allowed_transition?(@privacy_request.status, next_status)
        return redirect_to internal_privacy_requests_path(status: params[:status]), alert: t("admin.internal.privacy_requests.flash.invalid_transition")
      end

      @privacy_request.update!(status: next_status, resolved_at: resolved_at_for(next_status), operator_user: current_admin)
      @privacy_request.user.account_lifecycle_events.create!(
        event_type: "privacy_request_status_changed",
        occurred_at: Time.current,
        user_name_snapshot: @privacy_request.user.native_name.presence || @privacy_request.user.english_name.presence || @privacy_request.user.email,
        metadata: {
          "privacy_request_id" => @privacy_request.id,
          "request_type" => @privacy_request.request_type,
          "status" => next_status,
          "operator_user_id" => current_admin.id
        }
      )

      SystemAuditLogger.log!(
        action: "internal.privacy_requests.transition",
        admin: current_admin,
        target: @privacy_request.user,
        metadata: {
          privacy_request_id: @privacy_request.id,
          request_type: @privacy_request.request_type,
          previous_status: @privacy_request.status_before_last_save,
          resulting_status: next_status
        }
      )

      redirect_to internal_privacy_requests_path(status: params[:status]), notice: t("admin.internal.privacy_requests.flash.updated")
    end

    private

    def set_privacy_request
      @privacy_request = PrivacyRequest.find(params[:id])
    end

    def normalized_status_filter
      status = params[:status].to_s
      PrivacyRequest::STATUSES.include?(status) ? status : nil
    end

    def normalized_next_status
      status = params[:next_status].to_s
      return status if PrivacyRequest::STATUSES.include?(status)

      raise ActionController::BadRequest, t("admin.internal.privacy_requests.flash.invalid_transition")
    end

    def allowed_transition?(current_status, next_status)
      case current_status
      when "pending"
        %w[approved rejected completed].include?(next_status)
      when "approved"
        %w[completed rejected].include?(next_status)
      else
        false
      end
    end

    def resolved_at_for(status)
      %w[completed rejected].include?(status) ? Time.current : nil
    end
  end
end
