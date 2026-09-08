# frozen_string_literal: true

require "test_helper"

# A gallery photo used to be a string in temple_gallery_entries.photo_urls, with
# its MediaAsset id in a second jsonb array correlated only by position. Nothing
# enforced that pairing, so removing or reordering a single photo was not
# expressible and an album's S3 objects could not be identified after deletion.
class TempleGalleryPhotoTest < ActiveSupport::TestCase
  def setup
    @temple = create_temple
    @entry = @temple.temple_gallery_entries.create!(title: "元宵祝燈")
  end

  test "photo_urls reads from photo rows in position order" do
    @entry.photos.create!(url: "https://example.test/b.jpg", position: 1)
    @entry.photos.create!(url: "https://example.test/a.jpg", position: 0)

    assert_equal %w[https://example.test/a.jpg https://example.test/b.jpg], @entry.reload.photo_urls
  end

  test "archiving hides a single photo without destroying it" do
    keep = @entry.photos.create!(url: "https://example.test/keep.jpg", position: 0)
    drop = @entry.photos.create!(url: "https://example.test/drop.jpg", position: 1)

    drop.archive!
    @entry.reload

    assert_equal [keep.url], @entry.photo_urls, "an archived photo must not render"
    assert TempleGalleryPhoto.exists?(drop.id), "archive is reversible, so the row must survive"

    drop.restore!
    assert_equal 2, @entry.reload.photo_urls.size
  end

  test "reordering changes what renders first" do
    first = @entry.photos.create!(url: "https://example.test/1.jpg", position: 0)
    second = @entry.photos.create!(url: "https://example.test/2.jpg", position: 1)

    first.update!(position: 1)
    second.update!(position: 0)

    assert_equal second.url, @entry.reload.photo_urls.first
  end

  # The reason the rows exist: an uploaded photo keeps its own link to the S3
  # object, rather than the album holding a separate list correlated by index.
  test "a photo keeps its media_asset link when the url list is rewritten" do
    asset = @temple.media_assets.create!(role: "gallery_image", file_uid: "prod/gallery/a.jpg")
    kept = @entry.photos.create!(url: "https://example.test/a.jpg", position: 0, media_asset: asset)
    @entry.photos.create!(url: "https://example.test/gone.jpg", position: 1)

    @entry.photo_urls = ["https://example.test/a.jpg", "https://example.test/new.jpg"]
    @entry.save!
    @entry.reload

    assert_equal %w[https://example.test/a.jpg https://example.test/new.jpg], @entry.photo_urls
    assert_equal asset.id, @entry.photos.find(kept.id).media_asset_id,
      "rewriting the list must not sever a surviving photo from its asset"
    assert_not TempleGalleryPhoto.exists?(url: "https://example.test/gone.jpg")
  end

  test "destroying an album destroys its photos" do
    @entry.photos.create!(url: "https://example.test/a.jpg", position: 0)

    assert_difference -> { TempleGalleryPhoto.count }, -1 do
      @entry.destroy!
    end
  end

  test "status is constrained and url is required" do
    photo = @entry.photos.build(url: "", status: "nonsense")
    assert_not photo.valid?
    assert photo.errors.added?(:url, :blank)
    assert photo.errors.added?(:status, :inclusion, value: "nonsense")
  end
end
