# frozen_string_literal: true

module Account
  module Api
    class RegistrationsController < BaseController
      def index
        registrations = default_registration_scope
          .includes(:registrable)
          .order(created_at: :desc)
          .limit(limit_param)
        render json: {
          registrations: registrations.map { |registration| Account::Api::RegistrationSerializer.new(registration).as_json }
        }
      end

      private

      def limit_param
        value = params[:limit].to_i
        return 25 if value <= 0

        [value, 50].min
      end
    end
  end
end
