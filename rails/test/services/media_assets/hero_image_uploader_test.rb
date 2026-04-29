# frozen_string_literal: true

require "test_helper"

class MediaAssets::HeroImageUploaderTest < ActiveSupport::TestCase
  test "stores hero images under uploads namespace" do
    temple = create_temple(slug: "shengfukung-wenfu")
    admin = create_admin_user(temple: temple, role: "owner")
    uploaded_file = Rack::Test::UploadedFile.new(
      Rails.root.join("public/backend/assets/admin/hero-placeholder.svg"),
      "image/svg+xml"
    )
    captured_key = nil

    upload = lambda do |io:, key:, content_type:|
      captured_key = key
      assert io
      assert_equal "image/svg+xml", content_type
      key
    end

    public_url = lambda do |key|
      "https://cdn.example.test/#{key}"
    end

    Storage::S3Service.stub(:upload, upload) do
      Storage::S3Service.stub(:public_url, public_url) do
        MediaAssets::HeroImageUploader.call(
          temple: temple,
          file: uploaded_file,
          hero_tab: "home",
          admin: admin
        )
      end
    end

    assert_match %r{\Auploads/hero-images/shengfukung-wenfu/home/[0-9a-f-]+\.svg\z}, captured_key
    assert_equal captured_key, temple.media_assets.hero.first.file_uid
    assert_equal "https://cdn.example.test/#{captured_key}", temple.reload.hero_images["home"]
  end
end
