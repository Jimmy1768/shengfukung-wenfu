# frozen_string_literal: true

# Derives a test database name that is distinct per checkout.
#
# Why. The primary tree and both Control worktrees resolved
# `shengfukung_wenfu_test` identically, because the name came from the project
# slug and nothing else. One database with three users: two suites running at
# once collide, and the failure reads like a code defect rather than contention
# -- it cost an hour on 2026-09-13. It also blocks the removal half of the
# disposable-test-database rule, because a teardown drop would land on whichever
# checkout happened to be mid-suite.
#
# The derivation is from the checkout directory itself, so there is no file to
# create and nothing to remember: a worktree made tomorrow is distinct on its
# first run without anyone configuring it. Answering this with a per-checkout
# `.env` would reintroduce exactly the thing being removed -- something a person
# has to remember, and can forget.
#
# The primary tree keeps `shengfukung_wenfu_test` unchanged. Its directory
# basename equals the project slug and a worktree's does not, which is the
# distinction available without a config file. Nothing is migrated and nothing
# is abandoned.
#
# It takes the path rather than reading `Rails.root` for the same reason
# TestDatabaseProvisioner takes collaborators: a contract test that asserted a
# literal name would pass only in the checkout it was written in, and a check
# that passes only where you happen to be standing is a defect this repository
# has already shipped twice.
module TestDatabaseName
  module_function

  # checkout_path - the repository checkout root (not the rails/ directory)
  # base          - the slug-derived database base, e.g. "shengfukung_wenfu"
  # override      - PGDATABASE_TEST, which wins outright when present
  def call(checkout_path:, base:, override: nil)
    explicit = override.to_s.strip
    return explicit unless explicit.empty?

    suffix = suffix_for(checkout_path: checkout_path, base: base)
    suffix.empty? ? "#{base}_test" : "#{base}_test_#{suffix}"
  end

  # "" for the primary checkout, a readable per-worktree tag otherwise.
  #
  # Readable rather than hashed on purpose. A stray database has to be
  # attributable on sight -- `shengfukung_wenfu_test_control_a` says which
  # checkout owns it, where a digest would say only that something owned it
  # once. Finding strays is a listing checked against a table, and that only
  # works if the names mean something.
  def suffix_for(checkout_path:, base:)
    name = normalize(File.basename(checkout_path.to_s))
    return "" if name.empty? || name == base

    prefix = "#{base}_"
    name.start_with?(prefix) ? name.delete_prefix(prefix) : name
  end

  # Same normalisation config/database.yml applies to the slug, so a basename
  # and a slug are compared on the same terms.
  def normalize(value)
    value.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
  end
end
