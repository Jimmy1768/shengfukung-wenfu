# frozen_string_literal: true

require "test_helper"

class Admin::ArchivesAccessTest < ActionDispatch::IntegrationTest
  def setup
    @temple = create_temple
    @offering = @temple.temple_offerings.create!(
      slug: "spring-festival",
      title: "Spring Festival",
      starts_on: Date.current,
      ends_on: Date.current + 1.day,
      price_cents: 2000,
      currency: "TWD",
      offering_type: "general"
    )
    @registration = @temple.temple_event_registrations.create!(
      registrable: @offering,
      reference_code: "REG-ARCHIVE",
      quantity: 1,
      unit_price_cents: 2000,
      total_price_cents: 2000,
      currency: "TWD",
      payment_status: "paid",
      fulfillment_status: "fulfilled",
      certificate_number: "CERT-ARCHIVE",
      created_at: Time.zone.local(Time.zone.today.year, 1, 15)
    )
    TemplePayment.create!(
      temple_event_registration: @registration,
      temple: @temple,
      amount_cents: 2000,
      currency: "TWD",
      payment_method: TemplePayment::PAYMENT_METHODS[:cash],
      status: TemplePayment::STATUSES[:completed],
      provider: "demo",
      provider_account: "temple",
      payment_payload: {},
      metadata: {},
      processed_at: Time.zone.local(Time.zone.today.year, 1, 20)
    )
  end

  test "owner can view details and export archives" do
    owner = create_admin_user(temple: @temple)
    sign_in_admin(owner)

    get admin_archives_path
    assert_response :success
    assert_select ".empty-state-card", text: /請先選擇日期區間以檢視封存紀錄。/

    get admin_archives_path, params: {
      filter: {
        start_date: Time.zone.today.beginning_of_year.to_s,
        end_date: Time.zone.today.end_of_year.to_s
      }
    }
    assert_response :success
    assert_select ".admin-table-card table tbody tr", minimum: 1

    assert_difference -> { SystemAuditLog.where(action: "admin.archives.export").count }, 1 do
      get admin_archive_registrations_export_path(format: :csv, year: Time.zone.today.year)
      assert_response :success
      assert_match "text/csv", response.media_type
    end
  end

  test "owner can use month preset to load archive payments" do
    owner = create_admin_user(temple: @temple)
    @registration.temple_payments.first.update!(processed_at: Time.zone.today.beginning_of_month + 1.day)
    sign_in_admin(owner)

    get admin_archives_path, params: { filter: { start_date: Time.zone.today.beginning_of_month.to_date.to_s, end_date: Time.zone.today.end_of_month.to_date.to_s } }

    assert_response :success
    assert_select ".metric strong", text: /20(?:\.0)?/
    assert_select ".admin-table-card table tbody tr", minimum: 1
  end

  test "owner can search archives by one patron without date range" do
    owner = create_admin_user(temple: @temple)
    user = User.create!(
      email: "archive-patron@example.com",
      english_name: "謝文福",
      encrypted_password: User.password_hash("Password123!"),
      metadata: { "phone" => "0911-000-000" }
    )
    @registration.update!(user: user, contact_payload: { "name" => "謝文福" })
    @registration.temple_payments.first.update!(user: user)

    sign_in_admin(owner)

    get admin_archives_path, params: { filter: { query: "謝文福" } }

    assert_response :success
    assert_select ".empty-state-card", false
    assert_select ".admin-table-card table tbody tr", minimum: 1
    assert_match "Archive history for 謝文福", response.body
  end

  test "payments export respects resolved patron query without date range" do
    owner = create_admin_user(temple: @temple)
    user = User.create!(
      email: "archive-export@example.com",
      english_name: "彭雅玲",
      encrypted_password: User.password_hash("Password123!"),
      metadata: { "phone" => "0912-000-000" }
    )
    @registration.update!(user: user, contact_payload: { "name" => "彭雅玲" })
    @registration.temple_payments.first.update!(user: user)

    sign_in_admin(owner)

    get admin_archive_payments_export_path(format: :csv), params: { filter: { query: "彭雅玲" } }

    assert_response :success
    assert_match "text/csv", response.media_type
    assert_includes response.headers["Content-Disposition"], "archive-export-example-com"
    assert_includes response.body, "彭雅玲"
  end

  test "owner must refine patron query when multiple archive patrons match without date range" do
    owner = create_admin_user(temple: @temple)

    [ "謝文福", "謝文成" ].each_with_index do |name, index|
      user = User.create!(
        email: "archive-patron-#{index}@example.com",
        english_name: name,
        encrypted_password: User.password_hash("Password123!"),
        metadata: { "phone" => "0911-000-00#{index}" }
      )

      offering = @temple.temple_offerings.create!(
        slug: "archive-offering-#{index}",
        title: "Archive Offering #{index}",
        starts_on: Date.current,
        ends_on: Date.current + 1.day,
        price_cents: 2000,
        currency: "TWD",
        offering_type: "general"
      )
      registration = @temple.temple_event_registrations.create!(
        registrable: offering,
        user: user,
        reference_code: "REG-AMB-#{index}",
        quantity: 1,
        unit_price_cents: 2000,
        total_price_cents: 2000,
        currency: "TWD",
        payment_status: "paid",
        fulfillment_status: "fulfilled",
        created_at: Time.zone.local(Time.zone.today.year, 2, 15)
      )
      TemplePayment.create!(
        temple_event_registration: registration,
        temple: @temple,
        user: user,
        amount_cents: 2000,
        currency: "TWD",
        payment_method: TemplePayment::PAYMENT_METHODS[:cash],
        status: TemplePayment::STATUSES[:completed],
        provider: "demo",
        provider_account: "temple",
        payment_payload: {},
        metadata: {},
        processed_at: Time.zone.local(Time.zone.today.year, 2, 20)
      )
    end

    sign_in_admin(owner)

    get admin_archives_path, params: { filter: { query: "謝文" } }

    assert_response :success
    assert_select ".empty-state-card", text: /請先選擇日期區間以檢視封存紀錄。/
    assert_select ".filter-error-list li", text: /Multiple patrons matched/
  end

  test "staff without archive permissions is redirected" do
    staff = create_admin_user(
      temple: @temple,
      role: "staff",
      membership_role: "staff",
      permission_overrides: { view_financials: false, export_financials: false }
    )

    sign_in_admin(staff)
    get admin_archives_path
    assert_redirected_to admin_dashboard_path
  end

  test "export route is blocked without capability" do
    staff = create_admin_user(
      temple: @temple,
      role: "staff",
      membership_role: "staff",
      permission_overrides: { view_financials: false, export_financials: false }
    )
    sign_in_admin(staff)

    get admin_archive_registrations_export_path(format: :csv, year: Time.zone.today.year)
    assert_redirected_to admin_archives_path(year: Time.zone.today.year)
  end
end
