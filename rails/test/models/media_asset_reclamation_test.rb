# frozen_string_literal: true

require "test_helper"

# Nothing in this application had ever deleted an S3 object. Destroying an asset
# row removed the only record of where the file lived, leaving it in the bucket
# unfindable and permanent. These cover the hook that reclaims it, and -- more
# importantly -- the three cases where it must NOT fire.
class MediaAssetReclamationTest < ActiveSupport::TestCase
  def setup
    @temple = create_temple
    @deleted = []
    @service = Class.new do
      def initialize(sink) = @sink = sink
      def delete(key:) = @sink << key
    end.new(@deleted)
  end

  def with_stubbed_storage
    Storage::S3Service.stub(:delete, ->(key:) { @deleted << key }) { yield }
  end

  test "destroying an asset reclaims its object" do
    asset = @temple.media_assets.create!(role: "gallery_image", file_uid: "prod/gallery/a.jpg")

    with_stubbed_storage { asset.destroy! }

    assert_equal ["prod/gallery/a.jpg"], @deleted
  end

  # Legacy rows store a full URL here. namespaced_key would build
  # "prod/https://..." and address something that was never ours.
  test "a legacy URL-valued file_uid never reaches storage" do
    asset = @temple.media_assets.new(role: "gallery_image", file_uid: "https://placehold.co/x.png")
    asset.save!(validate: false)

    with_stubbed_storage { asset.destroy! }

    assert_empty @deleted, "there is no object of ours behind a pasted URL"
  end

  test "an object still referenced by another asset is left alone" do
    shared = "prod/gallery/shared.jpg"
    first = @temple.media_assets.create!(role: "gallery_image", file_uid: shared)
    @temple.media_assets.create!(role: "gallery_image", file_uid: shared)

    with_stubbed_storage { first.destroy! }

    assert_empty @deleted, "the last row out reclaims it, not the first"
  end

  test "the last asset referencing an object does reclaim it" do
    shared = "prod/gallery/shared.jpg"
    first = @temple.media_assets.create!(role: "gallery_image", file_uid: shared)
    second = @temple.media_assets.create!(role: "gallery_image", file_uid: shared)

    with_stubbed_storage do
      first.destroy!
      second.destroy!
    end

    assert_equal [shared], @deleted
  end

  # The row is already gone by the time this runs; re-raising cannot bring it
  # back, and a leaked object is not a reason to fail the request.
  test "a storage failure is logged, not raised" do
    asset = @temple.media_assets.create!(role: "gallery_image", file_uid: "prod/gallery/boom.jpg")

    Storage::S3Service.stub(:delete, ->(key:) { raise Aws::S3::Errors::NoSuchKey.new(nil, "gone") }) do
      assert_nothing_raised { asset.destroy! }
    end

    assert_not MediaAsset.exists?(asset.id)
  end
end
