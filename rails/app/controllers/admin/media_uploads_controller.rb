# frozen_string_literal: true

module Admin
  class MediaUploadsController < BaseController
    before_action :authorize_upload!

    UPLOAD_CONFIG = {
      "gathering_hero" => {
        capability: :manage_offerings,
        role: :gathering_hero,
        media_type: :image,
        path: "gatherings/hero"
      },
      "gallery_image" => {
        capability: :manage_gallery,
        role: :gallery_image,
        media_type: :image,
        path: "gallery/images"
      },
      "gallery_video" => {
        capability: :manage_gallery,
        role: :gallery_video,
        media_type: :video,
        path: "gallery/videos"
      }
    }.freeze

    def create
      config = upload_config
      asset = MediaAssets::ManagedUploader.new(
        temple: current_temple,
        file: upload_file,
        role: config[:role],
        admin: current_admin,
        media_type: config[:media_type],
        path: config[:path],
        metadata: {
          "context" => params[:context],
          "uploaded_by" => current_admin.id
        }
      ).call

      render json: {
        asset_id: asset.id,
        url: asset.url,
        role: asset.role
      }, status: :ok
    rescue MediaAssets::ManagedUploader::UploadError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    private

    def authorize_upload!
      config = upload_config
      require_capability!(config[:capability])
    end

    def upload_config
      config = UPLOAD_CONFIG[params[:context].to_s]
      raise MediaAssets::ManagedUploader::UploadError, "Unsupported upload context" unless config

      config
    end

    def upload_file
      params.require(:file)
    rescue ActionController::ParameterMissing
      raise MediaAssets::ManagedUploader::UploadError, "File missing"
    end
  end
end
