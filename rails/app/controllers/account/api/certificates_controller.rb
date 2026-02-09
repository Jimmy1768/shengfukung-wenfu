# frozen_string_literal: true

module Account
  module Api
    class CertificatesController < BaseController
      def index
        registrations = default_registration_scope
          .with_certificate_number
          .includes(:temple_offering)
          .order(updated_at: :desc)
        render json: {
          certificates: registrations.map { |registration| Account::Api::CertificateSerializer.new(registration).as_json }
        }
      end
    end
  end
end
