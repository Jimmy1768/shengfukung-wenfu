# frozen_string_literal: true

module AdminReviewTasks
  DEFAULT_EMAIL = "operator-ui-review@example.test"
  DEFAULT_PASSWORD = "Password123!"
  DEFAULT_TEMPLE_SLUG = "operator-ui-review-temple"
  DEFAULT_TEMPLE_NAME = "Operator UI Review Temple"
  DEFAULT_ADMIN_NAME = "Operator UI Reviewer"

  module_function

  def ensure_local_environment!
    return unless Rails.env.production? || Rails.env.test?

    raise "admin_review tasks are local review helpers; run with RAILS_ENV=development and an isolated PGDATABASE"
  end

  def seed_metadata
    {
      provisioned_by: "admin_review:prepare",
      provisioned_at: Time.current.iso8601
    }
  end

  def create_or_update_reviewer!
    ensure_local_environment!

    email = ENV.fetch("ADMIN_REVIEW_EMAIL", DEFAULT_EMAIL).downcase.strip
    password = ENV.fetch("ADMIN_REVIEW_PASSWORD", DEFAULT_PASSWORD)
    temple_slug = ENV.fetch("ADMIN_REVIEW_TEMPLE_SLUG", DEFAULT_TEMPLE_SLUG)
    temple_name = ENV.fetch("ADMIN_REVIEW_TEMPLE_NAME", DEFAULT_TEMPLE_NAME)
    admin_name = ENV.fetch("ADMIN_REVIEW_NAME", DEFAULT_ADMIN_NAME)

    temple = Temple.find_or_initialize_by(slug: temple_slug)
    temple.name = temple_name if temple.name.blank?
    temple.published = true if temple.respond_to?(:published=)
    temple.metadata = (temple.metadata || {}).merge(seed_metadata)
    temple.save!

    user = User.find_or_initialize_by(email:)
    user.english_name = admin_name
    user.encrypted_password = User.password_hash(password)
    user.account_status = "active" if user.respond_to?(:account_status=)
    user.closed_at = nil if user.respond_to?(:closed_at=)
    user.closure_reason = nil if user.respond_to?(:closure_reason=)
    user.metadata = (user.metadata || {}).merge(seed_metadata)
    user.save!

    admin = AdminAccount.find_or_initialize_by(user:)
    admin.role = :owner
    admin.active = true
    admin.metadata = (admin.metadata || {}).merge(seed_metadata)
    admin.save!

    membership = AdminTempleMembership.find_or_initialize_by(admin_account: admin, temple:)
    membership.role = :owner
    membership.metadata = (membership.metadata || {}).merge(seed_metadata) if membership.respond_to?(:metadata=)
    membership.save!

    permission = AdminPermission.find_or_initialize_by(admin_account: admin, temple:)
    AdminPermission::CAPABILITIES.each do |capability|
      permission[capability] = true if permission.respond_to?("#{capability}=")
    end
    permission.metadata = (permission.metadata || {}).merge(seed_metadata) if permission.respond_to?(:metadata=)
    permission.save!

    {
      email: user.email,
      password_matches: user.encrypted_password == User.password_hash(password),
      admin_active: admin.active?,
      admin_role: admin.role,
      temple_slug: temple.slug
    }
  end
end

namespace :admin_review do
  desc "Prepare local admin browser-review account in an isolated development database"
  task prepare: :environment do
    result = AdminReviewTasks.create_or_update_reviewer!

    puts "Admin review account ready:" # rubocop:disable Rails/Output
    puts "  email: #{result.fetch(:email)}" # rubocop:disable Rails/Output
    puts "  password_matches: #{result.fetch(:password_matches)}" # rubocop:disable Rails/Output
    puts "  admin_active: #{result.fetch(:admin_active)}" # rubocop:disable Rails/Output
    puts "  admin_role: #{result.fetch(:admin_role)}" # rubocop:disable Rails/Output
    puts "  temple: #{result.fetch(:temple_slug)}" # rubocop:disable Rails/Output
  end
end
