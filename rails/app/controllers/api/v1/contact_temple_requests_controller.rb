# frozen_string_literal: true

module Api
  module V1
    class ContactTempleRequestsController < Api::BaseController
      GuestUser = Struct.new(:email, :english_name, :native_name, :id, keyword_init: true)

      def create
        form = PublicContactTempleRequestForm.new(public_contact_params)

        unless form.valid?
          render json: { error: "Please check the form and try again.", errors: form.errors.to_hash(true) }, status: :unprocessable_entity
          return
        end

        rate_limit = Contact::TempleInquiryRateLimiter.call(
          user_id: "guest:#{form.email.downcase}",
          ip: request.remote_ip
        )
        unless rate_limit.allowed?
          render json: { error: "Please wait before sending another message." }, status: :too_many_requests
          return
        end

        result = Contact::TempleInquirySender.new(
          user: GuestUser.new(email: form.email, english_name: form.name, native_name: nil, id: nil),
          guest_name: form.name,
          guest_email: form.email,
          temple: current_temple,
          subject: form.subject,
          message: form.message,
          request_id: request.request_id,
          ip: request.remote_ip
        ).call

        if result.success?
          render json: { message: "Your message has been sent to the temple." }, status: :created
        else
          render json: { error: delivery_failure_error_for(result) }, status: :unprocessable_entity
        end
      end

      private

      def public_contact_params
        params.permit(:name, :email, :subject, :message, :website)
      end

      def delivery_failure_error_for(result)
        if Rails.env.development? && result.error_code == :missing_brevo_api_key
          "Missing BREVO_API_KEY in local environment."
        else
          "We could not send your message right now. Please try again later."
        end
      end

      class PublicContactTempleRequestForm
        include ActiveModel::Model
        include ActiveModel::Attributes

        attribute :name, :string
        attribute :email, :string
        attribute :subject, :string
        attribute :message, :string
        attribute :website, :string

        validates :name, presence: true, length: { maximum: 120 }
        validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 255 }
        validates :subject, presence: true, length: { maximum: 120 }
        validates :message, presence: true, length: { minimum: 10, maximum: 2000 }
        validate :honeypot_blank

        def initialize(attributes = {})
          super(attributes.to_h.transform_keys(&:to_sym))
          self.name = name.to_s.strip
          self.email = email.to_s.strip
          self.subject = subject.to_s.strip
          self.message = message.to_s.strip
          self.website = website.to_s.strip
        end

        private

        def honeypot_blank
          errors.add(:base, "Invalid submission") if website.present?
        end
      end
    end
  end
end
