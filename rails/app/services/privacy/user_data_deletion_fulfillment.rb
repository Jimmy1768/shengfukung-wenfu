# frozen_string_literal: true

require "securerandom"

module Privacy
  class UserDataDeletionFulfillment
    REDACTED_DOMAIN = "redacted.local"

    def self.fulfill!(privacy_request:, operator:)
      new(privacy_request:, operator:).fulfill!
    end

    def initialize(privacy_request:, operator:)
      @privacy_request = privacy_request
      @user = privacy_request.user
      @operator = operator
    end

    def fulfill!
      raise ArgumentError, "privacy request must be data_deletion" unless @privacy_request.request_type == "data_deletion"

      @user.transaction do
        @user.close_account!(reason: "privacy_request", closed_by: @operator) unless @user.closed_account?

        anonymize_user!
        anonymize_dependents!
        revoke_identities!
        scrub_preferences!
        scrub_privacy_settings!

        @user.account_lifecycle_events.create!(
          event_type: "account_anonymized",
          occurred_at: Time.current,
          user_name_snapshot: redacted_native_name,
          metadata: {
            "privacy_request_id" => @privacy_request.id,
            "operator_user_id" => @operator.id
          }
        )

        @privacy_request.update!(
          metadata: (@privacy_request.metadata || {}).merge(
            "anonymized_at" => Time.current.iso8601,
            "anonymized_user_id" => @user.id
          )
        )
      end
    end

    private

    def anonymize_user!
      @user.update!(
        email: redacted_email,
        native_name: redacted_native_name,
        english_name: redacted_english_name,
        encrypted_password: User.password_hash(SecureRandom.hex(32)),
        anonymized_at: Time.current,
        metadata: (@user.metadata || {}).merge(
          "anonymized_at" => Time.current.iso8601,
          "anonymized_by_user_id" => @operator.id,
          "anonymized_via" => "privacy_request"
        )
      )
    end

    def anonymize_dependents!
      @user.user_dependents.includes(:dependent).find_each do |link|
        dependent = link.dependent
        if dependent.users.where.not(id: @user.id).exists?
          link.destroy!
          next
        end

        dependent.update!(
          native_name: redacted_native_name,
          english_name: redacted_english_name,
          birthdate: nil,
          relationship_label: nil,
          metadata: (dependent.metadata || {}).merge(
            "anonymized_at" => Time.current.iso8601,
            "anonymized_by_user_id" => @operator.id
          )
        )
      end
    end

    def revoke_identities!
      @user.oauth_identities.destroy_all
    end

    def scrub_preferences!
      preference = @user.user_preference
      return unless preference

      preference.update!(metadata: {})
    end

    def scrub_privacy_settings!
      settings = @user.privacy_setting
      return unless settings

      settings.update!(
        share_data_with_partners: false,
        third_party_tracking_enabled: false,
        email_tracking_opt_in: false,
        metadata: {}
      )
    end

    def redacted_email
      "deleted-user-#{@user.id}@#{REDACTED_DOMAIN}"
    end

    def redacted_native_name
      "已刪除使用者"
    end

    def redacted_english_name
      "Deleted User"
    end
  end
end
