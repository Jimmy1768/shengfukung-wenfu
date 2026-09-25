require "test_helper"
require Rails.root.join("db", "seeds", "temples").to_s

class TemplesBootstrapTest < ActiveSupport::TestCase
  test "bootstrap creates a minimal temple row with registration periods" do
    assert_difference("Temple.count", 1) do
      Seeds::Temples.bootstrap(slug: "demo-lotus")
    end

    temple = Temple.find_by!(slug: "demo-lotus")

    assert_equal "蓮城慈航宮", temple.name
    assert_equal false, temple.published
    assert_equal({}, temple.hero_images)
    assert_equal({}, temple.contact_info)
    assert_equal({}, temple.service_times)
    assert_equal "temple", temple.payment_mode
    assert_equal({}, temple.payment_provider_settings)
    assert_equal %w[2026-lotus-festival perennial], temple.registration_period_keys
  end

  test "bootstrap preserves existing profile fields while refreshing registration periods" do
    temple = create_temple(
      slug: "demo-lotus",
      name: "Old Name",
      tagline: "Keep me",
      hero_copy: "Keep this copy",
      contact_info: { "phone" => "02-0000-0000" },
      service_times: { "weekday" => "09:00 - 18:00" },
      metadata: { "registration_periods" => [{ "key" => "old-period" }] },
      published: true,
      payment_mode: "temple",
      payment_provider_settings: {}
    )

    Seeds::Temples.bootstrap(slug: "demo-lotus")

    temple.reload
    assert_equal "蓮城慈航宮", temple.name
    assert_equal "Keep me", temple.tagline
    assert_equal "Keep this copy", temple.hero_copy
    assert_equal({ "phone" => "02-0000-0000" }, temple.contact_info)
    assert_equal({ "weekday" => "09:00 - 18:00" }, temple.service_times)
    assert_equal true, temple.published
    assert_equal %w[2026-lotus-festival perennial], temple.registration_period_keys
  end

  test "shengfukung bootstrap selects explicit cash-only checkout without overwriting payment credentials or billing data" do
    temple = create_temple(
      slug: "shengfukung-demo",
      payment_provider_settings: {
        "ecpay" => { "merchant_id" => "keep-merchant", "hash_key" => "keep-key", "hash_iv" => "keep-iv" },
        "billing" => { "stripe_customer_id" => "cus_keep", "stripe_payment_method_id" => "pm_keep" },
        "unrelated" => { "admin_work" => "keep" }
      },
      metadata: { "custom" => "keep" }
    )

    Seeds::Temples.bootstrap(slug: "shengfukung-demo")
    first_settings = temple.reload.payment_provider_settings.deep_dup
    Seeds::Temples.bootstrap(slug: "shengfukung-demo")

    assert_equal "cash_only", temple.reload.payment_provider_settings["patron_checkout_provider"]
    assert_equal first_settings, temple.payment_provider_settings
    assert_equal "keep-merchant", temple.payment_gateway_settings_for(:ecpay)["merchant_id"]
    assert_equal "cus_keep", temple.billing_settings["stripe_customer_id"]
    assert_equal "keep", temple.payment_provider_settings.dig("unrelated", "admin_work")
    assert_equal "keep", temple.metadata["custom"]
  end
end
