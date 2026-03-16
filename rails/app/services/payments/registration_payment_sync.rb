# frozen_string_literal: true

module Payments
  class RegistrationPaymentSync
    def self.call(payment, audit_logger: SystemAuditLogger)
      registration = payment.temple_registration
      return unless registration
      previous_status = registration.payment_status

      case payment.status
      when TemplePayment::STATUSES[:completed]
        registration.mark_paid! unless registration.paid?
      when TemplePayment::STATUSES[:refunded]
        registration.update!(payment_status: TempleRegistration::PAYMENT_STATUSES[:refunded])
      when TemplePayment::STATUSES[:failed]
        registration.update!(payment_status: TempleRegistration::PAYMENT_STATUSES[:failed])
      end

      return if previous_status == registration.payment_status

      audit_logger.log!(
        action: "system.registrations.payment_status_updated",
        target: registration,
        temple: registration.respond_to?(:temple) ? registration.temple : nil,
        metadata: {
          actor_type: "system",
          registration_reference: registration.respond_to?(:reference_code) ? registration.reference_code : nil,
          payment_id: payment.respond_to?(:id) ? payment.id : nil,
          payment_reference: payment.respond_to?(:provider_reference) ? (payment.provider_reference.presence || payment.id) : nil,
          provider: payment.respond_to?(:provider) ? payment.provider : nil,
          previous_status: previous_status,
          current_status: registration.payment_status
        }.compact
      )
    end
  end
end
