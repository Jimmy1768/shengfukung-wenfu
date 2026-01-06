# frozen_string_literal: true

require "test_helper"

class Admin::ArchivesAccessTest < ActionDispatch::IntegrationTest
  def setup
    @temple = create_temple
    @offering = @temple.temple_offerings.create!(
      slug: "spring-festival",
      title: "Spring Festival",
      price_cents: 2000,
      currency: "TWD",
      offering_type: "general"
    )
    @registration = @temple.temple_event_registrations.create!(
      temple_offering: @offering,
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
      processed_at: Time.zone.local(Time.zone.today.year, 1, 20)
    )
  end

  test "owner can view details and export archives" do
    owner = create_admin_user(temple: @temple)
    sign_in_admin(owner)

    get admin_archives_path
    assert_response :success
    assert_select "h2", text: /Registrations/
    assert_select ".archive-detail-table table tbody tr", minimum: 1
    assert_select "a", text: /Export CSV/

    assert_difference -> { SystemAuditLog.where(action: "admin.archives.export").count }, 1 do
      get admin_archive_registrations_export_path(format: :csv, year: Time.zone.today.year)
      assert_response :success
      assert_match "text/csv", response.media_type
    end
  end

  test "staff only sees snapshots without detail" do
    staff = create_admin_user(
      temple: @temple,
      role: "staff",
      membership_role: "staff",
      permission_overrides: { view_financials: false, export_financials: false }
    )

    sign_in_admin(staff)
    get admin_archives_path
    assert_response :success
    assert_select "section.card h2", text: "Limited access"
    assert_select ".archive-detail-table", false
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
