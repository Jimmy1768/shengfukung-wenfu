require "test_helper"

class AdminOrdersAndPaymentsAccessTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @offering = TempleOffering.create!(
      temple: @temple,
      slug: "lamp",
      title: "Lamp",
      starts_on: Date.current,
      ends_on: Date.current + 1.day,
      offering_type: "general",
      currency: "TWD",
      price_cents: 500
    )
    @user = User.create!(
      email: "registrant@example.com",
      english_name: "Registrant",
      encrypted_password: User.password_hash("Password123!")
    )
    @registration = TempleEventRegistration.create!(
      temple: @temple,
      registrable: @offering,
      user: @user,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )
    @payment = TemplePayment.create!(
      temple: @temple,
      temple_event_registration: @registration,
      provider: "demo",
      provider_account: "temple",
      payment_method: TemplePayment::PAYMENT_METHODS[:cash],
      status: TemplePayment::STATUSES[:completed],
      amount_cents: 500,
      currency: "TWD",
      metadata: {},
      payment_payload: {}
    )
  end

  test "admin with manage_registrations can view orders index" do
    admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
    permission.update!(manage_registrations: true)

    sign_in_admin(admin)

    get admin_orders_path

    assert_response :success
    assert_includes response.body, @registration.reference_code
  end

  test "admin without manage_registrations is redirected from orders index" do
    admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
    permission.update!(manage_registrations: false)

    sign_in_admin(admin)
    get admin_orders_path

    assert_redirected_to admin_dashboard_path
  end

  test "admin with view_financials can view payments index" do
    admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
    permission.update!(view_financials: true)

    sign_in_admin(admin)

    get admin_payments_path

    assert_response :success
    assert_includes response.body, "付款報表"
  end

  test "admin without view_financials is redirected from payments index" do
    admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
    permission.update!(view_financials: false)

    sign_in_admin(admin)
    get admin_payments_path

    assert_redirected_to admin_dashboard_path
  end

  test "admin with export_financials can download csv" do
    admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
    permission.update!(view_financials: true, export_financials: true)

    sign_in_admin(admin)

    get export_admin_payments_path(format: :csv)

    assert_response :success
    assert_includes response.content_type, "text/csv"
    assert_includes response.body, "Reference"
  end

  test "payments export respects active date filters" do
    admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
    permission.update!(view_financials: true, export_financials: true)

    older_registration = TempleEventRegistration.create!(
      temple: @temple,
      registrable: @offering,
      user: @user,
      quantity: 1,
      contact_payload: {},
      logistics_payload: {},
      metadata: {},
      created_at: 6.months.ago
    )
    TemplePayment.create!(
      temple: @temple,
      temple_event_registration: older_registration,
      provider: "demo",
      provider_account: "temple",
      payment_method: TemplePayment::PAYMENT_METHODS[:cash],
      status: TemplePayment::STATUSES[:completed],
      amount_cents: 700,
      currency: "TWD",
      processed_at: 6.months.ago,
      metadata: {},
      payment_payload: {}
    )

    sign_in_admin(admin)

    get export_admin_payments_path(format: :csv), params: {
      filter: {
        start_date: 30.days.ago.to_date.to_s,
        end_date: Date.current.to_s
      }
    }

    assert_response :success
    assert_includes response.headers["Content-Disposition"], 30.days.ago.to_date.to_s
    assert_includes response.body, @registration.reference_code
    refute_includes response.body, older_registration.reference_code
  end

  test "payments month preset filters the visible report" do
    travel_to Time.zone.local(2026, 3, 12, 12, 0, 0) do
      admin = create_admin_user(temple: @temple)
      permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
      permission.update!(view_financials: true)

      last_month_registration = TempleEventRegistration.create!(
        temple: @temple,
        registrable: @offering,
        user: @user,
        quantity: 1,
        contact_payload: {},
        logistics_payload: {},
        metadata: {},
        created_at: 1.month.ago
      )
      TemplePayment.create!(
        temple: @temple,
        temple_event_registration: last_month_registration,
        provider: "demo",
        provider_account: "temple",
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        status: TemplePayment::STATUSES[:completed],
        amount_cents: 700,
        currency: "TWD",
        processed_at: 1.month.ago,
        metadata: {},
        payment_payload: {}
      )

      sign_in_admin(admin)

      get admin_payments_path, params: {
        filter: {
          month_preset: "this_month"
        }
      }

      assert_response :success
      assert_includes response.body, "本月"
      assert_includes response.body, "NT$5"
      refute_includes response.body, "NT$7"
    end
  end

  test "payments month preset preserves status filter context" do
    travel_to Time.zone.local(2026, 3, 12, 12, 0, 0) do
      admin = create_admin_user(temple: @temple)
      permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
      permission.update!(view_financials: true)

      @payment.update!(status: TemplePayment::STATUSES[:refunded], amount_cents: 900)
      TemplePayment.create!(
        temple: @temple,
        temple_event_registration: @registration,
        provider: "demo",
        provider_account: "temple",
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        status: TemplePayment::STATUSES[:completed],
        amount_cents: 500,
        currency: "TWD",
        processed_at: Time.zone.now,
        metadata: {},
        payment_payload: {}
      )

      sign_in_admin(admin)

      get admin_payments_path, params: {
        filter: {
          month_preset: "this_month",
          status: TemplePayment::STATUSES[:refunded]
        }
      }

      assert_response :success
      assert_includes response.body, "已退款"
      assert_includes response.body, "NT$9"
      refute_includes response.body, "NT$5"
    end
  end

  test "admin without export_financials cannot download csv" do
    admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: admin.admin_account, temple: @temple)
    permission.update!(view_financials: true, export_financials: false)

    sign_in_admin(admin)

    get export_admin_payments_path(format: :csv)

    assert_redirected_to admin_dashboard_path
  end

  test "payments export stays scoped to the selected temple for multi-temple owners" do
    alpha = create_temple(name: "Alpha Temple", slug: "alpha-temple")
    beta = create_temple(name: "Beta Temple", slug: "beta-temple")
    owner = create_admin_user(temple: alpha)
    AdminPermission.find_by(admin_account: owner.admin_account, temple: alpha)&.update!(
      view_financials: true,
      export_financials: true,
      manage_permissions: true
    )

    AdminTempleMembership.create!(
      admin_account: owner.admin_account,
      temple: beta,
      role: "owner"
    )
    AdminPermission.create!(
      admin_account: owner.admin_account,
      temple: beta,
      view_financials: true,
      export_financials: true,
      manage_permissions: true
    )

    alpha_offering = create_offering(temple: alpha, slug: "alpha-offering", title: "Alpha Offering")
    beta_offering = create_offering(temple: beta, slug: "beta-offering", title: "Beta Offering")
    alpha_user = User.create!(
      email: "alpha-patron@example.com",
      english_name: "Alpha Patron",
      encrypted_password: User.password_hash("Password123!")
    )
    beta_user = User.create!(
      email: "beta-patron@example.com",
      english_name: "Beta Patron",
      encrypted_password: User.password_hash("Password123!")
    )
    alpha_registration = create_registration(user: alpha_user, offering: alpha_offering, reference_code: "REG-ALPHA")
    beta_registration = create_registration(user: beta_user, offering: beta_offering, reference_code: "REG-BETA")
    create_payment(registration: alpha_registration, amount_cents: 111)
    create_payment(registration: beta_registration, amount_cents: 222)

    sign_in_admin(owner)

    get export_admin_payments_path(format: :csv)

    assert_response :success
    assert_includes response.body, "REG-ALPHA"
    refute_includes response.body, "REG-BETA"

    post admin_temple_switch_path, params: { temple_switch: { temple_slug: beta.slug } }
    follow_redirect!

    get export_admin_payments_path(format: :csv)

    assert_response :success
    assert_includes response.body, "REG-BETA"
    refute_includes response.body, "REG-ALPHA"
  end
end
