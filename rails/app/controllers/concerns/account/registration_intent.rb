# frozen_string_literal: true

module Account
  module RegistrationIntent
    extend ActiveSupport::Concern

    private

    def registration_search_scope
      return TempleEventRegistration.none unless current_user

      scope = current_user.temple_event_registrations
      current_temple.present? ? scope.where(temple_id: current_temple.id) : scope
    end

    def find_registration_for_offering(offering)
      return nil unless offering

      scope = registration_search_scope.where("metadata ->> 'event_slug' = ?", offering.slug)
      types = registrable_types_for_offering(offering)
      scope = scope.where(registrable_type: types) if types.present?
      scope.order(created_at: :desc).first
    end

    def registrable_types_for_offering(offering)
      return [] unless offering

      classes = [offering.class]
      base_class = offering.class.base_class
      classes << base_class if base_class && base_class != offering.class
      classes.map(&:name).uniq
    end

    def account_action_for(offering)
      case offering
      when TempleService
        "service"
      when TempleGathering
        "gathering"
      else
        "event"
      end
    end

    def find_offering_for_intent(slug, account_action)
      return if slug.blank? || current_temple.blank?

      lookup_order = offering_lookup_order(account_action.to_s)
      lookup_order.each do |type|
        record = find_offering_by_type(type, slug)
        return record if record
      end

      nil
    end

    def offering_lookup_order(action)
      case action
      when "service"
        %i[service event gathering]
      when "gathering"
        %i[gathering event service]
      else
        %i[event service gathering]
      end
    end

    def find_offering_by_type(type, slug)
      return unless current_temple

      case type
      when :service
        current_temple.temple_services.find_by(slug:)
      when :gathering
        current_temple.temple_gatherings.find_by(slug:)
      else
        current_temple.temple_events.find_by(slug:)
      end
    end
  end
end
