ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require "securerandom"
module TestDataHelpers
  def create_temple(attrs = {})
    Temple.create!(
      { slug: "temple-#{SecureRandom.hex(2)}", name: "Test Temple" }.merge(attrs)
    )
  end

  def create_admin_user(
    temple: create_temple,
    create_permission: true,
    password: "Password123!",
    role: "owner",
    membership_role: nil,
    permission_overrides: {}
  )
    user = User.create!(
      email: "admin-#{SecureRandom.hex(2)}@example.com",
      encrypted_password: User.password_hash(password),
      english_name: "Admin User"
    )
    admin_account = AdminAccount.create!(
      user:,
      active: true,
      role: role.to_s
    )
    AdminTempleMembership.create!(
      admin_account:,
      temple:,
      role: (membership_role || role).to_s
    )
    if create_permission
      AdminPermission.create!(
        { admin_account:, temple:, manage_permissions: role.to_s == "owner" }
          .merge(permission_overrides)
      )
    end
    user
  end

  def create_offering(temple: create_temple, price_cents: 1_000, currency: "TWD", **attrs)
    temple.temple_offerings.create!(
      {
        slug: "offering-#{SecureRandom.hex(2)}",
        title: "Test Offering",
        offering_type: "general",
        starts_on: Date.current,
        ends_on: Date.current + 1.day,
        price_cents:,
        currency:
      }.merge(attrs)
    )
  end

  def create_registration(user:, offering:, **attrs)
    TempleEventRegistration.create!(
      {
        temple: offering.temple,
        registrable: offering,
        user:,
        reference_code: "REG-#{SecureRandom.hex(2).upcase}",
        quantity: 1,
        unit_price_cents: offering.price_cents,
        total_price_cents: offering.price_cents,
        currency: offering.currency,
        payment_status: "pending",
        fulfillment_status: "open",
        contact_payload: { "name" => user.english_name, "email" => user.email }
      }.merge(attrs)
    )
  end

  def create_payment(registration:, amount_cents: registration.total_price_cents, status: TemplePayment::STATUSES[:completed], method: TemplePayment::PAYMENT_METHODS[:cash], **attrs)
    defaults = {
      temple: registration.temple,
      temple_event_registration: registration,
      user: registration.user,
      amount_cents:,
      currency: registration.currency,
      payment_method: method,
      status:,
      processed_at: Time.current,
      provider: "demo",
      provider_account: "temple",
      payment_payload: {},
      metadata: {}
    }
    TemplePayment.create!(defaults.merge(attrs))
  end
end

class ActiveSupport::TestCase
  self.use_transactional_tests = true
  include TestDataHelpers

  def assert_valid(record, message = nil)
    message ||= "Expected #{record.inspect} to be valid"
    assert record.valid?, message
  end
end

class ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers
  include TestDataHelpers

  def sign_in_admin(user, password: "Password123!")
    post admin_sessions_path, params: { session: { email: user.email, password: } }
    follow_redirect! if response.redirect?
  end

  def sign_in_account(user, password: "Password123!", temple_slug: nil)
    request_params = {}
    request_params[:temple] = temple_slug if temple_slug.present?
    request_params[:session] = { email: user.email, password: }
    post account_sessions_path, params: request_params
    follow_redirect! if response.redirect?
  end
end
