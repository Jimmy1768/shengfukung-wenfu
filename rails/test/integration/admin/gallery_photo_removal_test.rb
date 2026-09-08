# frozen_string_literal: true

require "test_helper"

# Removing one photo from an album was previously only possible by editing a
# textarea of raw URLs -- the same failure mode the hero images had. These cover
# the control that replaced it.
class AdminGalleryPhotoRemovalTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @admin = create_admin_user(
      temple: @temple,
      role: "admin",
      permission_overrides: { manage_gallery: true }
    )
    sign_in_admin(@admin)

    @entry = @temple.temple_gallery_entries.create!(title: "元宵祝燈")
    @keep = @entry.photos.create!(url: "https://example.test/keep.jpg", position: 0)
    @drop = @entry.photos.create!(url: "https://example.test/drop.jpg", position: 1)
  end

  test "the edit form renders a Remove control for each photo" do
    get edit_admin_gallery_entry_path(@entry)

    assert_response :success
    assert_includes response.body, %(name="photo_remove[#{@keep.id}]")
    assert_includes response.body, %(name="photo_remove[#{@drop.id}]")
  end

  test "removing one photo hides it without destroying the row" do
    patch admin_gallery_entry_path(@entry),
      params: {
        temple_gallery_entry: {
          title: @entry.title,
          photo_urls_raw: [@keep.url, @drop.url].join("\n")
        },
        photo_remove: { @drop.id.to_s => "1" }
      }

    assert_redirected_to admin_gallery_entries_path
    assert_equal [@keep.url], @entry.reload.photo_urls, "the removed photo must stop rendering"
    assert TempleGalleryPhoto.exists?(@drop.id), "removal is reversible, so the row must survive"
    assert @drop.reload.archived?
  end

  # The submitted URL list still contains the photo being removed, because the
  # textarea is rendered before the click. The removal has to win.
  test "removal wins over the url list submitted alongside it" do
    patch admin_gallery_entry_path(@entry),
      params: {
        temple_gallery_entry: {
          title: @entry.title,
          photo_urls_raw: [@keep.url, @drop.url].join("\n")
        },
        photo_remove: { @drop.id.to_s => "1" }
      }

    assert_not_includes @entry.reload.photo_urls, @drop.url
  end

  test "a normal save with no removal leaves both photos visible" do
    patch admin_gallery_entry_path(@entry),
      params: {
        temple_gallery_entry: {
          title: "元宵祝燈 2026",
          photo_urls_raw: [@keep.url, @drop.url].join("\n")
        }
      }

    assert_redirected_to admin_gallery_entries_path
    assert_equal 2, @entry.reload.photo_urls.size
    assert_equal "元宵祝燈 2026", @entry.title
  end
end
