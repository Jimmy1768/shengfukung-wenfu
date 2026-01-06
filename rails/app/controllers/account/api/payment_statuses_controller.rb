# frozen_string_literal: true

module Account
  module Api
    class PaymentStatusesController < BaseController
      def show
        registration = find_registration
        render json: Account::Api::PaymentStatusSerializer.new(registration).as_json
      end

      private

      def find_registration
        reference = params[:reference].to_s.upcase
        default_registration_scope
          .includes(:temple_offering, :temple_payments)
          .find_by!(reference_code: reference)
      end
    end
  end
end
