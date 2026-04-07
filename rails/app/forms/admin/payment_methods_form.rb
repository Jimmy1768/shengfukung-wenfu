# frozen_string_literal: true

module Admin
  class PaymentMethodsForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    ECPAY_ENVIRONMENTS = %w[stage production].freeze
    DEFAULT_BILLING_MONTHLY_FEE_CENTS = 500_000
    DEFAULT_BILLING_GRACE_DAYS = 30
    DEFAULT_ECPAY_PORTAL_URL = "https://login.ecpay.com.tw/Login?Mode=1&NextURL=https%3A%2F%2Fcashier.ecpay.com.tw%2Fmanage%2Flogin%2Fecpay%2Fcallback"

    attribute :ecpay_merchant_id, :string
    attribute :ecpay_hash_key, :string
    attribute :ecpay_hash_iv, :string
    attribute :ecpay_environment, :string
    attribute :billing_payment_method_on_file, :boolean, default: false

    validates :ecpay_environment, inclusion: { in: ECPAY_ENVIRONMENTS }, allow_blank: true

    attr_reader :temple

    def initialize(temple:, params: nil)
      @temple = temple
      super(params.presence || extracted_attributes)
    end

    def save(current_admin:)
      return false unless valid?

      previous_snapshot = persisted_snapshot
      temple.assign_attributes(
        payment_mode: temple.payment_mode.presence || "temple",
        payment_provider_settings: merged_provider_settings
      )

      Temple.transaction do
        temple.save!
        SystemAuditLogger.log!(
          action: "admin.payment_methods.updated",
          admin: current_admin,
          target: temple,
          temple: temple,
          metadata: {
            changed_fields: changed_fields(previous_snapshot, snapshot_for_audit),
            ecpay_configured: ecpay_configured?,
            billing_payment_method_on_file: billing_payment_method_on_file?
          }
        )
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    def ecpay_environment_options
      ECPAY_ENVIRONMENTS.map { |value| [value.titleize, value] }
    end

    def ecpay_configured?
      ecpay_merchant_id.present? && ecpay_hash_key.present? && ecpay_hash_iv.present?
    end

    def billing_payment_method_on_file?
      ActiveModel::Type::Boolean.new.cast(billing_payment_method_on_file)
    end

    def billing_portal_url
      temple.billing_portal_url
    end

    def billing_monthly_fee_cents
      temple.billing_monthly_fee_cents
    end

    def billing_monthly_fee_label
      Currency::Symbols.format_amount(billing_monthly_fee_cents, "TWD")
    end

    def billing_grace_days
      temple.billing_grace_days
    end

    def billing_grace_remaining_days
      temple.billing_grace_remaining_days
    end

    def online_payments_frozen?
      temple.online_payments_frozen?
    end

    def online_payments_state
      return :setup_needed unless ecpay_configured?
      return :active if billing_payment_method_on_file?
      return :frozen if online_payments_frozen?

      :grace_period
    end

    def online_payments_status_i18n_key
      case online_payments_state
      when :setup_needed
        "setup_incomplete"
      when :active
        "active"
      when :frozen
        "billing_overdue"
      else
        "grace_period"
      end
    end

    def online_payments_status_i18n_options
      return {} unless online_payments_state == :grace_period

      { days: billing_grace_remaining_days || billing_grace_days }
    end

    def online_payments_status_tone
      case online_payments_state
      when :setup_needed
        "neutral"
      when :active
        "success"
      when :frozen
        "danger"
      else
        "warning"
      end
    end

    def ecpay_status_i18n_key
      ecpay_configured? ? "ready_to_test" : "setup_needed"
    end

    def ecpay_status_tone
      ecpay_configured? ? "success" : "warning"
    end

    def ecpay_portal_url
      ENV.fetch("ECPAY_PORTAL_URL", DEFAULT_ECPAY_PORTAL_URL).to_s
    end

    private

    def extracted_attributes
      ecpay = temple.payment_gateway_settings_for(:ecpay)

      {
        ecpay_merchant_id: ecpay["merchant_id"],
        ecpay_hash_key: ecpay["hash_key"],
        ecpay_hash_iv: ecpay["hash_iv"],
        ecpay_environment: ecpay["environment"].presence || Rails.configuration.x.ecpay.environment.to_s,
        billing_payment_method_on_file: temple.billing_payment_method_on_file?
      }
    end

    def persisted_snapshot
      self.class.new(temple: temple).send(:snapshot_for_audit)
    end

    def merged_provider_settings
      base = temple.payment_provider_settings.is_a?(Hash) ? temple.payment_provider_settings.deep_dup : {}
      base["ecpay"] = compact_hash(
        "merchant_id" => ecpay_merchant_id,
        "hash_key" => ecpay_hash_key,
        "hash_iv" => ecpay_hash_iv,
        "environment" => ecpay_environment
      )
      base["billing"] = compact_hash(
        "payment_method_on_file" => billing_payment_method_on_file?,
        "portal_url" => temple.billing_portal_url,
        "monthly_fee_cents" => DEFAULT_BILLING_MONTHLY_FEE_CENTS,
        "grace_days" => DEFAULT_BILLING_GRACE_DAYS,
        "grace_started_at" => billing_grace_started_at_value
      )
      base
    end

    def billing_grace_started_at_value
      return nil unless ecpay_configured?
      return nil if billing_payment_method_on_file?

      temple.billing_grace_started_at&.iso8601 || Time.current.iso8601
    end

    def compact_hash(hash)
      hash.each_with_object({}) do |(key, value), result|
        normalized = value.is_a?(String) ? value.strip.presence : value
        next if normalized.nil?

        result[key] = normalized
      end
    end

    def snapshot_for_audit
      {
        ecpay: compact_hash(
          "merchant_id" => ecpay_merchant_id,
          "hash_key" => ecpay_hash_key,
          "hash_iv" => ecpay_hash_iv,
          "environment" => ecpay_environment
        ),
        billing: compact_hash(
          "payment_method_on_file" => billing_payment_method_on_file?,
          "portal_url" => temple.billing_portal_url,
          "monthly_fee_cents" => DEFAULT_BILLING_MONTHLY_FEE_CENTS,
          "grace_days" => DEFAULT_BILLING_GRACE_DAYS,
          "grace_started_at" => billing_grace_started_at_value
        )
      }
    end

    def changed_fields(before_snapshot, after_snapshot)
      before_snapshot.each_with_object([]) do |(key, value), changed|
        changed << key.to_s if value != after_snapshot[key]
      end
    end
  end
end
