# frozen_string_literal: true

module Payments
  class RegistrationPaymentSync
    def self.call(payment)
      registration = payment.temple_registration
      return unless registration

      case payment.status
      when TemplePayment::STATUSES[:completed]
        registration.mark_paid! unless registration.paid?
      when TemplePayment::STATUSES[:refunded]
        registration.update!(payment_status: TempleRegistration::PAYMENT_STATUSES[:refunded])
      when TemplePayment::STATUSES[:failed]
        registration.update!(payment_status: TempleRegistration::PAYMENT_STATUSES[:failed])
      end
    end
  end
end
