# frozen_string_literal: true

require "securerandom"

require Rails.root.join("app", "lib", "app_constants", "project").to_s

module Seeds
  module AdminControls
    extend self

    OWNER_EMAIL = Seeds::AuthCore::OWNER_EMAIL
    STAFF_ADMIN_EMAIL = Seeds::AuthCore::STAFF_ADMIN_EMAIL
    DEV_EMAIL = Seeds::AuthCore::DEV_SUPPORT_EMAIL
    PATRON_EMAIL = Seeds::AuthCore::PATRON_EMAIL
    DEFAULT_PASSWORD = Seeds::AuthCore::DEFAULT_PASSWORD

    def seed
      puts "Seeding admin controls..." # rubocop:disable Rails/Output
      owner_user = ensure_seed_user(email: OWNER_EMAIL, name: "Owner Admin")
      staff_user = ensure_seed_user(email: STAFF_ADMIN_EMAIL, name: "Staff Admin")
      patron_user = ensure_seed_user(email: PATRON_EMAIL, name: "Patron Tester")
      dev_user = ensure_seed_user(email: DEV_EMAIL, name: "Dev Support")

      ensure_patron_profile(patron_user, role: "patron")
      ensure_patron_profile(staff_user, role: "staff_admin")

      owner_account = ensure_admin_account(owner_user, role: "owner", access_level: 10, metadata: { seed_role: "owner" })
      ensure_temple_memberships(owner_account)

      staff_account = ensure_admin_account(staff_user, role: "staff", access_level: 7, metadata: { seed_role: "staff_admin", promoted_from_patron: true })
      ensure_temple_memberships(staff_account)

      dev_account = ensure_admin_account(dev_user, role: "support", access_level: 9, metadata: { seed_role: "dev_support", dev_support: true })
      ensure_temple_memberships(dev_account)
      ensure_dev_token(dev_account)

      puts "Owner/admin/dev accounts seeded." # rubocop:disable Rails/Output
    end

    private

    def ensure_seed_user(email:, name:, metadata: {})
      User.find_or_initialize_by(email:).tap do |user|
        user.assign_attributes(
          english_name: name,
          encrypted_password: User.password_hash(DEFAULT_PASSWORD),
          metadata: (user.metadata || {}).merge(seed_metadata).merge(metadata)
        )
        user.save! if user.changed?
      end
    end

    def ensure_admin_account(user, role:, access_level:, metadata: {})
      AdminAccount.find_or_initialize_by(user:).tap do |admin|
        admin.assign_attributes(
          role:,
          access_level:,
          active: true,
          metadata: (admin.metadata || {}).merge(seed_metadata).merge(metadata)
        )
        admin.save! if admin.changed?
      end
    end

    def ensure_temple_memberships(admin)
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
      DevModeToken.find_or_initialize_by(admin_account: admin, purpose: "dev-support").tap do |token|
        token.assign_attributes(
          token: SecureRandom.urlsafe_base64(30),
          expires_at: 30.days.from_now,
          metadata: seed_metadata.merge("dev_support" => true)
        )
        token.save! if token.changed?
      end
    end

    def ensure_patron_profile(user, role:)
      profile = {
        "phone" => user.metadata&.dig("phone") || "02-1234-5678",
        "temple_profile" => {
          "preferred_language" => "zh-TW",
          "preferred_branch" => "本殿",
          "seed_role" => role
        }
      }
      user.metadata = (user.metadata || {}).merge(profile).merge(seed_metadata)
      user.save! if user.changed?
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:admin_controls"
      }
    end
  end
end
