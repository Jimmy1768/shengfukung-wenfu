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
    attribute :about, default: -> { {} }
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

      visit_data = compact_hash(visit_info)
      about_data = normalized_about_content
      metadata = merged_metadata(visit_data:, about_data:)

      resolved_contact = refresh_map_link? ? resolve_contact_from_map_link : nil
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
          metadata: {
            contact: contact_payload,
            service_times:,
            hero_images: normalized_hero_images,
            visit_info: visit_data,
            about: about_data
          },
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

    def about
      return @about_hash if defined?(@about_hash)

      raw = super()
      data =
        case raw
        when ActionController::Parameters
          raw.to_unsafe_h
        when Hash
          raw
        else
          {}
        end
      @about_hash = data.deep_stringify_keys.with_indifferent_access
    end

    def about_card_definitions
      [
        { key: "history", title: "沿革" },
        { key: "deities", title: "主祀 / 配祀" },
        { key: "etiquette", title: "參拜禮儀" }
      ].map do |template|
        {
          key: template[:key],
          title: template[:title],
          body: about_card_bodies[template[:key]] || ""
        }
      end
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
        about: record.about_content,
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

    def merged_metadata(visit_data:, about_data:)
      data = temple.metadata.is_a?(Hash) ? temple.metadata.deep_dup : {}
      if visit_data.present?
        data["visit_info"] = visit_data
      else
        data.delete("visit_info")
      end

      if about_data.present?
        data["about"] = about_data
      else
        data.delete("about")
      end

      data
    end

    def resolve_contact_from_map_link
      fetcher = Maps::PlaceDetailsFetcher.new(map_link)
      result = fetcher.call
      custom_link = normalized_map_link.presence
      {
        "addressZh" => result[:address_zh],
        "addressEn" => result[:address_en],
        "plusCode" => result[:plus_code],
        "mapUrl" => custom_link || result[:map_url],
        "canonicalMapUrl" => result[:map_url],
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

    def normalized_about_content
      raw = about
      return {} if raw.blank?

      normalized = {}
      %i[hero_subtitle].each do |key|
        value = normalized_string(raw[key])
        normalized[key.to_s] = value if value.present?
      end

      card_bodies = about_card_bodies
      cards = about_card_definitions.map do |template|
        body = normalized_string(card_bodies[template[:key]])
        next if body.blank?

        {
          "title" => template[:title],
          "body" => body
        }
      end.compact

      normalized["cards"] = cards if cards.present?
      normalized
    end

    def normalized_string(value)
      return if value.blank?

      string = value.is_a?(String) ? value : value.to_s
      string.strip.presence
    end

    def refresh_map_link?
      normalized_map_link.present? && normalized_map_link != existing_map_link
    end

    def normalized_map_link
      map_link.to_s.strip
    end

    def existing_map_link
      temple.contact_details["mapUrl"].to_s.strip
    end

    def about_card_bodies
      @about_card_bodies ||= begin
        source =
          if about[:cards].present?
            about[:cards]
          else
            temple.about_content["cards"]
          end
        normalized_card_bodies(source)
      end
    end

    def normalized_card_bodies(source)
      result = case source
               when ActionController::Parameters
                 normalized_card_bodies(source.to_unsafe_h)
               when Hash
                 source.each_with_object({}) do |(key, value), buffer|
                   body = extract_card_body(value)
                   buffer[key.to_s] = body if body.present?
                 end
               when Array
                 source.each_with_object({}) do |card, buffer|
                   next if card.blank?

                   key = determine_card_key(card)
                   next unless key

                   body = extract_card_body(card)
                   buffer[key] = body if body.present?
                 end
               else
                 {}
               end
      result.default = ""
      result
    end

    def extract_card_body(value)
      case value
      when ActionController::Parameters
        value[:body] || value["body"]
      when Hash
        value[:body] || value["body"]
      else
        value
      end
    end

    def determine_card_key(card)
      key = card[:key] || card["key"]
      return key if key.present?

      title = card[:title] || card["title"]
      %w[沿革 主祀 / 配祀 參拜禮儀].zip(%w[history deities etiquette]).to_h[title]
    end
  end
end
