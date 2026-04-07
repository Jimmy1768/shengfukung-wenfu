require "test_helper"

class AdminPaymentMethodsTest < ActionDispatch::IntegrationTest
  test "owner can view and update payment methods" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "owner")

    sign_in_admin(owner)

    get admin_payment_methods_path

    assert_response :success
    assert_includes response.body, "ECPay"

    assert_difference -> { SystemAuditLog.where(action: "admin.payment_methods.updated").count }, 1 do
      patch admin_payment_methods_path, params: {
        payment_methods: {
          payment_mode: "platform",
          ecpay_merchant_id: "2000132",
          ecpay_hash_key: "hash-key-value",
          ecpay_hash_iv: "hash-iv-value",
          ecpay_environment: "stage",
          stripe_platform_enabled: "1",
          stripe_platform_fee_bps: "450",
          stripe_platform_notes: "Collect platform fee after payout reconciliation"
        }
      }
    end

    assert_redirected_to admin_payment_methods_path
    temple.reload
    assert_equal "platform", temple.payment_mode
    assert_equal "2000132", temple.payment_gateway_settings_for(:ecpay)["merchant_id"]
    assert_equal "stage", temple.payment_gateway_settings_for(:ecpay)["environment"]
    assert_equal true, temple.stripe_platform_settings["enabled"]
    assert_equal 450, temple.stripe_platform_settings["application_fee_bps"]
  end

  test "non-owner is redirected away from payment methods" do
    temple = create_temple
    admin = create_admin_user(temple: temple, role: "admin")

    sign_in_admin(admin)

    get admin_payment_methods_path

    assert_redirected_to admin_dashboard_path
  end
end
