require "test_helper"

class AdminPaymentMethodsTest < ActionDispatch::IntegrationTest
  test "owner can view and update payment methods" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "owner")

    sign_in_admin(owner)

    get admin_dashboard_path

    assert_response :success
    assert_includes response.body, "Billing"

    get admin_payment_methods_path

    assert_response :success
    assert_includes response.body, "ECPay"
    assert_includes response.body, "Billing"

    assert_difference -> { SystemAuditLog.where(action: "admin.payment_methods.updated").count }, 1 do
      patch admin_payment_methods_path, params: {
        payment_methods: {
          ecpay_merchant_id: "2000132",
          ecpay_hash_key: "hash-key-value",
          ecpay_hash_iv: "hash-iv-value",
          ecpay_environment: "stage",
          billing_payment_method_on_file: "1"
        }
      }
    end

    assert_redirected_to admin_payment_methods_path
    temple.reload
    assert_equal "2000132", temple.payment_gateway_settings_for(:ecpay)["merchant_id"]
    assert_equal "stage", temple.payment_gateway_settings_for(:ecpay)["environment"]
    assert temple.billing_payment_method_on_file?
    assert_equal 500_000, temple.billing_settings["monthly_fee_cents"]
    assert_nil temple.billing_settings["grace_started_at"]
  end

  test "temple owner by permission can view and update payment methods" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "admin", membership_role: "owner", permission_overrides: { manage_permissions: true })

    sign_in_admin(owner)

    get admin_dashboard_path

    assert_response :success
    assert_includes response.body, "Billing"

    get admin_payment_methods_path

    assert_response :success

    patch admin_payment_methods_path, params: {
      payment_methods: {
        ecpay_merchant_id: "2000132",
        ecpay_hash_key: "hash-key-value",
        ecpay_hash_iv: "hash-iv-value",
        ecpay_environment: "stage",
        billing_payment_method_on_file: "1"
      }
    }

    assert_redirected_to admin_payment_methods_path
  end

  test "saving without payment method starts grace period" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "owner")

    sign_in_admin(owner)

    patch admin_payment_methods_path, params: {
      payment_methods: {
        ecpay_merchant_id: "2000132",
        ecpay_hash_key: "hash-key-value",
        ecpay_hash_iv: "hash-iv-value",
        ecpay_environment: "stage",
        billing_payment_method_on_file: "0"
      }
    }

    assert_redirected_to admin_payment_methods_path
    temple.reload
    refute temple.billing_payment_method_on_file?
    assert_equal 30, temple.billing_grace_days
    assert temple.billing_grace_started_at.present?
  end

  test "setup incomplete does not start grace period" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "owner")

    sign_in_admin(owner)

    patch admin_payment_methods_path, params: {
      payment_methods: {
        ecpay_merchant_id: "",
        ecpay_hash_key: "",
        ecpay_hash_iv: "",
        ecpay_environment: "stage",
        billing_payment_method_on_file: "0"
      }
    }

    assert_redirected_to admin_payment_methods_path
    temple.reload
    assert_nil temple.billing_grace_started_at
    refute temple.online_payments_frozen?
  end

  test "non-owner is redirected away from payment methods" do
    temple = create_temple
    admin = create_admin_user(temple: temple, role: "admin")

    sign_in_admin(admin)

    get admin_dashboard_path

    assert_response :success
    refute_includes response.body, "Billing"

    get admin_payment_methods_path

    assert_redirected_to admin_dashboard_path
  end
end
