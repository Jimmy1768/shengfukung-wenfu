# frozen_string_literal: true

module Admin
  class PaymentMethodsForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    PAYMENT_MODES = %w[temple platform].freeze
    ECPAY_ENVIRONMENTS = %w[stage production].freeze

    attribute :payment_mode, :string
    attribute :ecpay_merchant_id, :string
    attribute :ecpay_hash_key, :string
    attribute :ecpay_hash_iv, :string
    attribute :ecpay_environment, :string
    attribute :stripe_platform_enabled, :boolean, default: false
    attribute :stripe_platform_fee_bps, :integer
    attribute :stripe_platform_notes, :string

    validates :payment_mode, inclusion: { in: PAYMENT_MODES }
    validates :ecpay_environment, inclusion: { in: ECPAY_ENVIRONMENTS }, allow_blank: true
    validates :stripe_platform_fee_bps,
      numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 10_000, only_integer: true },
      allow_nil: true

    attr_reader :temple

    def initialize(temple:, params: nil)
      @temple = temple
      attributes = params.presence || extracted_attributes.merge(payment_mode: temple.payment_mode.presence || "temple")
      super(attributes)
    end

    def save(current_admin:)
      return false unless valid?

      previous_snapshot = persisted_snapshot
      temple.assign_attributes(
        payment_mode: payment_mode,
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
            payment_mode: payment_mode,
            ecpay_configured: ecpay_configured?,
            stripe_platform_enabled: stripe_platform_enabled
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

    def payment_mode_options
      PAYMENT_MODES.map { |value| [value.titleize, value] }
    end

    def ecpay_configured?
      ecpay_merchant_id.present? && ecpay_hash_key.present? && ecpay_hash_iv.present?
    end

    private

    def extracted_attributes
      ecpay = temple.payment_gateway_settings_for(:ecpay)
      stripe_platform = temple.stripe_platform_settings

      {
        ecpay_merchant_id: ecpay["merchant_id"],
        ecpay_hash_key: ecpay["hash_key"],
        ecpay_hash_iv: ecpay["hash_iv"],
        ecpay_environment: ecpay["environment"].presence || Rails.configuration.x.ecpay.environment.to_s,
        stripe_platform_enabled: stripe_platform["enabled"],
        stripe_platform_fee_bps: stripe_platform["application_fee_bps"],
        stripe_platform_notes: stripe_platform["notes"]
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
      base["stripe_platform"] = compact_hash(
        "enabled" => ActiveModel::Type::Boolean.new.cast(stripe_platform_enabled),
        "application_fee_bps" => stripe_platform_fee_bps,
        "notes" => stripe_platform_notes
      )
      base
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
        payment_mode: payment_mode,
        ecpay: compact_hash(
          "merchant_id" => ecpay_merchant_id,
          "hash_key" => ecpay_hash_key,
          "hash_iv" => ecpay_hash_iv,
          "environment" => ecpay_environment
        ),
        stripe_platform: compact_hash(
          "enabled" => ActiveModel::Type::Boolean.new.cast(stripe_platform_enabled),
          "application_fee_bps" => stripe_platform_fee_bps,
          "notes" => stripe_platform_notes
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
