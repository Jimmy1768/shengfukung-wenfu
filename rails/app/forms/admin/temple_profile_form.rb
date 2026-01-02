# frozen_string_literal: true

module Admin
  class TempleProfileForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :name, :string
    attribute :tagline, :string
    attribute :hero_copy, :string
    attribute :primary_image_url, :string
    attribute :contact, default: -> { {} }
    attribute :service_times, default: -> { {} }

    validates :name, presence: true

    attr_reader :temple

    def initialize(temple:, params: nil)
      @temple = temple
      attributes = params.presence || extracted_attributes(temple)
      super(attributes)
    end

    def save(current_admin:)
      return false unless valid?

      temple.assign_attributes(
        name:,
        tagline:,
        hero_copy:,
        primary_image_url:,
        contact_info: compact_hash(contact),
        service_times: compact_hash(service_times)
      )

      Temple.transaction do
        temple.save!
        SystemAuditLogger.log!(
          action: "admin.temple.profile.update",
          admin: current_admin,
          target: temple,
          metadata: { contact:, service_times: },
          temple:
        )
      end
      true
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    private

    def contact
      super || {}
    end

    def service_times
      super || {}
    end

    def extracted_attributes(record)
      {
        name: record.name,
        tagline: record.tagline,
        hero_copy: record.hero_copy,
        primary_image_url: record.primary_image_url,
        contact: record.contact_details,
        service_times: record.service_schedule
      }
    end

    def compact_hash(value)
      case value
      when ActionController::Parameters
        value.to_unsafe_h.compact
      when Hash
        value.compact
      else
        {}
      end
    end
  end
end
