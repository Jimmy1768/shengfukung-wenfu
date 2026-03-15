# frozen_string_literal: true

module Account
  class AssistanceRequestsController < BaseController
    def create
      registration = scoped_registration
      existing_request = TempleAssistanceRequest.find_open_for(
        temple: current_temple,
        user: current_user,
        temple_registration: registration
      )

      if existing_request
        redirect_back fallback_location: fallback_location(registration), notice: t("account.assistance_requests.flash.already_open")
        return
      end

      current_temple.temple_assistance_requests.create!(
        user: current_user,
        temple_registration: registration,
        status: "open",
        requested_at: Time.current,
        channel: normalized_channel,
        message: assistance_request_params[:message].presence
      )

      redirect_back fallback_location: fallback_location(registration), notice: t("account.assistance_requests.flash.created")
    end

    private

    def scoped_registration
      registration_id = assistance_request_params[:registration_id].presence
      return nil if registration_id.blank?

      current_user.temple_event_registrations.find_by!(id: registration_id, temple_id: current_temple.id)
    end

    def normalized_channel
      channel = assistance_request_params[:channel].to_s
      return channel if TempleAssistanceRequest::CHANNELS.include?(channel)

      raise ActionController::BadRequest, "Invalid assistance request channel"
    end

    def assistance_request_params
      params.require(:account_assistance_request).permit(:registration_id, :channel, :message)
    end

    def fallback_location(registration)
      registration.present? ? account_registration_path(registration) : account_profile_path
    end
  end
end
