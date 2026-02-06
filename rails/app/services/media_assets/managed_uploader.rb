# frozen_string_literal: true

module MediaAssets
  class ManagedUploader
    class UploadError < StandardError; end

    IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp image/avif].freeze
    VIDEO_TYPES = %w[video/mp4 video/quicktime video/webm].freeze

    def initialize(temple:, file:, role:, admin:, path:, media_type: :image, metadata: {})
      @temple = temple
      @file = file
      @role = role
      @admin = admin
      @path = path
      @media_type = media_type.to_sym
      @metadata = metadata
    end

    def call
      validate!
      storage_key = Storage::S3Service.upload(
        io: file.tempfile,
        key: object_key,
        content_type: file.content_type
      )
      url = Storage::S3Service.public_url(storage_key)
      asset = create_asset!(storage_key, url)
      log_upload(asset, url)
      asset
    rescue StandardError => e
      Rails.logger.error("ManagedUploader failed: #{e.class} #{e.message}")
      raise UploadError, e.message
    end

    private

    attr_reader :temple, :file, :role, :admin, :path, :media_type, :metadata

    def validate!
      raise UploadError, "No file uploaded" unless file.respond_to?(:tempfile)
      raise UploadError, "Unsupported media type" unless allowed_content_types.include?(file.content_type)
      raise UploadError, "Unsupported upload context" unless MediaAsset.roles.keys.include?(role.to_s)
    end

    def allowed_content_types
      case media_type
      when :video then VIDEO_TYPES
      else IMAGE_TYPES
      end
    end

    def object_key
      extension = File.extname(file.original_filename.to_s).presence || default_extension
      [
        path,
        temple.slug,
        "#{SecureRandom.uuid}#{extension}"
      ].join("/")
    end

    def default_extension
      media_type == :video ? ".mp4" : ".jpg"
    end

    def create_asset!(storage_key, url)
      temple.media_assets.create!(
        role: role,
        file_uid: storage_key,
        metadata: metadata.merge(
          "url" => url,
          "content_type" => file.content_type,
          "filename" => file.original_filename
        )
      )
    end

    def log_upload(asset, url)
      SystemAuditLogger.log!(
        action: "admin.media_asset.upload",
        admin: admin,
        target: temple,
        metadata: {
          role: role,
          asset_id: asset.id,
          file_uid: asset.file_uid,
          url: url
        },
        temple: temple
      )
    end
  end
end
