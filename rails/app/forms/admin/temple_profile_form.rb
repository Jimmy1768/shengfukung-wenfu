# frozen_string_literal: true

module Admin
  class TempleProfileForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :name, :string
    attribute :tagline, :string
    attribute :hero_copy, :string
    attribute :contact, default: -> { {} }
    attribute :service_times, default: -> { {} }
    attribute :hero_images, default: -> { {} }
    attribute :visit_info, default: -> { {} }
    attribute :map_link, :string

    validates :name, presence: true

    attr_reader :temple

    def initialize(temple:, params: nil)
      @temple = temple
      attributes = params.presence || extracted_attributes(temple)
      super(attributes)
    end

    def save(current_admin:)
      return false unless valid?

      metadata = merged_metadata(compact_hash(visit_info))

      resolved_contact = resolve_contact_from_map_link
      return false if errors.any?

      contact_payload = contact_info_payload(resolved_contact)

      temple.assign_attributes(
        name:,
        tagline:,
        hero_copy:,
        contact_info: contact_payload,
        service_times: compact_hash(service_times),
        hero_images: normalized_hero_images,
        metadata: metadata
      )

      Temple.transaction do
        temple.save!
        SystemAuditLogger.log!(
          action: "admin.temple.profile.update",
          admin: current_admin,
          target: temple,
          metadata: { contact: contact_payload, service_times:, hero_images: normalized_hero_images, visit_info: visit_info },
          temple:
        )
      end
      true
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    def contact
      super || {}
    end

    def service_times
      super || {}
    end

    def hero_images
      (super || {}).stringify_keys
    end

    def visit_info
      super || {}
    end

    private

    def extracted_attributes(record)
      {
        name: record.name,
        tagline: record.tagline,
        hero_copy: record.hero_copy,
        contact: record.contact_details.slice("phone"),
        service_times: record.service_schedule,
        hero_images: record.hero_images,
        visit_info: record.visit_info,
        map_link: record.contact_details["mapUrl"]
      }
    end

    def compact_hash(value)
      case value
      when ActionController::Parameters
        compact_hash(value.to_unsafe_h)
      when Hash
        value.each_with_object({}) do |(key, val), buffer|
          normalized =
            if val.is_a?(String)
              val.strip.presence
            elsif val.is_a?(Hash)
              compact_hash(val)
            else
              val.presence
            end
          buffer[key] = normalized if normalized.present?
        end
      else
        {}
      end
    end

    def normalized_hero_images
      hero_images.slice(*Temple::HERO_TABS)
    end

    def merged_metadata(visit_data)
      data = temple.metadata.is_a?(Hash) ? temple.metadata.deep_dup : {}
      if visit_data.present?
        data["visit_info"] = visit_data
      else
        data.delete("visit_info")
      end
      data
    end

    def resolve_contact_from_map_link
      return nil if map_link.blank?

      fetcher = Maps::PlaceDetailsFetcher.new(map_link)
      result = fetcher.call
      {
        "addressZh" => result[:address_zh],
        "addressEn" => result[:address_en],
        "plusCode" => result[:plus_code],
        "mapUrl" => result[:map_url],
        "latitude" => result[:latitude],
        "longitude" => result[:longitude],
        "placeId" => result[:place_id]
      }.compact
    rescue Maps::PlaceDetailsFetcher::Error => e
      errors.add(:map_link, e.message)
      nil
    end

    def contact_info_payload(resolved_contact)
      existing = temple.contact_details.deep_dup
      base =
        if resolved_contact.present?
          existing.merge(resolved_contact)
        else
          existing
        end

      phone_value = contact["phone"].presence
      phone_value.blank? ? base.except("phone") : base.merge("phone" => phone_value)
    end
  end
end
