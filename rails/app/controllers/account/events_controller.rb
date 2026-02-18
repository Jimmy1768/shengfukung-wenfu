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
        location: record_location(record),
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
