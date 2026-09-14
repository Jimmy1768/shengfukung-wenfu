require "test_helper"
require "erb"
require "yaml"

# config/database.yml used to hardcode golden_template_dev / golden_template_test.
# Any clone that did not explicitly set PGDATABASE_TEST therefore ran its suite
# against this project's test database -- which is exactly how a sibling clone's
# tables ended up in this repo's schema dump.
class DatabaseConfigurationTest < ActiveSupport::TestCase
  # The test name is per-checkout now, so asserting a literal here would pass
  # only in the primary tree and fail in every worktree -- a check that is true
  # where it was written and nowhere else, which is the defect this repository
  # has already shipped twice. The development name is still a literal, because
  # it is still shared on purpose.
  test "database names derive from the project slug" do
    config = render(slug: "shengfukung-wenfu")

    assert_equal "shengfukung_wenfu_dev", config.dig("development", "database")
    assert_equal expected_test_name("shengfukung_wenfu"), config.dig("test", "database")
  end

  # True in every checkout: whatever the suffix, the base is the slug's.
  test "the test name is the slug's test database, in any checkout" do
    config = render(slug: "shengfukung-wenfu")

    assert config.dig("test", "database").start_with?("shengfukung_wenfu_test"),
      "got #{config.dig('test', 'database')}"
  end

  test "two projects cloned from this template never share a database" do
    a = render(slug: "acme-clinic")
    b = render(slug: "shengfukung-wenfu")

    refute_equal a.dig("development", "database"), b.dig("development", "database")
    refute_equal a.dig("test", "database"), b.dig("test", "database")
  end

  test "development and test are always distinct" do
    config = render(slug: "acme-clinic")

    refute_equal config.dig("development", "database"), config.dig("test", "database")
  end

  test "falls back to the shared project config when PROJECT_SLUG is unset" do
    expected = AppConstants::Project.slug.downcase.gsub(/[^a-z0-9]+/, "_")
    config = render(slug: nil)

    assert_equal expected_test_name(expected), config.dig("test", "database")
  end

  test "an unusable slug still yields a name rather than an empty one" do
    config = render(slug: "---")

    assert_equal expected_test_name("app"), config.dig("test", "database")
  end

  test "explicit environment variables win over the derived names" do
    config = render(slug: "acme-clinic", "PGDATABASE" => "explicit_dev", "PGDATABASE_TEST" => "explicit_test")

    assert_equal "explicit_dev",  config.dig("development", "database")
    assert_equal "explicit_test", config.dig("test", "database")
  end

  private

  # What this checkout derives for a given base. Rendering database.yml answers
  # for wherever this process is standing, so the expectation has to be computed
  # the same way rather than written down.
  def expected_test_name(base)
    TestDatabaseName.call(checkout_path: Rails.root.parent, base: base)
  end

  # PGDATABASE / PGDATABASE_TEST / PGUSER are cleared unless a case sets them.
  # This project pins them in .env.test and .env.development, which dotenv now
  # loads in the test environment -- without clearing them the ERB would return
  # the pinned values and these cases would never exercise the fallback they
  # exist to test.
  def render(slug:, **env)
    env = { "PGDATABASE" => nil, "PGDATABASE_TEST" => nil, "PGUSER" => nil }
      .merge(env)
      .merge("PROJECT_SLUG" => slug)
    with_env(env) do
      raw = ERB.new(File.read(Rails.root.join("config", "database.yml"))).result(binding)
      YAML.safe_load(raw, aliases: true, permitted_classes: [Symbol])
    end
  end

  def with_env(vars)
    previous = vars.keys.index_with { |key| ENV[key] }
    vars.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
