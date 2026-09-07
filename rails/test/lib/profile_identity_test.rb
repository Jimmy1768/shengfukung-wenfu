require "test_helper"

# Guards the regression these values were changed to fix. Profile::Identity used
# to hardcode APP_CODENAME = "initial", and config/application.rb carried a second
# literal "initial" of its own. Every clone therefore shipped the same session
# cookie name and the same Redis namespaces, so siblings sharing a Redis instance
# shared cache and app-state keys, and siblings on sibling subdomains collided on
# session cookies. "initial" also matches no search for the template's name, so
# nothing surfaced it as a placeholder.
class ProfileIdentityTest < ActiveSupport::TestCase
  test "codename derives from the project slug rather than a hardcoded literal" do
    assert_equal "shengfukung_wenfu", Profile::Identity.app_codename
    refute_equal "initial", Profile::Identity.app_codename
  end

  test "config.x.app_codename cannot drift from Profile::Identity" do
    assert_equal Profile::Identity.app_codename, Rails.application.config.x.app_codename
  end

  test "the session cookie is namespaced by the codename" do
    assert_equal "_#{Profile::Identity.app_codename}_session",
      Rails.application.config.session_options[:key]
  end

  test "the redis app-state prefix is namespaced by the codename" do
    assert_equal "#{Profile::Identity.app_codename}:appstate", System::RedisAppStore::KEY_PREFIX
  end

  test "two different slugs never resolve to the same codename" do
    a = Profile::Identity.normalize_codename("acme-clinic")
    b = Profile::Identity.normalize_codename("shengfukung-wenfu")

    assert_equal "acme_clinic", a
    assert_equal "shengfukung_wenfu", b
    refute_equal a, b
  end

  test "casing punctuation and spaces normalise safely" do
    assert_equal "acme_clinic_tw", Profile::Identity.normalize_codename("  Acme Clinic (TW)!  ")
    assert_equal "acme_clinic",    Profile::Identity.normalize_codename("ACME--CLINIC")
  end

  test "an unusable slug falls back rather than producing an empty codename" do
    assert_equal "app", Profile::Identity.normalize_codename("---")
    assert_equal "app", Profile::Identity.normalize_codename("")
    assert_equal "app", Profile::Identity.normalize_codename(nil)
  end

  test "APP_CODENAME overrides the derived value" do
    with_codename_env("legacy-name") do
      assert_equal "legacy_name", Profile::Identity.app_codename
    end
  end

  test "a blank APP_CODENAME falls through to the project slug" do
    with_codename_env("   ") do
      assert_equal "shengfukung_wenfu", Profile::Identity.app_codename
    end
  end

  private

  def with_codename_env(value)
    previous = ENV["APP_CODENAME"]
    ENV["APP_CODENAME"] = value
    reset_memo!
    yield
  ensure
    previous.nil? ? ENV.delete("APP_CODENAME") : ENV["APP_CODENAME"] = previous
    reset_memo!
  end

  def reset_memo!
    if Profile::Identity.instance_variable_defined?(:@app_codename)
      Profile::Identity.remove_instance_variable(:@app_codename)
    end
  end
end
