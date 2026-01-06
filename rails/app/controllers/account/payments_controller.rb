# frozen_string_literal: true

module Account
  class PaymentsController < BaseController
    def index
      @payments = current_user.temple_payments
        .includes(temple_event_registration: :temple_offering)
        .order(Arel.sql("COALESCE(temple_payments.processed_at, temple_payments.created_at) DESC"))
    end
  end
end
