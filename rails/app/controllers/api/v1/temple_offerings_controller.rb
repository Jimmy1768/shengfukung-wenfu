# frozen_string_literal: true

module Api
  module V1
    class TempleOfferingsController < Api::BaseController
      def index
        offerings = filtered_scope
          .order_for_marketing
          .limit(limit)

        render json: { events: offerings.map { |offering| serialize(offering) } }
      end

      def show
        offering = current_temple.temple_offerings.find_by!(slug: params[:event_slug])
        render json: { event: serialize(offering) }
      end

      private

      def filtered_scope
        scope = current_temple.temple_offerings
        case status_filter
        when "past" then scope.past_events
        when "all" then scope
        else scope.upcoming_or_active
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

      def serialize(offering)
        TempleOfferingSerializer.new(offering).as_json
      end
    end
  end
end
