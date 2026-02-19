# frozen_string_literal: true

module Admin
  class RegistrationsController < BaseController
    QUICK_PICK_LIMIT = 6

    before_action :require_manage_registrations!

    def index
      usage_lookup = registration_usage_lookup
      @all_targets = [
        *build_targets(active_offerings(current_temple.temple_events), :events, usage_lookup),
        *build_targets(active_offerings(current_temple.temple_services), :services, usage_lookup),
        *build_targets(active_offerings(current_temple.temple_gatherings), :gatherings, usage_lookup)
      ]
      @quick_pick_targets = @all_targets.first(QUICK_PICK_LIMIT)
      @recent_registrations = current_temple.temple_event_registrations
        .includes(:registrable, :temple_payments)
        .order(created_at: :desc)
        .limit(25)
    end

    private

    def active_offerings(scope)
      scope.where.not(status: "archived").order(:title)
    end

    def build_targets(offerings, kind, usage_lookup)
      offerings
        .map do |offering|
          {
            offering:,
            kind:,
            last_used_at: usage_lookup[[offering.class.name, offering.id]]
          }
        end
        .sort_by do |entry|
          [entry[:last_used_at]&.to_i || 0, entry[:offering].title.to_s.downcase]
        end
        .reverse
    end

    def registration_usage_lookup
      current_temple.temple_event_registrations
        .group(:registrable_type, :registrable_id)
        .maximum(:created_at)
    end

    def require_manage_registrations!
      require_capability!(:manage_registrations)
    end
  end
end
