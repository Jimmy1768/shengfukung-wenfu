# frozen_string_literal: true

module Api
  module V1
    class TempleNewsController < Api::BaseController
      def index
        posts = current_temple.temple_news_posts.published.recent_first.limit(limit)
        render json: {
          news: posts.map { |post| serialize_post(post) }
        }
      end

      private

      def limit
        value = params[:limit].presence || 10
        value.to_i.clamp(1, 50)
      end

      def serialize_post(post)
        {
          id: post.id,
          title: post.title,
          body: post.body,
          published_at: post.published_at&.iso8601
        }
      end
    end
  end
end
