# frozen_string_literal: true

module Utils
  class UploadsController < Admin::BaseController
    before_action -> { require_capability!(:manage_profile) }
    protect_from_forgery with: :exception

    def create
      result = MediaAssets::HeroImageUploader.call(
        temple: current_temple,
        file: upload_file,
        hero_tab: params[:hero_tab],
        admin: current_admin
      )

      render json: {
        hero_tab: params[:hero_tab],
        url: result[:url],
        asset_id: result[:asset].id
      }, status: :ok
    rescue MediaAssets::HeroImageUploader::UploadError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def upload_file
      params.require(:file)
    rescue ActionController::ParameterMissing
      raise MediaAssets::HeroImageUploader::UploadError, "File missing"
    end
  end
end
