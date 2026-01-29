# frozen_string_literal: true

module Api
  module V1
    class TempleGalleriesController < Api::BaseController
      def index
        entries = current_temple.temple_gallery_entries.recent_first.limit(limit)
        render json: {
          entries: entries.map { |entry| serialize_entry(entry) }
        }
      end

      private

      def limit
        value = params[:limit].presence || 10
        value.to_i.clamp(1, 50)
      end

      def serialize_entry(entry)
        {
          id: entry.id,
          title: entry.title,
          body: entry.body,
          event_date: entry.event_date&.iso8601,
          photo_urls: entry.photo_urls
        }
      end
    end
  end
end
