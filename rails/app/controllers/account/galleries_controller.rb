# frozen_string_literal: true

module Account
  class GalleriesController < BaseController
    def index
      @entries = gallery_scope
    end

    def show
      @entry = gallery_scope.find(params[:id])
    end

    private

    def gallery_scope
      current_temple.temple_gallery_entries.recent_first
    end
  end
end
