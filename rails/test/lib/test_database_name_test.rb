require "test_helper"

# The test database name is derived per checkout, so two checkouts cannot share
# one database by accident.
#
# Every case passes a path in rather than reading the one this process is
# standing in. That is the point of the module taking an argument: these
# assertions have to mean the same thing in the primary tree and in either
# worktree, and a test that asserted a literal name would be true only where it
# was written. This repository has shipped that defect twice.
class TestDatabaseNameTest < ActiveSupport::TestCase
  BASE = "shengfukung_wenfu"

  # The three checkouts that exist today, as paths rather than as wherever this
  # process happens to be running.
  PRIMARY = "/Users/jimmy1768/Projects/shengfukung-wenfu"
  CONTROL_A = "/Users/jimmy1768/Projects/shengfukung-wenfu-worktrees/shengfukung-wenfu-control-a"
  CONTROL_B = "/Users/jimmy1768/Projects/shengfukung-wenfu-worktrees/shengfukung-wenfu-control-b"

  def name_for(path, **overrides)
    TestDatabaseName.call(**{ checkout_path: path, base: BASE }.merge(overrides))
  end

  # --- criterion 2: the primary tree is unchanged -------------------------

  # Nothing is migrated and nothing is abandoned. The primary checkout's
  # basename equals the project slug, which is what marks it as the one that
  # keeps the plain name.
  test "the primary checkout keeps the unsuffixed name" do
    assert_equal "shengfukung_wenfu_test", name_for(PRIMARY)
  end

  test "a trailing separator does not change the primary's name" do
    assert_equal "shengfukung_wenfu_test", name_for("#{PRIMARY}/")
  end

  # --- criterion 1: distinct per checkout, with nothing to configure ------

  test "each worktree gets its own readable name" do
    assert_equal "shengfukung_wenfu_test_control_a", name_for(CONTROL_A)
    assert_equal "shengfukung_wenfu_test_control_b", name_for(CONTROL_B)
  end

  # This is the assertion that fails if the derivation is removed, and it says
  # what is actually wrong when it does: the checkouts are sharing a database.
  test "the three checkouts that exist today resolve three different databases" do
    names = [PRIMARY, CONTROL_A, CONTROL_B].map { |path| name_for(path) }

    assert_equal names.uniq.length, names.length,
      "two checkouts resolved the same test database name (#{names.join(', ')}). " \
      "They would share one database: two suites running at once collide, and the " \
      "failure reads like a code defect rather than contention."
  end

  test "a worktree created tomorrow is distinct without anyone configuring it" do
    fresh = "/Users/jimmy1768/Projects/shengfukung-wenfu-worktrees/shengfukung-wenfu-hotfix"

    assert_equal "shengfukung_wenfu_test_hotfix", name_for(fresh)
    refute_equal name_for(PRIMARY), name_for(fresh),
      "a new worktree must not share the primary checkout's test database"
  end

  # A checkout whose basename does not start with the slug still gets a name of
  # its own, rather than falling back to the shared one.
  test "a checkout named nothing like the project is still distinct" do
    assert_equal "shengfukung_wenfu_test_scratch", name_for("/tmp/scratch")
    refute_equal name_for(PRIMARY), name_for("/tmp/scratch")
  end

  test "punctuation in a directory name is normalised the way the slug is" do
    assert_equal "shengfukung_wenfu_test_review_2", name_for("/x/Review.2")
  end

  # --- criterion 3: an explicit override still wins -----------------------

  test "PGDATABASE_TEST wins over the derived name, in the primary and in a worktree" do
    assert_equal "explicit_test", name_for(PRIMARY, override: "explicit_test")
    assert_equal "explicit_test", name_for(CONTROL_A, override: "explicit_test")
  end

  test "a blank override is ignored rather than yielding an empty name" do
    assert_equal "shengfukung_wenfu_test_control_a", name_for(CONTROL_A, override: "")
    assert_equal "shengfukung_wenfu_test_control_a", name_for(CONTROL_A, override: "   ")
    assert_equal "shengfukung_wenfu_test_control_a", name_for(CONTROL_A, override: nil)
  end

  # --- the wiring ---------------------------------------------------------

  # The module is inert unless database.yml calls it. Asserted on the source
  # rather than by rendering, because rendering answers for this checkout only.
  test "database.yml derives the test name through this module" do
    source = Rails.root.join("config/database.yml").read
    test_block = source[/^test:.*?(?=\n\w|\z)/m]

    assert_match(/TestDatabaseName\.call/, test_block,
      "database.yml must derive the test database name, or every checkout shares one")
    assert_match(/checkout_path:/, test_block)
    assert_match(/override: ENV\["PGDATABASE_TEST"\]/, test_block)
  end

  # criterion 4, asserted where it cannot drift: development is not derived per
  # checkout and must keep its single shared name.
  test "database.yml leaves the development name alone" do
    source = Rails.root.join("config/database.yml").read
    development = source[/^development:.*?(?=\n\w|\z)/m]

    assert_match(/ENV\.fetch\("PGDATABASE", "#\{db_base\}_dev"\)/, development)
    assert_no_match(/TestDatabaseName/, development,
      "the development database is shared on purpose; only the test name is per-checkout")
  end
end
