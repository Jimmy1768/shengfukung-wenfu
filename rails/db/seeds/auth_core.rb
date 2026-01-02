# frozen_string_literal: true

module Seeds
  module AuthCore
    extend self

    PRIMARY_EMAIL = ENV.fetch("PROJECT_PRIMARY_USER_EMAIL") do
      "demo@#{AppConstants::Project.slug}.local"
    end.freeze
    SECONDARY_EMAIL = ENV.fetch("PROJECT_SECONDARY_USER_EMAIL") do
      "guest@#{AppConstants::Project.slug}.local"
    end.freeze
    DEFAULT_PASSWORD = ENV.fetch("PROJECT_PRIMARY_USER_PASSWORD", "DemoPassword!23")

    SAMPLE_USERS = [
      {
        email: PRIMARY_EMAIL,
        english_name: "Demo Client",
        metadata: { demo_user: true }
      },
      {
        email: SECONDARY_EMAIL,
        english_name: "Guest Operator",
        metadata: { demo_user: true, guest: true }
      }
    ].freeze

    DEPENDENT_ATTRIBUTES = {
      english_name: "Demo Dependent",
      native_name: "Demo Dependent",
      relationship_label: "Spouse",
      metadata: { seeded_by: "Seeds::AuthCore" }
    }.freeze

    def seed
      puts "Seeding auth core data..." # rubocop:disable Rails/Output
      SAMPLE_USERS.each do |attributes|
        ensure_user(attributes)
      end
      attach_dependent!
    end

    private

    def ensure_user(attributes)
      User.find_or_initialize_by(email: attributes[:email]).tap do |user|
        user.assign_attributes(
          english_name: attributes[:english_name],
          encrypted_password: User.password_hash(DEFAULT_PASSWORD),
          metadata: (user.metadata || {}).merge(attributes[:metadata] || {}).merge(seed_metadata)
        )
        user.save! if user.changed?
      end
    end

    def attach_dependent!
      primary_user = User.find_by(email: PRIMARY_EMAIL)
      return unless primary_user

      dependent = Dependent.find_or_initialize_by(english_name: DEPENDENT_ATTRIBUTES[:english_name]).tap do |dep|
        dep.assign_attributes(
          native_name: DEPENDENT_ATTRIBUTES[:native_name],
          relationship_label: DEPENDENT_ATTRIBUTES[:relationship_label],
          metadata: (dep.metadata || {}).merge(DEPENDENT_ATTRIBUTES[:metadata] || {})
        )
        dep.save! if dep.changed?
      end

      UserDependent.find_or_initialize_by(user: primary_user, dependent: dependent).tap do |link|
        link.assign_attributes(
          role: "caretaker",
          metadata: seed_metadata
        )
        link.save! if link.changed?
      end
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:auth_core"
      }
    end
  end
end
