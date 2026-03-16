# frozen_string_literal: true

module Account
  class ContactTempleRequestsController < BaseController
    def create
      @contact_temple_form = Account::ContactTempleRequestForm.new(params: contact_temple_params)

      unless @contact_temple_form.valid?
        render_profile_with_errors(status: :unprocessable_content, alert: "Please check the form and try again.")
        return
      end

      result = Contact::TempleInquirySender.new(
        user: current_user,
        temple: current_temple,
        subject: @contact_temple_form.subject,
        message: @contact_temple_form.message,
        request_id: request.request_id,
        ip: request.remote_ip
      ).call

      if result.success?
        log_contact_request_event!
        redirect_to success_redirect_path, notice: "Your message has been sent to the temple."
      else
        render_profile_with_errors(
          status: :unprocessable_content,
          alert: delivery_failure_alert_for(result)
        )
      end
    end

    private

    def contact_temple_params
      params.require(:account_contact_temple_request_form).permit(:subject, :message, :website)
    end

    def render_profile_with_errors(status:, alert:)
      @form = Account::ProfileForm.new(user: current_user)
      @password_form = Account::PasswordSettingsForm.new(user: current_user)
      @contact_temple_form ||= Account::ContactTempleRequestForm.new
      @dependents = current_user.user_dependents.includes(:dependent)
      flash.now[:alert] = alert
      render "account/profile/show", status: status
    end

    def success_redirect_path
      safe_return_to_path || account_profile_path
    end

    def safe_return_to_path
      path = params[:return_to].to_s
      return if path.blank?
      return unless path.start_with?("/account")
      return if path.start_with?("//")
      return if path.start_with?(account_contact_temple_requests_path)

      path
    end

    def delivery_failure_alert_for(result)
      if Rails.env.development? && result.error_code == :missing_brevo_api_key
        "Missing BREVO_API_KEY in local environment. Add it to .env.development and restart Rails."
      else
        "We could not send your message right now. Please try again later."
      end
    end

    def log_contact_request_event!
      SystemAuditLogger.log!(
        action: "account.contact_temple_requests.created",
        admin: current_user,
        target: current_user,
        temple: current_temple,
        metadata: {
          actor_type: "user",
          source: "account_profile",
          subject_present: @contact_temple_form.subject.present?,
          message_length: @contact_temple_form.message.to_s.length
        }
      )
    end
  end
end
