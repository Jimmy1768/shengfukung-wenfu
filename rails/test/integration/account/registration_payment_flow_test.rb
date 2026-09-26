require "test_helper"

class RegistrationPaymentFlowTest < ActionDispatch::IntegrationTest
  FakeRedirectAdapter = Struct.new(:redirect_url) do
    def checkout(**)
      {
        status: "pending",
        provider_checkout_id: "stubbed_chk",
        provider_payment_id: "stubbed_pay",
        provider_reference: "stubbed_ref",
        redirect_url: redirect_url,
        raw: {}
      }
    end
  end

  FakeReturnAdapter = Struct.new(:status) do
    def confirm(**kwargs)
      {
        status: status,
        provider_reference: kwargs[:provider_payment_ref],
        raw: {}
      }
    end

    def query_status(provider_payment_ref:, **)
      {
        status: status,
        provider_reference: provider_payment_ref,
        raw: {}
      }
    end
  end

  test "successful registration redirects to payment page" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple:,
      slug: "lantern-festival",
      title: "Lantern Festival",
      currency: "TWD",
      price_cents: 600,
      starts_on: Date.current,
      ends_on: Date.current + 1.day
    )
    user = User.create!(
      email: "flow@example.com",
      english_name: "Flow Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    post account_registrations_path, params: {
      offering: offering.slug,
      account_action: "event",
      account_registration_intake_form: {
        contact_name: "Flow Member",
        quantity: 1
      }
    }

    registration = TempleEventRegistration.order(:created_at).last
    assert_redirected_to payment_account_registration_path(registration)

    # Fresh patron self-registration is intent, not a finished order --
    # checkout isn't offered until an admin completes it (see
    # ops/docs/plans/SEMI_AUTOMATIC_REGISTRATION_WORKFLOW_PLAN.md).
    follow_redirect!
    assert_response :success
    refute_includes response.body, "前往付款"
    # Deliberately vague: the patron cannot act in this state, so the copy
    # does not narrate the temple's internal step (or its billing).
    assert_includes response.body, "已收到您的報名，廟方正在處理中。"
    assert_includes response.body, offering.title
    assert_includes response.body, api_v1_account_payment_status_path(reference: registration.reference_code)

    assert_no_difference -> { registration.temple_payments.count } do
      post start_checkout_account_registration_path(registration)
    end
    assert_redirected_to payment_account_registration_path(registration)

    registration.mark_admin_completed!
    get payment_account_registration_path(registration)
    assert_response :success
    assert_includes response.body, "前往付款"
  end

  test "account self create and eligible update write safe defaults without rewriting the registration snapshot" do
    temple = create_temple
    offering = create_offering(
      temple:,
      slug: "account-defaults",
      title: "Account defaults",
      metadata: { "registration_form" => { "sections" => { "logistics" => ["arrival_window"], "ritual_metadata" => ["ceremony_notes"] } } }
    )
    user = User.create!(email: "account-defaults@example.com", english_name: "Account Defaults", encrypted_password: User.password_hash("Password123!"))
    defaults = Registrations::ReusableDefaults.new(user:, temple:, offering:)

    sign_in_account(user, temple_slug: temple.slug)

    post account_registrations_path, params: {
      offering: offering.slug,
      account_action: "event",
      account_registration_intake_form: { contact_name: "Account Defaults", quantity: 1, arrival_window: "morning", ceremony_notes: "first note" }
    }
    assert_redirected_to payment_account_registration_path(TempleEventRegistration.order(:id).last)
    registration = TempleEventRegistration.order(:id).last
    user.reload
    assert_equal({ "arrival_window" => "morning", "ceremony_notes" => "first note" }, defaults.read)

    patch account_registration_path(registration), params: {
      account_registration_metadata_form: { contact_name: "Account Defaults", quantity: 1, arrival_window: "afternoon", ceremony_notes: "updated note" }
    }
    assert_redirected_to account_registration_path(registration)
    user.reload
    assert_equal({ "arrival_window" => "afternoon", "ceremony_notes" => "updated note" }, defaults.read)

    defaults.write!("arrival_window" => "later default")
    registration.reload
    assert_equal "afternoon", registration.logistics_payload["arrival_window"]

    patch account_registration_path(registration), params: {
      account_registration_metadata_form: { contact_name: "Account Defaults", quantity: 1, arrival_window: "", ceremony_notes: "" }
    }
    assert_redirected_to account_registration_path(registration)
    assert_equal "later default", defaults.read["arrival_window"]

    before = defaults.read
    post account_registrations_path, params: {
      offering: offering.slug,
      account_action: "event",
      account_registration_intake_form: { contact_name: "", quantity: 1, arrival_window: "must not write" }
    }
    assert_response :unprocessable_content
    assert_equal before, defaults.read
  end

  test "paid gathering registration redirects to payment page" do
    temple = create_temple
    gathering = temple.temple_gatherings.create!(
      slug: "community-workshop",
      title: "Community Workshop",
      currency: "TWD",
      price_cents: 450,
      status: "published",
      starts_on: Date.current
    )
    user = User.create!(
      email: "gatheringflow@example.com",
      english_name: "Gathering Flow Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: gathering.slug,
        account_action: "gathering",
        account_registration_intake_form: {
          contact_name: "Gathering Flow Member",
          quantity: 1
        }
      }
    end

    registration = TempleEventRegistration.order(:created_at).last
    assert_equal gathering, registration.registrable
    assert_redirected_to payment_account_registration_path(registration)

    follow_redirect!
    assert_response :success
    assert_includes response.body, gathering.title
    # Gatherings now follow the same pipeline as every other type: created
    # pending, payable only after the temple reviews and publishes.
    refute_includes response.body, "前往付款"

    registration.mark_admin_completed!
    get payment_account_registration_path(registration)
    assert_response :success
    assert_includes response.body, "前往付款"
  end

  test "new gathering registration honors temple param and active account temple context" do
    create_temple(slug: "decoy-temple", name: "Decoy Temple")
    temple = create_temple(slug: "selected-temple", name: "Selected Temple")
    gathering = temple.temple_gatherings.create!(
      slug: "selected-gathering",
      title: "Selected Gathering",
      currency: "TWD",
      price_cents: 450,
      status: "published",
      starts_on: Date.current
    )
    user = User.create!(
      email: "templecontext@example.com",
      english_name: "Temple Context Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    get new_account_registration_path(
      temple: temple.slug,
      account_action: "gathering",
      offering: gathering.slug
    )

    assert_response :success
    assert_includes response.body, gathering.title
    assert_select "input[name='account_registration_intake_form[contact_name]']"
  end

  test "expired billing grace lets a new account registration through, pending" do
    temple = create_temple(
      payment_provider_settings: {
        "billing" => {
          "payment_method_on_file" => false,
          "monthly_fee_cents" => 500_000,
          "grace_days" => 30,
          "grace_started_at" => 31.days.ago.iso8601
        }
      }
    )
    gathering = temple.temple_gatherings.create!(
      slug: "billing-paused-gathering",
      title: "Billing Paused Gathering",
      currency: "TWD",
      price_cents: 450,
      status: "published",
      starts_on: Date.current
    )
    user = User.create!(
      email: "billingpaused@example.com",
      english_name: "Billing Paused",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: gathering.slug,
        account_action: "gathering",
        account_registration_intake_form: {
          contact_name: "Billing Paused",
          quantity: 1
        }
      }
    end

    registration = TempleEventRegistration.order(:created_at).last
    assert_redirected_to payment_account_registration_path(registration)
    assert_equal TempleEventRegistration::PAYMENT_STATUSES[:pending], registration.payment_status
  end

  test "pending setup and suspended entitlements let account registration through, pending, but block checkout" do
    temple = create_temple
    user = User.create!(
      email: "entitlementgated@example.com",
      english_name: "Entitlement Gated",
      encrypted_password: User.password_hash("Password123!")
    )
    entitlement = temple.adopt_platform_billing_entitlement!

    sign_in_account(user, temple_slug: temple.slug)

    ["pending_setup", "suspended"].each do |state|
      entitlement.update!(state:)
      # A distinct offering per state: the same user registering twice for
      # the same non-repeatable offering is a separate duplicate-prevention
      # rule, not something this test is about.
      offering = create_offering(temple:, slug: "entitlement-gated-#{state}", title: "Entitlement Gated #{state}", price_cents: 1500)

      assert_difference -> { TempleEventRegistration.count }, 1 do
        post account_registrations_path, params: {
          offering: offering.slug,
          account_action: "event",
          account_registration_intake_form: { contact_name: "Entitlement Gated", quantity: 1 }
        }
      end
      registration = TempleEventRegistration.order(:created_at).last
      assert_redirected_to payment_account_registration_path(registration)
      assert_equal TempleEventRegistration::PAYMENT_STATUSES[:pending], registration.payment_status

      get payment_account_registration_path(registration)
      assert_response :success
      refute_includes response.body, "前往付款"

      assert_no_difference -> { registration.temple_payments.count } do
        post start_checkout_account_registration_path(registration)
      end
      assert_redirected_to payment_account_registration_path(registration)
    end
  end

  test "active entitlement allows account registration and checkout presentation" do
    temple = create_temple
    offering = create_offering(temple:, slug: "entitlement-active", title: "Entitlement Active", price_cents: 1500)
    user = User.create!(
      email: "entitlementactive@example.com",
      english_name: "Entitlement Active",
      encrypted_password: User.password_hash("Password123!")
    )
    temple.adopt_platform_billing_entitlement!.update!(state: "active")

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: offering.slug,
        account_action: "event",
        account_registration_intake_form: { contact_name: "Entitlement Active", quantity: 1 }
      }
    end

    registration = TempleEventRegistration.order(:created_at).last
    registration.mark_admin_completed!
    get payment_account_registration_path(registration)
    assert_response :success
    assert_includes response.body, "前往付款"
  end

  test "an adopted active entitlement takes precedence over frozen legacy billing settings" do
    temple = create_temple(
      payment_provider_settings: {
        "billing" => {
          "payment_method_on_file" => false,
          "grace_started_at" => 31.days.ago.iso8601
        }
      }
    )
    offering = create_offering(temple:, slug: "entitlement-authority", title: "Entitlement Authority", price_cents: 1500)
    user = User.create!(
      email: "entitlementauthority@example.com",
      english_name: "Entitlement Authority",
      encrypted_password: User.password_hash("Password123!")
    )
    temple.adopt_platform_billing_entitlement!.update!(state: "active")

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: offering.slug,
        account_action: "event",
        account_registration_intake_form: { contact_name: "Entitlement Authority", quantity: 1 }
      }
    end
  end

  test "free registration payment page shows confirmation" do
    temple = create_temple
    offering = TempleOffering.create!(
      temple:,
      slug: "community-potluck",
      title: "Community Potluck",
      currency: "TWD",
      price_cents: 0,
      starts_on: Date.current,
      ends_on: Date.current + 1.day
    )
    user = User.create!(
      email: "free@example.com",
      english_name: "Free Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    post account_registrations_path, params: {
      offering: offering.slug,
      account_action: "event",
      account_registration_intake_form: {
        contact_name: "Free Member",
        quantity: 1
      }
    }

    registration = TempleEventRegistration.order(:created_at).last
    assert_redirected_to payment_account_registration_path(registration)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "此報名不需付費，已完成。"
  end

  test "free gathering registration payment page shows confirmation" do
    temple = create_temple
    gathering = temple.temple_gatherings.create!(
      slug: "free-community-tea",
      title: "Free Community Tea",
      currency: "TWD",
      price_cents: 0,
      status: "published",
      starts_on: Date.current
    )
    user = User.create!(
      email: "freegathering@example.com",
      english_name: "Free Gathering Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    post account_registrations_path, params: {
      offering: gathering.slug,
      account_action: "gathering",
      account_registration_intake_form: {
        contact_name: "Free Gathering Member",
        quantity: 1
      }
    }

    registration = TempleEventRegistration.order(:created_at).last
    assert_equal gathering, registration.registrable
    assert_redirected_to payment_account_registration_path(registration)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "此報名不需付費，已完成。"
  end

  test "failed payment page shows retry action" do
    temple = create_temple
    offering = create_offering(temple:, slug: "failed-payment", title: "Failed Payment Offering", price_cents: 700)
    user = User.create!(
      email: "failedpayment@example.com",
      english_name: "Failed Payment",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:, payment_status: TempleRegistration::PAYMENT_STATUSES[:failed])

    get payment_account_registration_path(registration)

    assert_response :success
    assert_includes response.body, "付款失敗"
    assert_includes response.body, "重新付款"
  end

  test "cash-only tenant shows truthful pending guidance and blocks direct checkout without side effects" do
    temple = create_temple(payment_provider_settings: { "patron_checkout_provider" => "cash_only" })
    offering = create_offering(temple:, slug: "cash-only", title: "Cash Only", price_cents: 700)
    user = User.create!(email: "cashonly-account@example.com", english_name: "Cash Only", encrypted_password: User.password_hash("Password123!"))
    registration = create_registration(user:, offering:)
    original_updated_at = registration.updated_at

    sign_in_account(user, temple_slug: temple.slug)

    get payment_account_registration_path(registration)
    assert_response :success
    assert_includes response.body, "現金付款"
    assert_includes response.body, "與宮廟安排現金付款"
    refute_includes response.body, "繼續進行線上付款"
    refute_includes response.body, "test checkout"
    refute_includes response.body, "ECPay"
    refute_select "form[action=?]", start_checkout_account_registration_path(registration)

    assert_includes I18n.t("account.registrations.payment.online_unavailable_notice", locale: :en), "Online payment is not available"
    assert_includes I18n.t("account.registrations.payment.online_unavailable_notice", locale: :"zh-TW"), "現金付款"

    assert_no_difference [
      "TemplePayment.count",
      "FinancialLedgerEntry.count",
      "SystemAuditLog.count",
      "PaymentWebhookLog.count",
      "PlatformBillingStatement.count",
      "PlatformBillingUsageRecord.count",
      "PlatformBillingAdjustment.count"
    ] do
      post start_checkout_account_registration_path(registration)
    end
    assert_redirected_to payment_account_registration_path(registration)
    assert_equal TempleRegistration::PAYMENT_STATUSES[:pending], registration.reload.payment_status
    assert_equal original_updated_at, registration.updated_at
  end

  test "start fake checkout redirects through return flow and marks payment paid" do
    temple = create_temple(payment_provider_settings: { "patron_checkout_provider" => "fake" })
    offering = create_offering(temple:, slug: "fake-checkout", title: "Fake Checkout Offering", price_cents: 800)
    user = User.create!(
      email: "fakecheckout@example.com",
      english_name: "Fake Checkout",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:)

    Payments::ProviderResolver.stub(:current_provider, "ecpay") do
      get payment_account_registration_path(registration)
      assert_response :success
      assert_includes response.body, "test checkout"

      assert_difference -> { SystemAuditLog.where(action: "account.payments.checkout_started").count }, 1 do
        post start_checkout_account_registration_path(registration)
      end
    end

    assert_redirected_to checkout_return_account_registration_url(registration, provider: "fake")
    follow_redirect!
    assert_redirected_to payment_account_registration_path(registration)
    follow_redirect!
    assert_response :success
    payment = registration.temple_payments.order(:created_at).last
    assert_not_nil payment
    assert_equal "fake", payment.provider
    assert_equal TemplePayment::STATUSES[:completed], payment.reload.status
    assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
    assert_includes response.body, "Payment confirmed successfully."
  end

  test "start checkout redirects to provider url when adapter returns one" do
    temple = create_temple
    offering = create_offering(temple:, slug: "redirect-checkout", title: "Redirect Checkout Offering", price_cents: 1200)
    user = User.create!(
      email: "redirectcheckout@example.com",
      english_name: "Redirect Checkout",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:)

    Payments::ProviderResolver.stub(:current_provider, "ecpay") do
      PaymentGateway::EcpayAdapter.stub(:new, FakeRedirectAdapter.new("/payments/ecpay_checkouts/test")) do
        assert_difference -> { SystemAuditLog.where(action: "account.payments.checkout_started").count }, 1 do
          post start_checkout_account_registration_path(registration)
        end
      end
    end

    assert_redirected_to "/payments/ecpay_checkouts/test"
  end

  test "checkout return confirms an ecpay payment and redirects back to payment page" do
    temple = create_temple(payment_provider_settings: { "patron_checkout_provider" => "fake" })
    offering = create_offering(temple:, slug: "ecpay-return", title: "ECPay Return", price_cents: 1500)
    user = User.create!(
      email: "ecpayreturn@example.com",
      english_name: "ECPay Return",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)
    registration = create_registration(user:, offering:)
    create_payment(
      registration: registration,
      amount_cents: registration.total_price_cents,
      status: TemplePayment::STATUSES[:pending],
      method: TemplePayment::PAYMENT_METHODS[:ecpay],
      provider: "ecpay",
      provider_reference: "trade_123",
      processed_at: nil
    )

    assert_difference -> { SystemAuditLog.where(action: "account.payments.checkout_returned").count }, 1 do
      assert_difference -> { SystemAuditLog.where(action: "system.payments.reconciled").count }, 1 do
        PaymentGateway::EcpayAdapter.stub(:new, FakeReturnAdapter.new("completed")) do
          post checkout_return_account_registration_path(
            registration,
            provider: "fake",
            MerchantTradeNo: "trade_123",
            TradeNo: "ecpay_trade_no_123",
            RtnCode: "1",
            TradeStatus: "1",
            CheckMacValue: "mac_123"
          )
        end
      end
    end

    assert_redirected_to payment_account_registration_path(registration)
    follow_redirect!
    assert_includes response.body, "已完成付款。"
    assert_equal TempleRegistration::PAYMENT_STATUSES[:paid], registration.reload.payment_status
    assert_equal TemplePayment::STATUSES[:completed], registration.temple_payments.order(:created_at).last.reload.status
  end

  test "retry preserves the recorded provider after the temple selection changes" do
    temple = create_temple(payment_provider_settings: { "patron_checkout_provider" => "ecpay" })
    offering = create_offering(temple:, slug: "historical-provider", title: "Historical Provider", price_cents: 800)
    user = User.create!(email: "historical-provider@example.com", english_name: "Historical Provider", encrypted_password: User.password_hash("Password123!"))
    registration = create_registration(user:, offering:)
    create_payment(
      registration: registration,
      amount_cents: registration.total_price_cents,
      status: TemplePayment::STATUSES[:failed],
      method: TemplePayment::PAYMENT_METHODS[:cash],
      provider: "fake",
      provider_reference: "fake_history",
      processed_at: nil
    )
    temple.update!(payment_provider_settings: { "patron_checkout_provider" => "ecpay" })

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference -> { registration.temple_payments.count }, 1 do
      post start_checkout_account_registration_path(registration)
    end

    assert_equal "fake", registration.temple_payments.order(:created_at).last.provider
  end

  test "frozen registration payments hide checkout and block checkout start" do
    temple = create_temple(
      payment_provider_settings: {
        "billing" => {
          "payment_method_on_file" => false,
          "monthly_fee_cents" => 500_000,
          "grace_days" => 30,
          "grace_started_at" => 31.days.ago.iso8601
        }
      }
    )
    offering = create_offering(temple:, slug: "billing-frozen", title: "Billing Frozen Offering", price_cents: 1500)
    user = User.create!(
      email: "billingfrozen@example.com",
      english_name: "Billing Frozen",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    # Creating the registration itself is never blocked by billing --
    # only the payment step is. It's simply created pending.
    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: offering.slug,
        account_action: "event",
        account_registration_intake_form: { contact_name: "Billing Frozen", quantity: 1 }
      }
    end
    registration = TempleEventRegistration.order(:created_at).last
    assert_redirected_to payment_account_registration_path(registration)

    get payment_account_registration_path(registration)

    assert_response :success
    assert_includes response.body, "已收到您的報名，廟方正在處理中。"
    refute_includes response.body, "前往付款"

    assert_no_difference -> { registration.temple_payments.count } do
      post start_checkout_account_registration_path(registration)
    end

    assert_redirected_to payment_account_registration_path(registration)
    follow_redirect!
    assert_includes response.body, "已收到您的報名，廟方正在處理中。"
  end

  test "repeat-enabled service allows multiple registrations for the same user" do
    temple = create_temple(
      metadata: {
        "registration_periods" => [
          { "key" => "perennial", "label_zh" => "常年供燈", "label_en" => "Perennial" }
        ]
      }
    )
    offering = temple.temple_services.create!(
      slug: "incense-oil",
      title: "香油錢",
      description: "敬獻香油",
      currency: "TWD",
      price_cents: 300,
      status: "published",
      registration_period_key: "perennial",
      period_label: "常年供燈",
      metadata: {
        "allow_repeat_registrations" => true
      }
    )
    user = User.create!(
      email: "repeat@example.com",
      english_name: "Repeat Member",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: offering.slug,
        account_action: "service",
        account_registration_intake_form: {
          contact_name: "Repeat Member",
          quantity: 1
        }
      }
    end

    assert_difference -> { TempleEventRegistration.count }, 1 do
      post account_registrations_path, params: {
        offering: offering.slug,
        account_action: "service",
        account_registration_intake_form: {
          contact_name: "Repeat Member",
          quantity: 1
        }
      }
    end

    registrations = TempleEventRegistration.where(user: user, registrable: offering).order(:created_at)
    assert_equal 2, registrations.count
    assert_redirected_to payment_account_registration_path(registrations.last)
  end
end
