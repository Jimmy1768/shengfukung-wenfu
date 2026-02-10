# frozen_string_literal: true

module Api
  module V1
    class TempleGatheringsController < Api::BaseController
      def index
        gatherings = current_temple.temple_gatherings
          .where(status: "published")
          .order(starts_on: :asc)
        render json: { gatherings: gatherings.map { |g| serialize(g) } }
      end

      private

      def serialize(gathering)
        TempleGatheringSerializer.new(gathering).as_json.merge(kind: "gathering")
      end
    end
  end
end
