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

  def create_admin_user(temple: create_temple, create_permission: true, password: "Password123!")
    user = User.create!(
      email: "admin-#{SecureRandom.hex(2)}@example.com",
      encrypted_password: User.password_hash(password),
      english_name: "Admin User"
    )
    admin_account = AdminAccount.create!(
      user:,
      active: true,
      role: "owner"
    )
    AdminTempleMembership.create!(admin_account:, temple:, role: "owner")
    AdminPermission.create!(admin_account:, temple:, manage_permissions: true) if create_permission
    user
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

  def sign_in_account(user, password: "Password123!")
    post account_sessions_path, params: { session: { email: user.email, password: } }
    follow_redirect! if response.redirect?
  end
end
