# frozen_string_literal: true

module Account
  class EventsController < BaseController
    def index
      @offerings = offerings_scope.map { |offering| build_event_card(offering) }
      @gatherings = gatherings_scope.map { |gathering| build_event_card(gathering) }
      @gallery_entries = gallery_preview_scope.map { |entry| build_gallery_card(entry) }
    end

    private

    def offerings_scope
      current_temple.temple_events
        .upcoming_or_active
        .order_for_marketing
    end

    def gatherings_scope
      current_temple.temple_gatherings
        .where(status: "published")
        .order(
          Arel.sql(
            "COALESCE(temple_gatherings.starts_on, DATE(temple_gatherings.created_at)) ASC"
          )
        )
    end

    def build_event_card(record)
      {
        id: record.id,
        title: record.title,
        date: formatted_date(record.starts_on),
        time_range: formatted_time_range(record),
        location: record_location(record),
        map_url: map_url_for(record),
        status: record.timeline_status,
        description: record.try(:subtitle).presence || record.try(:description),
        image_url: record.try(:hero_image_url).presence,
        cta_path: registration_cta_path(record)
      }
    end

    def build_gallery_card(entry)
      {
        id: entry.id,
        title: entry.title,
        date: formatted_date(entry.event_date),
        description: entry.body.to_s,
        photo_count: entry.photo_urls.count
      }
    end

    def formatted_date(date)
      return I18n.t("account.events.date_tbd") if date.blank?

      I18n.l(date, format: :short)
    end

    def record_location(record)
      return record.location_label if record.respond_to?(:location_label) && record.location_label.present?

      if record.respond_to?(:location_address) && record.location_address.present?
        record.location_address
      else
        current_temple.contact_details&.dig("addressZh") || I18n.t("account.events.default_location")
      end
    end

    def map_url_for(record)
      return unless record.respond_to?(:location_address) && record.location_address.present?

      "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(record.location_address)}"
    end

    def formatted_time_range(record)
      return unless record.respond_to?(:start_time) || record.respond_to?(:end_time)

      starts_at = format_time_value(record.try(:start_time))
      ends_at = format_time_value(record.try(:end_time))
      return if starts_at.blank? && ends_at.blank?

      if starts_at.present? && ends_at.present?
        "#{starts_at} - #{ends_at}"
      else
        starts_at.presence || ends_at
      end
    end

    def format_time_value(value)
      return if value.blank?

      value.respond_to?(:strftime) ? value.strftime("%H:%M") : value.to_s
    end

    def gallery_preview_scope
      current_temple.temple_gallery_entries.recent_first.limit(3)
    end

    def registration_cta_path(record)
      return unless record.respond_to?(:slug) && record.slug.present?

      new_account_registration_path(
        account_action: account_action_for(record),
        offering: record.slug
      )
    rescue ActionController::UrlGenerationError
      nil
    end
  end
end
