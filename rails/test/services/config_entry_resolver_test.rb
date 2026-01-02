require "test_helper"
require Rails.root.join("app", "lib", "app_constants", "project").to_s

class ConfigEntryResolverTest < ActiveSupport::TestCase
  test "fetch returns default when entry is missing" do
    assert_equal "fallback", Config::EntryResolver.fetch("missing.key", default: "fallback")
  end

  test "fetch_flag casts stored values to boolean" do
    Config::EntryResolver.upsert!(key: "feature.flag", value: true)
    assert_equal true, Config::EntryResolver.fetch_flag("feature.flag", default: false)
  end

  test "scope-specific entries are isolated" do
    user = create_user("resolver-scope@#{AppConstants::Project.slug}.local")
    Config::EntryResolver.upsert!(
      key: "scoped.setting",
      value: { "level" => 1 },
      scope: user
    )

    assert_equal({ "level" => 1 }, Config::EntryResolver.fetch("scoped.setting", scope: user))
    assert_nil Config::EntryResolver.fetch("scoped.setting")
  end

  private

  def create_user(email)
    User.find_or_create_by!(email: email) do |user|
      user.english_name = "Resolver User"
      user.encrypted_password = User.password_hash("Resolver!123")
    end
  end
end
