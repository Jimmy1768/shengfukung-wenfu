# frozen_string_literal: true

module AdminControlsTasks
  module_function

  def default_admin_email(slug)
    "admin@#{slug}.local"
  end

  def seed_metadata(source)
    {
      provisioned_by: source,
      provisioned_at: Time.current.iso8601
    }
  end
end

namespace :admin_controls do
  desc "Dev helper: create/update an owner admin (User + AdminAccount + membership)"
  task :seed_owner, [:slug, :email, :password, :name] => :environment do |_task, args|
    slug = args[:slug] || AppConstants::Project.slug
    email = args[:email] || AdminControlsTasks.default_admin_email(slug)
    password = args[:password] || ENV.fetch("PROJECT_DEFAULT_ADMIN_PASSWORD", "GoldenTemplate!123")
    english_name = args[:name] || "#{slug.titleize} Owner Admin"

    temple = Temple.find_by!(slug:)
    user = User.find_or_initialize_by(email: email.downcase)
    user.english_name = english_name if user.english_name.blank?
    user.encrypted_password = User.password_hash(password)
    user.metadata = (user.metadata || {}).merge(AdminControlsTasks.seed_metadata("admin_controls:seed_owner"))
    user.save!

    admin = AdminAccount.find_or_initialize_by(user:)
    admin.role = :owner
    admin.active = true
    admin.metadata = (admin.metadata || {}).merge(AdminControlsTasks.seed_metadata("admin_controls:seed_owner"))
    admin.save!

    AdminTempleMembership.find_or_create_by!(admin_account: admin, temple:) do |membership|
      membership.role = :owner
    end

    puts "Owner admin ready for #{slug} (#{email})." # rubocop:disable Rails/Output
  end

  desc "Promote an existing user (by email) to owner admin for a temple"
  task :promote_owner, [:slug, :email] => :environment do |_task, args|
    slug = args[:slug] || AppConstants::Project.slug
    email = args[:email]
    raise ArgumentError, "email is required" if email.blank?

    temple = Temple.find_by!(slug:)
    user = User.find_by!(email: email.downcase)

    admin = AdminAccount.find_or_initialize_by(user:)
    admin.role = :owner
    admin.active = true
    admin.metadata = (admin.metadata || {}).merge(AdminControlsTasks.seed_metadata("admin_controls:promote_owner"))
    admin.save!

    AdminTempleMembership.find_or_create_by!(admin_account: admin, temple:) do |membership|
      membership.role = :owner
    end

    puts "User #{email} is now an owner admin for #{slug}." # rubocop:disable Rails/Output
  end
end
