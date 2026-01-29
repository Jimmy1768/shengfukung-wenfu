# frozen_string_literal: true

module MediaAssets
  class HeroImageUploader
    class UploadError < StandardError; end

    def self.call(...)
      new(...).call
    end

    def initialize(temple:, file:, hero_tab:, admin:)
      @temple = temple
      @file = file
      @hero_tab = hero_tab.to_s
      @admin = admin
    end

    def call
      validate!
      storage_key = Storage::S3Service.upload(
        io: file.tempfile,
        key: object_key,
        content_type: file.content_type
      )
      url = Storage::S3Service.public_url(storage_key)
      asset = upsert_media_asset(storage_key, url)
      update_temple_hero_map(url)
      log!(asset, url)
      { url:, asset: }
    rescue StandardError => e
      Rails.logger.error("HeroImageUploader failed: #{e.class} #{e.message}")
      raise UploadError, e.message
    end

    private

    attr_reader :temple, :file, :hero_tab, :admin

    def validate!
      raise UploadError, "No file uploaded" unless file.respond_to?(:tempfile)
      raise UploadError, "Unsupported hero tab" unless Temple::HERO_TABS.include?(hero_tab)
    end

    def object_key
      extension = File.extname(file.original_filename.to_s).presence || ".jpg"
      [
        "hero-images",
        temple.slug,
        hero_tab,
        "#{SecureRandom.uuid}#{extension}"
      ].join("/")
    end

    def upsert_media_asset(storage_key, url)
      asset = existing_asset || temple.media_assets.hero.new
      asset.tap do
        asset.role = :hero_image
        asset.file_uid = storage_key
        meta = (asset.metadata || {}).merge("hero_tab" => hero_tab, "url" => url)
        asset.metadata = meta
        asset.save!
      end
    end

    def existing_asset
      temple.media_assets.hero.where("metadata ->> 'hero_tab' = ?", hero_tab).first
    end

    def update_temple_hero_map(url)
      images = temple.hero_images.dup
      images[hero_tab] = url
      temple.update!(hero_images: images)
    end

    def log!(asset, url)
      SystemAuditLogger.log!(
        action: "admin.temple.profile.hero_image.upload",
        admin: admin,
        target: temple,
        metadata: {
          hero_tab: hero_tab,
          asset_id: asset.id,
          file_uid: asset.file_uid,
          url: url
        },
        temple: temple
      )
    end
  end
end
