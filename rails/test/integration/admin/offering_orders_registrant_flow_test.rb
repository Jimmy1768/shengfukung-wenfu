require "test_helper"

class AdminOfferingOrdersRegistrantFlowTest < ActionDispatch::IntegrationTest
  setup do
    @temple = create_temple
    @admin = create_admin_user(temple: @temple)
    permission = AdminPermission.find_by(admin_account: @admin.admin_account, temple: @temple)
    permission.update!(manage_registrations: true)

    @gathering = @temple.temple_gatherings.create!(
      slug: "community-satsang",
      title: "Community Satsang",
      currency: "TWD",
      price_cents: 0,
      status: "published"
    )
    @event = TempleOffering.create!(
      temple: @temple,
      slug: "spring-rite",
      title: "Spring Rite",
      starts_on: Date.current,
      ends_on: Date.current + 1.day,
      offering_type: "general",
      currency: "TWD",
      price_cents: 1000
    )
    @patron = User.create!(
      email: "household@example.com",
      english_name: "Household Owner",
      encrypted_password: User.password_hash("Password123!")
    )
    @other_patron = User.create!(
      email: "other-household@example.com",
      english_name: "Other Household",
      encrypted_password: User.password_hash("Password123!")
    )
    @dependent = create_dependent_for(@patron, name: "Family Member")
    @other_dependent = create_dependent_for(@other_patron, name: "Other Family")
  end

  test "admin creates dependent registration and stores registrant metadata" do
    sign_in_admin(@admin)

    assert_difference -> { @temple.temple_event_registrations.count }, 1 do
      post admin_gathering_offering_orders_path(@gathering), params: {
        temple_event_registration: {
          user_id: @patron.id,
          quantity: 1,
          registrant_scope: "dependent",
          dependent_id: @dependent.id
        }
      }
    end

    registration = @temple.temple_event_registrations.order(created_at: :desc).first
    assert_redirected_to admin_gathering_offering_order_path(@gathering, registration)
    assert_equal "dependent", registration.metadata["registrant_scope"]
    assert_equal @dependent.id.to_s, registration.metadata["dependent_id"]
    assert_equal "Family Member", registration.metadata["registrant_name"]

    get admin_gathering_offering_orders_path(@gathering)
    assert_response :success
    assert_includes response.body, "Family Member"
  end

  test "admin create redirects to existing registration for same dependent scope" do
    existing = create_registration(
      user: @patron,
      offering: @gathering,
      metadata: {
        "registrant_scope" => "dependent",
        "dependent_id" => @dependent.id.to_s,
        "registrant_name" => "Family Member"
      },
      contact_payload: { "primary_contact" => "Family Member" }
    )

    sign_in_admin(@admin)

    assert_no_difference -> { @temple.temple_event_registrations.count } do
      post admin_gathering_offering_orders_path(@gathering), params: {
        temple_event_registration: {
          user_id: @patron.id,
          quantity: 1,
          registrant_scope: "dependent",
          dependent_id: @dependent.id
        }
      }
    end

    assert_redirected_to admin_gathering_offering_order_path(@gathering, existing)
  end

  test "gathering registrations cannot be edited after creation" do
    registration = create_registration(
      user: @patron,
      offering: @gathering,
      metadata: { "registrant_scope" => "self" }
    )

    sign_in_admin(@admin)

    get admin_gathering_offering_order_path(@gathering, registration)
    assert_response :success
    assert_no_match(/Edit attendance/, response.body)

    get edit_admin_gathering_offering_order_path(@gathering, registration)
    assert_redirected_to admin_gathering_offering_order_path(@gathering, registration)
  end

  test "admin pending registration allows core field edits" do
    registration = create_registration(
      user: @patron,
      offering: @event,
      quantity: 1,
      unit_price_cents: 1000,
      total_price_cents: 1000,
      currency: "TWD",
      metadata: {
        "registrant_scope" => "dependent",
        "dependent_id" => @dependent.id.to_s,
        "registrant_name" => @dependent.english_name
      }
    )

    sign_in_admin(@admin)

    patch admin_event_offering_order_path(@event, registration), params: {
      temple_event_registration: {
        user_id: @other_patron.id,
        quantity: 9,
        unit_price_cents: 2500,
        currency: "USD",
        registrant_scope: "dependent",
        dependent_id: @other_dependent.id,
        logistics_details: { preferred_slot: "Afternoon" }
      }
    }

    assert_redirected_to admin_event_offering_order_path(@event, registration)
    registration.reload
    assert_equal @other_patron.id, registration.user_id
    assert_equal 9, registration.quantity
    assert_equal 2500, registration.unit_price_cents
    assert_equal "USD", registration.currency
    assert_equal @other_dependent.id.to_s, registration.metadata["dependent_id"]
    assert_equal "dependent", registration.metadata["registrant_scope"]
    assert_equal "Other Family", registration.metadata["registrant_name"]
    assert_equal "Afternoon", registration.logistics_payload["preferred_slot"]
  end

  test "admin paid registration blocks core field edits but keeps metadata editable" do
    registration = create_registration(
      user: @patron,
      offering: @event,
      quantity: 1,
      unit_price_cents: 1000,
      total_price_cents: 1000,
      currency: "TWD",
      metadata: {
        "registrant_scope" => "dependent",
        "dependent_id" => @dependent.id.to_s,
        "registrant_name" => @dependent.english_name
      }
    )
    create_payment(registration: registration)

    sign_in_admin(@admin)

    patch admin_event_offering_order_path(@event, registration), params: {
      temple_event_registration: {
        user_id: @other_patron.id,
        quantity: 9,
        unit_price_cents: 2500,
        currency: "USD",
        registrant_scope: "dependent",
        dependent_id: @other_dependent.id,
        contact_details: { primary_contact: "Changed After Paid" },
        logistics_details: { preferred_slot: "Evening" }
      }
    }

    assert_redirected_to admin_event_offering_order_path(@event, registration)
    registration.reload
    assert_equal @patron.id, registration.user_id
    assert_equal 1, registration.quantity
    assert_equal 1000, registration.unit_price_cents
    assert_equal "TWD", registration.currency
    assert_equal @dependent.id.to_s, registration.metadata["dependent_id"]
    assert_equal "dependent", registration.metadata["registrant_scope"]
    assert_not_equal "Changed After Paid", registration.contact_payload["primary_contact"]
    assert_equal "Evening", registration.logistics_payload["preferred_slot"]
  end

  test "admin pending update keeps duplicate guard on registrant identity" do
    registration = create_registration(
      user: @patron,
      offering: @event,
      metadata: { "registrant_scope" => "self" }
    )
    existing = create_registration(
      user: @patron,
      offering: @event,
      metadata: {
        "registrant_scope" => "dependent",
        "dependent_id" => @dependent.id.to_s,
        "registrant_name" => "Family Member"
      }
    )

    sign_in_admin(@admin)

    patch admin_event_offering_order_path(@event, registration), params: {
      temple_event_registration: {
        user_id: @patron.id,
        registrant_scope: "dependent",
        dependent_id: @dependent.id
      }
    }

    assert_redirected_to admin_event_offering_order_path(@event, existing)
    registration.reload
    assert_equal "self", registration.metadata["registrant_scope"]
    assert_nil registration.metadata["dependent_id"]
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
