require "test_helper"
require "erb"
require "yaml"
require "json"

# config/database.yml used to hardcode golden_template_dev / golden_template_test.
# Any clone that did not explicitly set PGDATABASE_TEST therefore ran its suite
# against this project's test database -- which is exactly how a sibling clone's
# tables ended up in this repo's schema dump. That is the bug these cases exist
# to keep fixed, and nothing here may reintroduce a name that is fixed
# regardless of configuration.
#
# The local base now comes from `databaseName` in project.json when that key is
# present, and from the slug when it is not -- a repository and the product
# inside it can be called different things. Cases that need a different
# project.json stub the read rather than editing the tracked file.
class DatabaseConfigurationTest < ActiveSupport::TestCase
  # --- criterion 2: what this project actually resolves --------------------

  # Correct as literals, unlike a name derived from where you are standing:
  # these come from a tracked file, so every checkout agrees on them.
  test "this project's local databases are named after the product" do
    config = render

    assert_equal "templemate_dev",  config.dig("development", "database")
    assert_equal "templemate_test", config.dig("test", "database")
  end

  # --- criterion 1: the key wins, its absence changes nothing --------------

  test "databaseName is the base when it is present" do
    config = render(project: { "slug" => "acme-clinic", "databaseName" => "widgets" })

    assert_equal "widgets_dev",  config.dig("development", "database")
    assert_equal "widgets_test", config.dig("test", "database")
  end

  # A clone that has not set the key keeps deriving from its slug exactly as
  # before, so adding it changed nothing for anyone else.
  test "without databaseName the slug is used exactly as before" do
    config = render(project: { "slug" => "acme-clinic" })

    assert_equal "acme_clinic_dev",  config.dig("development", "database")
    assert_equal "acme_clinic_test", config.dig("test", "database")
  end

  test "a blank databaseName falls back to the slug rather than yielding an empty name" do
    config = render(project: { "slug" => "acme-clinic", "databaseName" => "   " })

    assert_equal "acme_clinic_test", config.dig("test", "database")
  end

  test "an unusable slug and no databaseName still yields a name" do
    config = render(project: { "slug" => "---" })

    assert_equal "app_test", config.dig("test", "database")
  end

  test "PROJECT_SLUG still drives the base where no databaseName is set" do
    config = render(project: { "slug" => "acme-clinic" }, "PROJECT_SLUG" => "other-thing")

    assert_equal "other_thing_test", config.dig("test", "database")
  end

  # --- criterion 5: the original bug stays fixed ---------------------------

  test "two projects with different databaseName never share a database" do
    a = render(project: { "slug" => "same-slug", "databaseName" => "alpha" })
    b = render(project: { "slug" => "same-slug", "databaseName" => "beta" })

    refute_equal a.dig("development", "database"), b.dig("development", "database")
    refute_equal a.dig("test", "database"), b.dig("test", "database")
  end

  test "two projects with different slugs and no databaseName never share a database" do
    a = render(project: { "slug" => "acme-clinic" })
    b = render(project: { "slug" => "shengfukung-demo" })

    refute_equal a.dig("development", "database"), b.dig("development", "database")
    refute_equal a.dig("test", "database"), b.dig("test", "database")
  end

  test "development and test are always distinct" do
    config = render(project: { "slug" => "acme-clinic" })

    refute_equal config.dig("development", "database"), config.dig("test", "database")
  end

  # --- criterion 3: explicit environment variables win ---------------------

  test "PGDATABASE and PGDATABASE_TEST win over the derived names" do
    config = render("PGDATABASE" => "explicit_dev", "PGDATABASE_TEST" => "explicit_test")

    assert_equal "explicit_dev",  config.dig("development", "database")
    assert_equal "explicit_test", config.dig("test", "database")
  end

  # --- criterion 4: deployments are out of reach ---------------------------

  # The property this whole change rests on. Production and staging resolve from
  # PGDATABASE alone and never consult the derived base, so nothing decided in
  # project.json can reach a deployment even in principle. Asserted rather than
  # reasoned about, so a future edit that wires the base into either entry fails
  # here instead of on the droplet.
  test "databaseName cannot reach production or staging, whatever it is set to" do
    %w[templemate wildly_different ""].each do |candidate|
      config = render(
        project: { "slug" => "shengfukung-demo", "databaseName" => candidate },
        "PGDATABASE" => "the_only_thing_deployments_read"
      )

      assert_equal "the_only_thing_deployments_read", config.dig("production", "database"),
        "production must resolve from PGDATABASE alone; databaseName=#{candidate.inspect} reached it"
      assert_equal "the_only_thing_deployments_read", config.dig("staging", "database"),
        "staging must resolve from PGDATABASE alone; databaseName=#{candidate.inspect} reached it"
    end
  end

  # With PGDATABASE unset a deployment gets nothing, not a locally derived name.
  # A fallback here is how staging silently ran against production's database.
  test "production and staging resolve to nothing when PGDATABASE is unset" do
    config = render(project: { "slug" => "acme-clinic", "databaseName" => "templemate" })

    assert_nil config.dig("production", "database")
    assert_nil config.dig("staging", "database")
  end

  private

  # Renders config/database.yml under controlled conditions.
  #
  # project: replaces the parsed project.json for this render only, by stubbing
  # the read the template performs. The tracked file is never written to -- a
  # case that edited it would change what every other case sees.
  def render(project: nil, **env)
    env = { "PGDATABASE" => nil, "PGDATABASE_TEST" => nil, "PGUSER" => nil, "PROJECT_SLUG" => nil }
      .merge(env)

    template = ERB.new(File.read(Rails.root.join("config", "database.yml")))

    with_env(env) do
      raw = project ? with_project(project) { template.result(binding) } : template.result(binding)
      YAML.safe_load(raw, aliases: true, permitted_classes: [Symbol])
    end
  end

  def with_project(project)
    original = File.method(:read)
    reader = lambda do |path, *args|
      path.to_s.end_with?("project.json") ? project.to_json : original.call(path, *args)
    end

    File.stub(:read, reader) { yield }
  end

  # PGDATABASE / PGDATABASE_TEST / PGUSER / PROJECT_SLUG are cleared unless a
  # case sets them. This project pins some of them in .env.test and
  # .env.development, which dotenv loads in the test environment -- without
  # clearing them the ERB would return the pinned values and these cases would
  # never exercise the fallbacks they exist to test.
  def with_env(vars)
    previous = vars.keys.index_with { |key| ENV[key] }
    vars.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end
