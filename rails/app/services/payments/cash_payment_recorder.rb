# frozen_string_literal: true

module Payments
  class CashPaymentRecorder
    def initialize(registration:, admin_user:, amount_cents:, currency:, notes: nil)
      @registration = registration
      @admin_user = admin_user
      @amount_cents = amount_cents.to_i
      @currency = currency.presence || registration.currency
      @notes = notes
    end

    def record!
      TemplePayment.transaction do
        ledger_entry = create_ledger_entry!
        payment = create_payment!(ledger_entry)
        registration.mark_paid!

        SystemAuditLogger.log!(
          action: "temple.payment.cash_recorded",
          admin: admin_user,
          target: payment,
          metadata: {
            amount_cents: amount_cents,
            currency: currency,
            registration_id: registration.id
          },
          temple: registration.temple
        )

        payment
      end
    end

    private

    attr_reader :registration, :admin_user, :amount_cents, :currency, :notes

    def create_payment!(ledger_entry)
      attrs = {
        temple: registration.temple,
        user: registration.user,
        admin_account: admin_user&.admin_account,
        provider: "manual_cash",
        provider_account: "temple",
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        status: TemplePayment::STATUSES[:completed],
        amount_cents: amount_cents,
        currency: currency,
        processed_at: Time.current,
        payment_payload: payment_payload,
        metadata: {}
      }
      attrs[:financial_ledger_entry] = ledger_entry if TemplePayment.column_names.include?("financial_ledger_entry_id")

      registration.temple_payments.create!(attrs)
    end

    def create_ledger_entry!
      FinancialLedgerEntry.create!(
        user: registration.user,
        entry_type: "temple_offering_sale",
        currency: currency,
        country_code: "TW",
        amount: cents_to_decimal(amount_cents),
        tax_amount: 0,
        status: "posted",
        external_reference: external_reference,
        entry_date: Time.current.to_date,
        user_name_snapshot: registration.user&.english_name,
        user_email_snapshot: registration.user&.email,
        details: {
          registration_id: registration.id,
          offering_id: registration.registrable_id,
          payment_method: "cash"
        },
        metadata: {
          recorded_by_admin_id: admin_user&.admin_account&.id
        }
      )
    end

    def cents_to_decimal(cents)
      BigDecimal(cents) / 100
    end

    def external_reference
      registration.reference_code
    end

    def payment_payload
      payload = {}
      payload[:notes] = notes if notes.present?
      payload
    end
  end
end
