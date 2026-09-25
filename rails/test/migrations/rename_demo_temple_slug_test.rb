require "test_helper"
require Rails.root.join("db/migrate/20260925000000_rename_demo_temple_slug.rb")

# The demo temple's slug moves from shengfukung-wenfu to shengfukung-demo.
#
# The migration renames in place rather than creating a temple and moving things
# onto it, so the record keeps its temple_id and everything attached by that id
# stays attached. Registrations are the ones that matter: production has three
# on this temple, and a rename that detached them would be discovered by a
# patron, not by a test.
class RenameDemoTempleSlugTest < ActiveSupport::TestCase
  OLD_SLUG = "shengfukung-wenfu"
  NEW_SLUG = "shengfukung-demo"

  def migration
    RenameDemoTempleSlug.new.tap { |m| m.verbose = false }
  end

  test "a temple with registrations keeps them across the rename" do
    temple = create_temple(slug: OLD_SLUG)
    user = create_admin_user(temple: temple)
    offering = create_offering(temple: temple)
    registration = create_registration(user: user, offering: offering)

    migration.up
    temple.reload

    assert_equal NEW_SLUG, temple.slug, "the slug must move"
    assert_equal temple.id, registration.reload.temple_id,
      "the registration detached from its temple. The rename must happen in place, by id: " \
      "a temple renamed by creating a new record leaves its registrations pointing at the old one."
    assert_equal 1, TempleEventRegistration.where(temple_id: temple.id).count
  end

  test "the rename keeps the same record rather than making another" do
    temple = create_temple(slug: OLD_SLUG)

    assert_no_difference -> { Temple.count } do
      migration.up
    end

    assert_equal temple.id, Temple.find_by(slug: NEW_SLUG).id
    assert_nil Temple.find_by(slug: OLD_SLUG)
  end

  # The normal case on a fresh database, in CI, and on any second run.
  test "it is a no-op when the old slug is absent" do
    assert_nil Temple.find_by(slug: OLD_SLUG)

    assert_no_difference -> { Temple.count } do
      migration.up
    end
  end

  test "running it twice changes nothing the second time" do
    temple = create_temple(slug: OLD_SLUG)

    migration.up
    migration.up

    assert_equal NEW_SLUG, temple.reload.slug
    assert_equal 1, Temple.where(slug: NEW_SLUG).count
  end

  # Renaming onto an occupied slug would collapse two temples into one as far as
  # every lookup by slug is concerned.
  test "it refuses to rename onto a slug that already exists" do
    old = create_temple(slug: OLD_SLUG)
    existing = create_temple(slug: NEW_SLUG)

    migration.up

    assert_equal OLD_SLUG, old.reload.slug, "the old temple must be left alone"
    assert_equal NEW_SLUG, existing.reload.slug
    assert_equal 2, Temple.where(slug: [OLD_SLUG, NEW_SLUG]).count
  end

  test "down reverses the rename, in place" do
    temple = create_temple(slug: OLD_SLUG)

    migration.up
    assert_equal NEW_SLUG, temple.reload.slug

    migration.down

    assert_equal OLD_SLUG, temple.reload.slug
    assert_equal temple.id, Temple.find_by(slug: OLD_SLUG).id
  end
end
