require "test_helper"

class AccountPortalFlowTest < ActionDispatch::IntegrationTest
  test "member sees registrations and payments and can update metadata" do
    temple = create_temple
    offering = create_offering(
      temple:,
      slug: "spring-lights",
      title: "新春點燈",
      price_cents: 800
    )
    user = User.create!(
      email: "member@example.com",
      english_name: "Member",
      encrypted_password: User.password_hash("Password123!")
    )
    registration = create_registration(
      user:,
      offering:,
      quantity: 1,
      contact_payload: { "primary_contact" => "Member" },
      logistics_payload: {},
      certificate_number: "CERT-001"
    )
    create_payment(
      registration:,
      method: TemplePayment::PAYMENT_METHODS[:line_pay],
      provider: "line_pay"
    )

    gallery_entry = temple.temple_gallery_entries.create!(
      title: "Lantern Parade",
      body: "Volunteers gathered at dusk.",
      event_date: Date.current,
      photo_urls: ["https://placehold.co/1200x800/f97316/ffffff?text=Gallery"]
    )

    sign_in_account(user, temple_slug: temple.slug)

    get account_dashboard_path
    assert_response :success
    assert_includes response.body, 'data-modal-trigger="account-contact-temple-modal"'
    assert_includes response.body, "新春點燈"
    assert_includes response.body, "CERT-001"

    get account_payments_path
    assert_response :success
    assert_includes response.body, "LINE Pay"

    get account_registrations_path
    assert_response :success
    assert_includes response.body, registration.reference_code

    get edit_account_registration_path(registration)
    assert_response :success

    patch account_registration_path(registration), params: {
      account_registration_metadata_form: {
        contact_name: "Member",
        contact_phone: "0912-000-000",
        contact_email: "member@example.com",
        household_notes: "2 位家人",
        arrival_window: "08:30",
        ceremony_notes: "Need seating"
      }
    }
    assert_redirected_to account_registration_path(registration)

    registration.reload
    assert_nil registration.contact_payload["phone"]
    assert_equal "Need seating", registration.metadata["ceremony_notes"]

    get account_galleries_path
    assert_response :success
    assert_includes response.body, gallery_entry.title

    get account_gallery_path(gallery_entry)
    assert_response :success
    assert_includes response.body, gallery_entry.title
  end

  test "profile page renders password login status" do
    temple = create_temple
    user = User.create!(
      email: "profile-password@example.com",
      english_name: "Profile Password",
      encrypted_password: User.password_hash("Password123!")
    )

    sign_in_account(user, temple_slug: temple.slug)

    get account_profile_path

    assert_response :success
    assert_includes response.body, I18n.t("account.profile.password.title")
    assert_includes response.body, I18n.t("account.profile.password.enabled")
  end

  test "account pending registration allows core field edits" do
    temple = create_temple
    offering = create_offering(temple:, slug: "pending-edit", title: "待付款編輯測試")
    user = User.create!(
      email: "pending-edit@example.com",
      english_name: "Pending User",
      encrypted_password: User.password_hash("Password123!")
    )
    dependent = create_dependent_for(user, name: "Dependent Member")
    registration = create_registration(
      user:,
      offering:,
      quantity: 1,
      metadata: { "registrant_scope" => "self" }
    )

    sign_in_account(user, temple_slug: temple.slug)

    patch account_registration_path(registration), params: {
      account_registration_metadata_form: {
        quantity: 3,
        registrant_scope: "dependent",
        dependent_id: dependent.id,
        contact_name: "Dependent Member",
        contact_phone: "0900-123-123",
        contact_email: "pending-edit@example.com",
        household_notes: "family",
        arrival_window: "09:00",
        ceremony_notes: "Pending edit note"
      }
    }

    assert_redirected_to account_registration_path(registration)
    registration.reload
    assert_equal 3, registration.quantity
    assert_equal "dependent", registration.metadata["registrant_scope"]
    assert_equal dependent.id.to_s, registration.metadata["dependent_id"]
    assert_equal "Dependent Member", registration.metadata["registrant_name"]
  end

  test "account paid registration blocks core field edits" do
    temple = create_temple
    offering = create_offering(temple:, slug: "paid-edit", title: "已付款編輯測試")
    user = User.create!(
      email: "paid-edit@example.com",
      english_name: "Paid User",
      encrypted_password: User.password_hash("Password123!")
    )
    dependent = create_dependent_for(user, name: "Paid Dependent")
    registration = create_registration(
      user:,
      offering:,
      quantity: 1,
      contact_payload: { "primary_contact" => "Paid User", "phone" => "0911-111-111", "email" => "paid-edit@example.com" },
      metadata: { "registrant_scope" => "self" }
    )
    create_payment(registration: registration)

    sign_in_account(user, temple_slug: temple.slug)

    patch account_registration_path(registration), params: {
      account_registration_metadata_form: {
        quantity: 4,
        registrant_scope: "dependent",
        dependent_id: dependent.id,
        contact_name: "Paid User",
        contact_phone: "0900-456-456",
        contact_email: "paid-edit@example.com",
        household_notes: "paid household",
        arrival_window: "10:00",
        ceremony_notes: "Paid note"
      }
    }

    assert_redirected_to account_registration_path(registration)
    registration.reload
    assert_equal 1, registration.quantity
    assert_equal "self", registration.metadata["registrant_scope"]
    assert_nil registration.metadata["dependent_id"]
    assert_equal "0911-111-111", registration.contact_payload["phone"]
    assert_equal "Paid note", registration.metadata["ceremony_notes"]
    assert_equal "10:00", registration.logistics_payload["arrival_window"]
  end

  test "account pending update keeps duplicate guard on identity" do
    temple = create_temple
    offering = create_offering(temple:, slug: "duplicate-guard", title: "重複身份檢查")
    user = User.create!(
      email: "duplicate-guard@example.com",
      english_name: "Guard User",
      encrypted_password: User.password_hash("Password123!")
    )
    dependent = create_dependent_for(user, name: "Guard Dependent")
    registration = create_registration(
      user:,
      offering:,
      quantity: 1,
      metadata: { "registrant_scope" => "self" }
    )
    _existing = create_registration(
      user:,
      offering:,
      quantity: 1,
      metadata: {
        "registrant_scope" => "dependent",
        "dependent_id" => dependent.id.to_s,
        "registrant_name" => "Guard Dependent"
      }
    )

    sign_in_account(user, temple_slug: temple.slug)

    patch account_registration_path(registration), params: {
      account_registration_metadata_form: {
        quantity: 2,
        registrant_scope: "dependent",
        dependent_id: dependent.id,
        contact_name: "Guard User",
        contact_phone: "0900-000-000",
        contact_email: "duplicate-guard@example.com"
      }
    }

    assert_response :unprocessable_content
    assert_includes response.body, I18n.t("account.registrations.new.duplicate_error")
    registration.reload
    assert_equal "self", registration.metadata["registrant_scope"]
    assert_nil registration.metadata["dependent_id"]
  end

  test "account gathering registration remains view only after create" do
    temple = create_temple
    gathering = temple.temple_gatherings.create!(
      slug: "community-circle",
      title: "Community Circle",
      currency: "TWD",
      price_cents: 0,
      status: "published"
    )
    user = User.create!(
      email: "gathering-view-only@example.com",
      english_name: "Gathering User",
      encrypted_password: User.password_hash("Password123!")
    )
    registration = create_registration(
      user:,
      offering: gathering,
      metadata: { "registrant_scope" => "self" }
    )

    sign_in_account(user, temple_slug: temple.slug)

    get account_registration_path(registration)
    assert_response :success
    assert_no_match(/Edit registration/, response.body)

    get edit_account_registration_path(registration)
    assert_redirected_to account_registration_path(registration)
  end

  private

  def create_dependent_for(user, name:)
    dependent = Dependent.create!(english_name: name)
    UserDependent.create!(
      user: user,
      dependent: dependent,
      role: "family",
      relationship_label: "Family"
    )
    dependent
  end
end
