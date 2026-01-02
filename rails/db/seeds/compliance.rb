# frozen_string_literal: true

require Rails.root.join("app", "lib", "app_constants", "project").to_s

module Seeds
  module Compliance
    extend self

    def seed
      puts "Seeding compliance data..." # rubocop:disable Rails/Output
      user = seed_user
      seed_data_anomaly(user)
      agreement = seed_agreement
      seed_agreement_acceptance(agreement, user)
    end

    private

    def seed_user
      User.find_or_create_by!(email: "compliance@#{AppConstants::Project.slug}.local") do |user|
        user.english_name = "Compliance Seed"
        user.encrypted_password = User.password_hash("ComplianceSeed!2025")
        user.metadata = seed_metadata
      end
    end

    def seed_data_anomaly(user)
      DataAnomaly.find_or_initialize_by(detector_key: "seed:consistency-check").tap do |anomaly|
        anomaly.record = user
        anomaly.severity = "critical"
        anomaly.status = "open"
        anomaly.detected_at = Time.current
        anomaly.details = { field: "email", anomaly: "missing verification" }
        anomaly.metadata = seed_metadata
        anomaly.save! if anomaly.changed?
      end
    end

    def seed_agreement
      Agreement.find_or_initialize_by(key: "terms_of_service", version: 1).tap do |agreement|
        agreement.title = "Terms of Service"
        agreement.body = "Seeded agreement body for compliance checks."
        agreement.effective_on = Date.current
        agreement.metadata = seed_metadata
        agreement.save! if agreement.changed?
      end
    end

    def seed_agreement_acceptance(agreement, user)
      AgreementAcceptance.find_or_initialize_by(agreement: agreement, user: user).tap do |acceptance|
        acceptance.accepted_at = Time.current
        acceptance.body_snapshot = agreement.body
        acceptance.ip_address = "127.0.0.1"
        acceptance.user_agent = "SeedAgent/1.0"
        acceptance.metadata = seed_metadata
        acceptance.save! if acceptance.changed?
      end
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:compliance"
      }
    end
  end
end
