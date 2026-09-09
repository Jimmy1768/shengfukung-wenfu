# frozen_string_literal: true

require "test_helper"

# These go through the real form payload rather than assigning media_asset by
# hand. Every earlier test set the association directly, which meant they
# asserted an assumption instead of the system's behaviour and missed two
# defects: uploads never linked to their photo row, and archiving a photo made
# its asset look detached so the next ordinary save deleted the file.
class AdminGalleryUploadAssetLinkTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @admin = create_admin_user(
      temple: @temple,
      role: "admin",
      permission_overrides: { manage_gallery: true }
    )
    sign_in_admin(@admin)

    @entry = @temple.temple_gallery_entries.create!(title: "元宵祝燈")
    @asset = @temple.media_assets.create!(
      role: "gallery_image",
      file_uid: "prod/gallery/uploaded.jpg",
      metadata: { "url" => "https://cdn.test/uploaded.jpg" }
    )
    @deleted_keys = []
  end

  def with_storage_capture(&block)
    Storage::S3Service.stub(:delete, ->(key:) { @deleted_keys << key }, &block)
  end

  def submit(urls:, payload: [{ "id" => @asset.id, "url" => @asset.url }], **extra)
    patch admin_gallery_entry_path(@entry),
      params: {
        temple_gallery_entry: {
          title: @entry.title,
          photo_urls_raw: Array(urls).join("\n"),
          uploaded_assets_payload: payload.to_json
        }
      }.merge(extra)
  end

  test "an uploaded photo is linked to its asset" do
    with_storage_capture { submit(urls: [@asset.url]) }

    photo = @entry.reload.photos.sole
    assert_equal @asset.id, photo.media_asset_id,
      "without this link, deleting the photo cannot reclaim the file"
  end

  # The defect that mattered: archive is only reversible if the file outlives an
  # ordinary save. The admin textarea lists live photos only, so an archived
  # photo looks absent to any logic that reads it.
  test "archiving a photo does not release its file on the next save" do
    with_storage_capture { submit(urls: [@asset.url]) }
    photo = @entry.reload.photos.sole
    photo.archive!

    with_storage_capture { submit(urls: []) }

    assert MediaAsset.exists?(@asset.id), "an archived photo keeps its file"
    assert_empty @deleted_keys, "no object may be deleted by an ordinary save"
    assert @entry.reload.photos.sole.archived?
  end

  test "restoring an archived photo still has a file behind it" do
    with_storage_capture { submit(urls: [@asset.url]) }
    photo = @entry.reload.photos.sole
    photo.archive!
    with_storage_capture { submit(urls: []) }

    with_storage_capture { submit(urls: [], photo_restore: { photo.id.to_s => "1" }) }

    assert_not photo.reload.archived?
    assert_equal @asset.id, photo.media_asset_id
    assert MediaAsset.exists?(@asset.id)
  end

  # An image uploaded and then taken out of the list before saving is attached
  # to nothing, and should not be left behind in the bucket.
  test "an upload no photo claims is released" do
    with_storage_capture { submit(urls: []) }

    assert_not MediaAsset.exists?(@asset.id), "nothing references it, so it is reclaimed"
    assert_equal ["prod/gallery/uploaded.jpg"], @deleted_keys
  end

  test "a save that posts no payload releases nothing" do
    with_storage_capture { submit(urls: [@asset.url]) }

    with_storage_capture { submit(urls: [@asset.url], payload: []) }

    assert MediaAsset.exists?(@asset.id),
      "a submit without the payload must not be read as detachment"
    assert_empty @deleted_keys
  end

  test "destroying the album releases the files its photos held" do
    with_storage_capture { submit(urls: [@asset.url]) }

    with_storage_capture { delete admin_gallery_entry_path(@entry) }

    assert_not MediaAsset.exists?(@asset.id)
    assert_equal ["prod/gallery/uploaded.jpg"], @deleted_keys,
      "after_destroy runs too late to read the rows, so the ids are captured before"
  end
end
