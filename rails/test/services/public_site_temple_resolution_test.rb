require "test_helper"

# The public site has exactly one way to find its temple.
#
# TempleContextResolver's public surface offers a single candidate, the project
# default, which is AppConstants::Project.slug from
# shared/app_constants/project.json. So that file's slug and the temple record's
# slug are one fact stored twice, and if they ever disagree the public site
# stops finding its temple. The 2026-09-25 rename moved both together, and these
# cases are what would notice if a later change moved only one.
class PublicSiteTempleResolutionTest < ActiveSupport::TestCase
  DEMO_SLUG = "shengfukung-demo"

  test "the project slug is the renamed demo slug" do
    assert_equal DEMO_SLUG, AppConstants::Project.slug,
      "project.json's slug and the migrated temple record must name the same temple. " \
      "The public site resolves its temple by the project default alone, so a project.json " \
      "still saying shengfukung-wenfu against a record migrated to shengfukung-demo means " \
      "the site finds no temple by that route."
  end

  test "the public surface resolves the demo temple through the project default" do
    demo = create_temple(slug: DEMO_SLUG)
    # A second temple, so resolving by luck is distinguishable from resolving by
    # the project default: with a mismatch the resolver falls through to
    # scope.first, which may well be this one.
    create_temple(slug: "another-temple")

    result = TempleContextResolver.new(params: {}, session: {}, surface: :public).resolve

    assert_equal demo.id, result.temple&.id,
      "the public site resolved #{result.temple&.slug.inspect} rather than the demo temple"
    assert_equal :project_default, result.source,
      "the demo temple was found, but not by the project default -- source was " \
      "#{result.source.inspect}. A scope fallback means project.json and the record " \
      "disagree and the site is showing whichever temple happened to come first."
  end

  # The failure this guards against, stated as its own case: when the project
  # slug names no temple, the public surface has nothing left to try.
  test "a project slug that names no temple resolves nothing by the project default" do
    create_temple(slug: "another-temple")

    AppConstants::Project.stub(:slug, "shengfukung-wenfu") do
      result = TempleContextResolver.new(params: {}, session: {}, surface: :public).resolve

      assert_not_equal :project_default, result.source,
        "a stale project slug must not resolve by the project default"
    end
  end

  test "the manifest and the temple config file agree with the project slug" do
    manifest = YAML.load_file(Rails.root.join("app/lib/temples/manifest.yml"))
    slugs = manifest.fetch("temples").map { |t| t["slug"] }

    assert_includes slugs, DEMO_SLUG,
      "the manifest must list the demo temple under its new slug"
    assert Rails.root.join("db/temples/#{DEMO_SLUG}.yml").exist?,
      "the temple config is opened by slug at runtime, so the file has to be named for it"
    assert Rails.root.join("db/temples/offerings/#{DEMO_SLUG}.yml").exist?,
      "the offerings config is opened by slug too"
  end
end
