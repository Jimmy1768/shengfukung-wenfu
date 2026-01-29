# frozen_string_literal: true

module Admin
  class NewsPostsController < BaseController
    before_action -> { require_capability!(:manage_news) }
    before_action :set_news_post, only: %i[edit update destroy]

    def index
      @news_posts = current_temple.temple_news_posts.order(published_at: :desc, created_at: :desc)
    end

    def new
      @news_post = current_temple.temple_news_posts.new(published: true, published_at: Time.current)
    end

    def create
      @news_post = current_temple.temple_news_posts.new(news_post_params)
      assign_published_timestamp(@news_post)

      if @news_post.save
        invalidate_news_cache!
        redirect_to admin_news_posts_path, notice: t("admin.news_posts.notices.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @news_post.assign_attributes(news_post_params)
      assign_published_timestamp(@news_post)

      if @news_post.save
        invalidate_news_cache!
        redirect_to admin_news_posts_path, notice: t("admin.news_posts.notices.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @news_post.destroy
      invalidate_news_cache!
      redirect_to admin_news_posts_path, notice: t("admin.news_posts.notices.deleted")
    end

    private

    def set_news_post
      @news_post = current_temple.temple_news_posts.find(params[:id])
    end

    def news_post_params
      permitted = params.require(:temple_news_post).permit(:title, :body, :published, :published_at)
      permitted[:published_at] = permitted[:published_at].presence
      permitted
    end

    def assign_published_timestamp(record)
      return unless ActiveModel::Type::Boolean.new.cast(record.published)

      record.published_at ||= Time.current
    end

    def invalidate_news_cache!
      state_key = "marketing.news.#{current_temple.slug}"
      CachePayloads::Invalidator.call(state_keys: state_key)
    rescue NameError
      Rails.logger.info("[NewsPostsController] Cache subsystem not initialized for #{state_key}")
    end
  end
end
