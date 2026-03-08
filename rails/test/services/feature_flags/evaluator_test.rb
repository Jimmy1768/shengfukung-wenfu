require "test_helper"

module FeatureFlags
  class EvaluatorTest < ActiveSupport::TestCase
    test "returns default when flag is missing" do
      user = User.create!(
        email: "flag-missing@example.com",
        english_name: "Flag Missing",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )

      assert_equal false, Evaluator.enabled?("missing.flag", actor: user, default: false)
    end

    test "uses config entry boolean when no rollout exists" do
      Config::EntryResolver.upsert!(key: "oauth_account_linking", value: true)
      user = User.create!(
        email: "flag-boolean@example.com",
        english_name: "Flag Boolean",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )

      assert_equal true, Evaluator.enabled?("oauth_account_linking", actor: user)
    end

    test "supports percentage rollout by actor" do
      Config::EntryResolver.upsert!(key: "oauth_account_linking", value: true)
      entry = ConfigEntry.find_by!(key: "oauth_account_linking", scope_type: "system", scope_id: nil)
      entry.create_feature_flag_rollout!(
        rollout_percentage: 0,
        enabled_by_default: false
      )

      user = User.create!(
        email: "flag-rollout@example.com",
        english_name: "Flag Rollout",
        encrypted_password: User.password_hash("Password123!"),
        metadata: {}
      )

      assert_equal false, Evaluator.enabled?("oauth_account_linking", actor: user)

      entry.feature_flag_rollout.update!(rollout_percentage: 100)
      assert_equal true, Evaluator.enabled?("oauth_account_linking", actor: user)
    end
  end
end
