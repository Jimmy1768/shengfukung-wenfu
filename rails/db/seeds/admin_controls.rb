# frozen_string_literal: true

require "securerandom"

require Rails.root.join("app", "lib", "app_constants", "project").to_s

module Seeds
  module AdminControls
    extend self

    DEFAULT_EMAIL = ENV.fetch("PROJECT_DEFAULT_ADMIN_EMAIL") do
      "admin@#{AppConstants::Project.slug}.local"
    end.freeze

    DEFAULT_PASSWORD = ENV.fetch("PROJECT_DEFAULT_ADMIN_PASSWORD", "GoldenTemplate!123")
    DEFAULT_ADMIN_NAME = ENV.fetch("PROJECT_DEFAULT_ADMIN_NAME", "#{AppConstants::Project.name} Admin")

    def seed
      puts "Seeding admin controls..." # rubocop:disable Rails/Output
      admin_user = ensure_admin_user
      admin_record = ensure_admin_record(admin_user)
      ensure_temple_membership(admin_record)
      ensure_dev_token(admin_record)
      puts "Admin controls seeded (#{admin_user.email})." # rubocop:disable Rails/Output
    end

    private

    def ensure_admin_user
      User.find_or_initialize_by(email: DEFAULT_EMAIL).tap do |user|
        user.assign_attributes(
          english_name: DEFAULT_ADMIN_NAME,
          encrypted_password: User.password_hash(DEFAULT_PASSWORD),
          metadata: (user.metadata || {}).merge(seed_metadata)
        )
        user.save! if user.changed?
      end
    end

    def ensure_admin_record(user)
      AdminAccount.find_or_initialize_by(user: user).tap do |admin|
        admin.assign_attributes(
          role: "owner",
          access_level: 10,
          active: true,
          metadata: (admin.metadata || {}).merge(seed_metadata)
        )
        admin.save! if admin.changed?
      end
    end

    def ensure_temple_membership(admin)
      Temple.find_each do |temple|
        AdminTempleMembership.find_or_create_by!(
          admin_account: admin,
          temple:
        ) do |membership|
          membership.role = admin.role
        end
      end
    end

    def ensure_dev_token(admin)
      DevModeToken.find_or_initialize_by(admin_account: admin, purpose: "default-guest").tap do |token|
        token.assign_attributes(
          token: SecureRandom.urlsafe_base64(30),
          expires_at: 30.days.from_now,
          metadata: seed_metadata
        )
        token.save! if token.changed?
      end
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:admin_controls"
      }
    end
  end
end
