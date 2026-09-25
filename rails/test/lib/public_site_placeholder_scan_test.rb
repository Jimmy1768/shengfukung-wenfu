require "test_helper"

# The public Vue site must not fall back to admin-facing placeholder copy.
#
# Four files imported shared/app_constants/temple_profile_placeholders.json and
# rendered it whenever site data was absent. Because the fetch is asynchronous,
# "absent" included the first moments of every page load, so every visitor saw
# "尚未設定地址（請至後台「Temple Profile」更新）" flash in the footer on every
# page, longer on a slow phone. Observed 2026-09-25 in a screenshot showing
# 載入中 in the body and the placeholders in the footer at the same instant.
#
# This is a Rails test that reads Vue source. The Vue site has no test runner
# and adding one is out of scope; reading files needs nothing.
class PublicSitePlaceholderScanTest < ActiveSupport::TestCase
  REPO_ROOT = Rails.root.join("..").expand_path

  # Named exactly rather than as a directory. These are the four that carried
  # the fallback; naming them means a fifth cannot inherit the exemption by
  # sitting in the same folder.
  GUARDED_FILES = %w[
    vue/src/components/site/SiteFooter.vue
    vue/src/layouts/classic/pages/Contact.vue
    vue/src/layouts/classic/pages/About.vue
    vue/src/layouts/classic/pages/Home.vue
  ].freeze

  PLACEHOLDER_IMPORT = %r{@shared/app_constants/temple_profile_placeholders\.json}
  PLACEHOLDER_FALLBACK = /placeholders\s*\.\s*(contact|service_times|visit_info|about)\b/
  SAMPLE_MARKER = /（Placeholder）|\(Placeholder\)/

  test "the guarded files still exist, so this scan cannot pass by scanning nothing" do
    missing = GUARDED_FILES.reject { |path| REPO_ROOT.join(path).exist? }

    assert_empty missing,
      "#{missing.inspect} no longer exists. If a file moved, move it in GUARDED_FILES " \
      "too -- a scan over files that are not there passes without checking anything."
  end

  test "no guarded file imports the placeholder JSON" do
    offenders = GUARDED_FILES.select { |path| REPO_ROOT.join(path).read.match?(PLACEHOLDER_IMPORT) }

    assert_empty offenders,
      "#{offenders.inspect} imports the shared placeholder file. Those strings are " \
      "addressed to an admin, and the public site renders them to visitors -- during " \
      "every load while data is in flight, and permanently for a temple that left a " \
      "section empty."
  end

  test "no guarded file falls back to the contact, service_times, visit_info or about placeholders" do
    offenders = GUARDED_FILES.select { |path| REPO_ROOT.join(path).read.match?(PLACEHOLDER_FALLBACK) }

    assert_empty offenders,
      "#{offenders.inspect} falls back to placeholder profile copy. A region with no " \
      "data must render nothing and let the value appear when it arrives."
  end

  # The literal, swept across the whole public site rather than only the four,
  # because a new page can invent one as easily as an old one can keep it.
  test "no file under vue/src carries a （Placeholder） marker" do
    offenders = Dir.glob(REPO_ROOT.join("vue/src/**/*.{vue,js,ts,json}")).select do |path|
      File.read(path).match?(SAMPLE_MARKER)
    end

    assert_empty offenders.map { |path| Pathname(path).relative_path_from(REPO_ROOT).to_s },
      "a （Placeholder） marker is sample text. On the public site it tells a visitor " \
      "that what they are reading is not real -- and the two on Home were fabricated " \
      "events with dates, a location and a working registration link."
  end

  # The deleted keys must stay deleted: the file holds the hero image and
  # nothing else, so there is no admin-facing copy left for anything to read.
  test "the shared placeholder file no longer holds admin-facing profile copy" do
    config = JSON.parse(REPO_ROOT.join("shared/app_constants/temple_profile_placeholders.json").read)

    assert_equal %w[hero_images], config.keys,
      "temple_profile_placeholders.json has grown a key again. It holds the hero image " \
      "and nothing else; profile defaults written for an admin belong nowhere the " \
      "public site can reach."
  end
end
