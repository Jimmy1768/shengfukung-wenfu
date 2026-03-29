require "test_helper"

class AdminAccountingReportingGatheringsTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: @admin.admin_account, temple: @temple)
    permission.update!(manage_registrations: true, view_financials: true)

    @user = User.create!(
      email: "reporting@example.com",
      english_name: "Reporting User",
      encrypted_password: User.password_hash("Password123!")
    )

    @event = TempleOffering.create!(
      temple: @temple,
      slug: "spring-event",
      title: "Spring Event",
      starts_on: Date.current,
      ends_on: Date.current + 1.day,
      offering_type: "general",
      currency: "TWD",
      price_cents: 700
    )
    @gathering = @temple.temple_gatherings.create!(
      slug: "free-gathering",
      title: "Free Gathering",
      currency: "TWD",
      price_cents: 0,
      status: "published"
    )
  end

  test "orders filter can isolate gatherings and show no payment required state" do
    TempleEventRegistration.create!(
      temple: @temple,
      registrable: @event,
      user: @user,
      quantity: 1,
      unit_price_cents: 700,
      total_price_cents: 700,
      currency: "TWD",
      payment_status: TempleEventRegistration::PAYMENT_STATUSES[:pending],
      fulfillment_status: TempleEventRegistration::FULFILLMENT_STATUSES[:open],
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )
    free_registration = TempleEventRegistration.create!(
      temple: @temple,
      registrable: @gathering,
      user: @user,
      quantity: 1,
      unit_price_cents: 0,
      total_price_cents: 0,
      currency: "TWD",
      payment_status: TempleEventRegistration::PAYMENT_STATUSES[:pending],
      fulfillment_status: TempleEventRegistration::FULFILLMENT_STATUSES[:open],
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )

    sign_in_admin(@admin)

    get admin_orders_path, params: { filter: { offering_kind: "gatherings" } }

    assert_response :success
    assert_includes response.body, "Free Gathering"
    assert_no_match(/orders-source__title\">Spring Event</, response.body)
    assert_includes response.body, I18n.t("admin.orders.index.table.no_payment_required")

    get admin_gathering_offering_order_path(@gathering, free_registration)
    assert_response :success
    assert_includes response.body, I18n.t("admin.orders.index.table.no_payment_required")
  end

  test "payments filter can isolate gathering payments" do
    event_registration = TempleEventRegistration.create!(
      temple: @temple,
      registrable: @event,
      user: @user,
      quantity: 1,
      unit_price_cents: 700,
      total_price_cents: 700,
      currency: "TWD",
      payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid],
      fulfillment_status: TempleEventRegistration::FULFILLMENT_STATUSES[:open],
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )
    gathering_registration = TempleEventRegistration.create!(
      temple: @temple,
      registrable: @gathering,
      user: @user,
      quantity: 1,
      unit_price_cents: 500,
      total_price_cents: 500,
      currency: "TWD",
      payment_status: TempleEventRegistration::PAYMENT_STATUSES[:paid],
      fulfillment_status: TempleEventRegistration::FULFILLMENT_STATUSES[:open],
      contact_payload: {},
      logistics_payload: {},
      metadata: {}
    )

    TemplePayment.create!(
      temple: @temple,
      temple_event_registration: event_registration,
      user: @user,
      provider: "demo",
      provider_account: "temple",
      payment_method: TemplePayment::PAYMENT_METHODS[:cash],
      status: TemplePayment::STATUSES[:completed],
      amount_cents: 700,
      currency: "TWD",
      metadata: {},
      payment_payload: {}
    )
    TemplePayment.create!(
      temple: @temple,
      temple_event_registration: gathering_registration,
      user: @user,
      provider: "demo",
      provider_account: "temple",
      payment_method: TemplePayment::PAYMENT_METHODS[:cash],
      status: TemplePayment::STATUSES[:completed],
      amount_cents: 500,
      currency: "TWD",
      metadata: {},
      payment_payload: {}
    )

    sign_in_admin(@admin)

    get admin_payments_path, params: { filter: { offering_kind: "gatherings" } }

    assert_response :success
    gathering_label = Regexp.escape("#{I18n.t('admin.filters.offering.gathering_prefix')} · Free Gathering")
    event_label = Regexp.escape("#{I18n.t('admin.filters.offering.event_prefix')} · Spring Event")
    assert_match(/<tbody>[\s\S]*#{gathering_label}[\s\S]*<\/tbody>/, response.body)
    assert_no_match(/<tbody>[\s\S]*#{event_label}[\s\S]*<\/tbody>/, response.body)
  end
end
