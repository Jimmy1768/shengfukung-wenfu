# frozen_string_literal: true

module Api
  module V1
    class TempleServicesController < Api::BaseController
      def index
        services = current_temple.temple_services.published_visible.limit(limit)
        render json: { services: services.map { |service| serialize(service) } }
      end

      def show
        service = current_temple.temple_services.published_visible.find_by!(slug: params[:service_slug])
        render json: { service: serialize(service) }
      end

      private

      def limit
        value = params[:limit].presence || 50
        value.to_i.clamp(1, 100)
      end

      def serialize(service)
        TempleServiceSerializer.new(service).as_json
      end
    end
  end
end
