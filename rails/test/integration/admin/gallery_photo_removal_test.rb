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

  test "an archived photo appears in the archived shelf with a Restore control" do
    @drop.archive!

    get edit_admin_gallery_entry_path(@entry)

    assert_response :success
    assert_includes response.body, %(name="photo_restore[#{@drop.id}]")
    assert_not_includes response.body, %(name="photo_remove[#{@drop.id}]"),
      "an archived photo belongs in the shelf, not in the live set"
  end

  test "restoring puts the photo back on the public page" do
    @drop.archive!

    patch admin_gallery_entry_path(@entry),
      params: {
        temple_gallery_entry: { title: @entry.title, photo_urls_raw: @keep.url },
        photo_restore: { @drop.id.to_s => "1" }
      }

    assert_redirected_to admin_gallery_entries_path
    assert_includes @entry.reload.photo_urls, @drop.url
    assert_not @drop.reload.archived?
  end

  # The admin textarea lists only live photos, so a plain save presents the
  # archived photo as absent. It must not be destroyed by that.
  test "an archived photo survives a later save that does not mention it" do
    @drop.archive!

    patch admin_gallery_entry_path(@entry),
      params: { temple_gallery_entry: { title: "later edit", photo_urls_raw: @keep.url } }

    assert_redirected_to admin_gallery_entries_path
    assert TempleGalleryPhoto.exists?(@drop.id),
      "archive is only reversible if the row survives ordinary saves"
    assert @drop.reload.archived?
    assert_equal [@keep.url], @entry.reload.photo_urls
  end

  test "the form offers move controls, disabled at each end" do
    get edit_admin_gallery_entry_path(@entry)

    assert_response :success
    assert_includes response.body, %(name="photo_move_down[#{@keep.id}]")
    assert_includes response.body, %(name="photo_move_up[#{@drop.id}]")
    # first cannot move up, last cannot move down
    assert_match %r{name="photo_move_up\[#{@keep.id}\]"[^>]*disabled}m, response.body
    assert_match %r{name="photo_move_down\[#{@drop.id}\]"[^>]*disabled}m, response.body
  end

  test "moving a photo down changes the public order" do
    assert_equal [@keep.url, @drop.url], @entry.photo_urls

    patch admin_gallery_entry_path(@entry),
      params: {
        temple_gallery_entry: { title: @entry.title, photo_urls_raw: [@keep.url, @drop.url].join("\n") },
        photo_move_down: { @keep.id.to_s => "1" }
      }

    assert_redirected_to admin_gallery_entries_path
    assert_equal [@drop.url, @keep.url], @entry.reload.photo_urls
  end

  # Positions drift as photos are archived, so a move has to renumber rather
  # than increment, or the order stops meaning anything.
  test "reordering ignores archived photos and leaves positions contiguous" do
    third = @entry.photos.create!(url: "https://example.test/third.jpg", position: 2)
    @drop.archive!

    patch admin_gallery_entry_path(@entry),
      params: {
        temple_gallery_entry: { title: @entry.title, photo_urls_raw: [@keep.url, third.url].join("\n") },
        photo_move_up: { third.id.to_s => "1" }
      }

    @entry.reload
    assert_equal [third.url, @keep.url], @entry.photo_urls
    assert_equal [0, 1], @entry.photos.active.ordered.map(&:position)
    assert @drop.reload.archived?, "an archived photo takes no place in the order"
  end

  test "Delete is offered only in the archived shelf, never beside a live photo" do
    @drop.archive!

    get edit_admin_gallery_entry_path(@entry)

    assert_response :success
    assert_includes response.body, %(name="photo_destroy[#{@drop.id}]")
    assert_not_includes response.body, %(name="photo_destroy[#{@keep.id}]"),
      "a live photo must not offer an irreversible control"
  end

  # The gate, asserted at the request level rather than only in the markup: not
  # rendering a button is presentation, refusing the request is the rule.
  test "a live photo cannot be destroyed even if the request asks" do
    patch admin_gallery_entry_path(@entry),
      params: {
        temple_gallery_entry: { title: @entry.title, photo_urls_raw: [@keep.url, @drop.url].join("\n") },
        photo_destroy: { @keep.id.to_s => "1" }
      }

    assert TempleGalleryPhoto.exists?(@keep.id),
      "destroying must require the photo to be archived first"
    assert_includes @entry.reload.photo_urls, @keep.url
  end

  test "destroying an archived photo removes the row and its asset" do
    asset = @temple.media_assets.create!(role: "gallery_image", file_uid: "prod/gallery/drop.jpg")
    @drop.update!(media_asset: asset)
    @drop.archive!

    patch admin_gallery_entry_path(@entry),
      params: {
        temple_gallery_entry: { title: @entry.title, photo_urls_raw: @keep.url },
        photo_destroy: { @drop.id.to_s => "1" }
      }

    assert_redirected_to admin_gallery_entries_path
    assert_not TempleGalleryPhoto.exists?(@drop.id)
    assert_not MediaAsset.exists?(asset.id), "the asset row owns the object, so it goes too"
    assert_equal [@keep.url], @entry.reload.photo_urls
  end

  # Album deletion destroys every photo and reclaims every file at once. The
  # control was a link_to with method: :delete, which needs rails-ujs -- absent
  # here, so the confirmation modal fired and then the browser followed the href
  # as a GET to #show and 404ed. Deleting an album had never worked.
  test "the index deletes through a real form, not an inert link" do
    get admin_gallery_entries_path

    assert_response :success
    assert_match %r{<form[^>]*action="#{Regexp.escape(admin_gallery_entry_path(@entry))}"}, response.body
    assert_includes response.body, %(name="_method" value="delete")
    assert_includes response.body, I18n.t("admin.gallery_entries.confirmations.delete")
  end

  test "deleting an album destroys it and its photos" do
    assert_difference -> { TempleGalleryEntry.count }, -1 do
      assert_difference -> { TempleGalleryPhoto.count }, -2 do
        delete admin_gallery_entry_path(@entry)
      end
    end

    assert_redirected_to admin_gallery_entries_path
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
