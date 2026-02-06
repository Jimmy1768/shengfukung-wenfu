# frozen_string_literal: true

module Api
  module V1
    class TempleEventsController < Api::BaseController
      def index
        events = filtered_scope.order_for_marketing.limit(limit)
        render json: { events: events.map { |event| serialize(event) } }
      end

      def show
        event = current_temple.temple_events.published_visible.find_by!(slug: params[:event_slug])
        render json: { event: serialize(event) }
      end

      private

      def filtered_scope
        base = current_temple.temple_events.published_visible
        case status_filter
        when "past" then base.past_events
        when "all" then base
        else base.upcoming_or_active
        end
      end

      def status_filter
        value = params[:status].to_s.downcase
        return value if %w[upcoming past all].include?(value)

        "upcoming"
      end

      def limit
        value = params[:limit].presence || 20
        value.to_i.clamp(1, 100)
      end

      def serialize(event)
        TempleEventSerializer.new(event).as_json
      end
    end
  end
end
