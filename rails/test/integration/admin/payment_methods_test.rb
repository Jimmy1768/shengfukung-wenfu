require "test_helper"

class AdminPaymentMethodsTest < ActionDispatch::IntegrationTest
  test "owner can view and update payment methods" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "owner")

    sign_in_admin(owner)

    get admin_dashboard_path

    assert_response :success
    assert_includes response.body, "帳務設定"

    get admin_payment_methods_path

    assert_response :success
    assert_includes response.body, "ECPay"
    assert_includes response.body, "帳務設定"
    assert_includes response.body, "NT$36,000"
    refute_includes response.body, "%{annual_amount}"

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
    assert_equal 300_000, temple.billing_settings["monthly_fee_cents"]
    assert_equal 3_600_000, temple.billing_settings["annual_fee_cents"]
    assert_equal "year", temple.billing_settings["billing_interval"]
    assert_nil temple.billing_settings["grace_started_at"]
  end

  test "stored ecpay secrets do not render back into html" do
    temple = create_temple(
      payment_provider_settings: {
        "ecpay" => {
          "merchant_id" => "2000132",
          "hash_key" => "TempleHashKeySecret",
          "hash_iv" => "TempleHashIvSecret",
          "environment" => "stage"
        }
      }
    )
    owner = create_admin_user(temple: temple, role: "owner")

    sign_in_admin(owner)
    get admin_payment_methods_path

    assert_response :success
    assert_includes response.body, "2000132"
    refute_includes response.body, "TempleHashKeySecret"
    refute_includes response.body, "TempleHashIvSecret"
    assert_includes response.body, "Merchant ID"
    assert_includes response.body, "HashKey"
    assert_includes response.body, "HashIV"
  end

  test "payment method audit log does not persist raw ecpay secrets" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "owner")

    sign_in_admin(owner)

    patch admin_payment_methods_path, params: {
      payment_methods: {
        ecpay_merchant_id: "2000132",
        ecpay_hash_key: "hash-key-value",
        ecpay_hash_iv: "hash-iv-value",
        ecpay_environment: "stage",
        billing_payment_method_on_file: "1"
      }
    }

    log = SystemAuditLog.order(created_at: :desc).find_by!(action: "admin.payment_methods.updated")
    serialized = log.metadata.to_json
    refute_includes serialized, "hash-key-value"
    refute_includes serialized, "hash-iv-value"
    assert_includes Array(log.metadata["changed_fields"]), "ecpay"
  end

  test "temple owner by permission can view and update payment methods" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "admin", membership_role: "owner", permission_overrides: { manage_permissions: true })

    sign_in_admin(owner)

    get admin_dashboard_path

    assert_response :success
    assert_includes response.body, "帳務設定"

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

  test "owner can start Stripe billing setup" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "owner")
    result = Billing::StripePaymentMethodSetup::Result.new(
      session_id: "cs_setup_123",
      url: "https://checkout.stripe.com/c/cs_setup_123"
    )

    sign_in_admin(owner)

    Billing::StripePaymentMethodSetup.stub(:start, ->(**_args) { result }) do
      post start_billing_setup_admin_payment_methods_path
    end

    assert_redirected_to result.url
  end

  test "owner can complete Stripe billing setup return" do
    temple = create_temple
    owner = create_admin_user(temple: temple, role: "owner")
    completed_session_id = nil

    sign_in_admin(owner)

    Billing::StripePaymentMethodSetup.stub(:complete, ->(**args) { completed_session_id = args[:checkout_session_id] }) do
      get billing_setup_return_admin_payment_methods_path(checkout_session_id: "cs_setup_123")
    end

    assert_equal "cs_setup_123", completed_session_id
    assert_redirected_to admin_payment_methods_path
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
    refute_includes response.body, "帳務設定"

    get admin_payment_methods_path

    assert_redirected_to admin_dashboard_path
  end
end
