# frozen_string_literal: true

require "digest"
require "json"

module Privacy
  class UserDataExportFulfillment
    def self.fulfill!(privacy_request:, operator:)
      new(privacy_request:, operator:).fulfill!
    end

    def initialize(privacy_request:, operator:)
      @privacy_request = privacy_request
      @user = privacy_request.user
      @operator = operator
    end

    def fulfill!
      raise ArgumentError, "privacy request must be data_export" unless @privacy_request.request_type == "data_export"

      payload_hash = export_payload_hash
      payload_json = JSON.pretty_generate(payload_hash)
      now = Time.current

      DataExportJob.transaction do
        job = DataExportJob.create!(
          export_key: "privacy.user_data",
          status: "succeeded",
          destination: "inline",
          started_at: now,
          finished_at: now,
          filters: {},
          metadata: {
            "user_id" => @user.id,
            "privacy_request_id" => @privacy_request.id,
            "operator_user_id" => @operator.id
          }
        )

        export_payload = job.data_export_payloads.create!(
          storage_location: "inline://privacy_requests/#{@privacy_request.id}",
          checksum: Digest::SHA256.hexdigest(payload_json),
          bytes: payload_json.bytesize,
          record_count: record_count_for(payload_hash),
          available_at: now,
          metadata: {
            "payload" => payload_hash
          }
        )

        @privacy_request.update!(
          metadata: (@privacy_request.metadata || {}).merge(
            "data_export_job_id" => job.id,
            "data_export_payload_id" => export_payload.id,
            "export_available_at" => now.iso8601
          )
        )

        export_payload
      end
    end

    private

    def export_payload_hash
      {
        exported_at: Time.current.iso8601,
        user: user_payload,
        preferences: preference_payload,
        privacy_settings: privacy_settings_payload,
        oauth_identities: oauth_identity_payloads,
        dependents: dependent_payloads,
        registrations: registration_payloads,
        payments: payment_payloads,
        privacy_requests: privacy_request_payloads,
        account_lifecycle_events: lifecycle_event_payloads
      }
    end

    def user_payload
      {
        id: @user.id,
        email: @user.email,
        native_name: @user.native_name,
        english_name: @user.english_name,
        account_status: @user.account_status,
        closed_at: @user.closed_at&.iso8601,
        closure_reason: @user.closure_reason,
        created_at: @user.created_at.iso8601,
        updated_at: @user.updated_at.iso8601,
        metadata: @user.metadata || {}
      }
    end

    def preference_payload
      preference = @user.user_preference
      return {} unless preference

      {
        locale: preference.locale,
        timezone: preference.timezone,
        currency: preference.currency,
        theme: preference.theme,
        temperature_unit: preference.temperature_unit,
        measurement_system: preference.measurement_system,
        twenty_four_hour_time: preference.twenty_four_hour_time,
        metadata: preference.metadata || {}
      }
    end

    def privacy_settings_payload
      settings = @user.privacy_setting
      return {} unless settings

      {
        share_data_with_partners: settings.share_data_with_partners,
        third_party_tracking_enabled: settings.third_party_tracking_enabled,
        email_tracking_opt_in: settings.email_tracking_opt_in,
        metadata: settings.metadata || {}
      }
    end

    def oauth_identity_payloads
      @user.oauth_identities.order(:provider, :created_at).map do |identity|
        {
          provider: identity.provider,
          provider_uid: identity.provider_uid,
          email: identity.email,
          email_verified: identity.email_verified,
          linked_at: identity.linked_at&.iso8601,
          last_login_at: identity.last_login_at&.iso8601,
          metadata: identity.metadata || {}
        }
      end
    end

    def dependent_payloads
      @user.user_dependents.includes(:dependent).map do |link|
        dependent = link.dependent
        {
          link_id: link.id,
          role: link.role,
          relationship_label: link.relationship_label,
          link_metadata: link.metadata || {},
          dependent: {
            id: dependent.id,
            native_name: dependent.native_name,
            english_name: dependent.english_name,
            birthdate: dependent.birthdate&.iso8601,
            relationship_label: dependent.relationship_label,
            metadata: dependent.metadata || {}
          }
        }
      end
    end

    def registration_payloads
      @user.temple_event_registrations.includes(:temple, :registrable).order(created_at: :desc).map do |registration|
        {
          id: registration.id,
          reference_code: registration.reference_code,
          temple_slug: registration.temple&.slug,
          temple_name: registration.temple&.name,
          offering_type: registration.registrable_type,
          offering_id: registration.registrable_id,
          offering_title: registration.registrable&.respond_to?(:title) ? registration.registrable.title : nil,
          quantity: registration.quantity,
          unit_price_cents: registration.unit_price_cents,
          total_price_cents: registration.total_price_cents,
          currency: registration.currency,
          payment_status: registration.payment_status,
          fulfillment_status: registration.fulfillment_status,
          contact_payload: registration.contact_payload || {},
          logistics_payload: registration.logistics_payload || {},
          metadata: registration.metadata || {},
          created_at: registration.created_at.iso8601,
          updated_at: registration.updated_at.iso8601
        }
      end
    end

    def payment_payloads
      @user.temple_payments.includes(:temple, :temple_registration).order(created_at: :desc).map do |payment|
        {
          id: payment.id,
          temple_slug: payment.temple&.slug,
          temple_name: payment.temple&.name,
          registration_reference: payment.temple_registration&.reference_code,
          amount_cents: payment.amount_cents,
          currency: payment.currency,
          payment_method: payment.payment_method,
          status: payment.status,
          provider: payment.provider,
          external_reference: payment.external_reference,
          processed_at: payment.processed_at&.iso8601,
          metadata: payment.metadata || {},
          created_at: payment.created_at.iso8601
        }
      end
    end

    def privacy_request_payloads
      @user.privacy_requests.order(requested_at: :desc, created_at: :desc).map do |request|
        {
          id: request.id,
          request_type: request.request_type,
          status: request.status,
          submitted_via: request.submitted_via,
          requested_at: request.requested_at&.iso8601,
          resolved_at: request.resolved_at&.iso8601,
          notes: request.notes,
          metadata: request.metadata || {}
        }
      end
    end

    def lifecycle_event_payloads
      @user.account_lifecycle_events.order(occurred_at: :desc, created_at: :desc).map do |event|
        {
          id: event.id,
          event_type: event.event_type,
          occurred_at: event.occurred_at&.iso8601,
          details: event.details || {},
          metadata: event.metadata || {}
        }
      end
    end

    def record_count_for(payload_hash)
      %i[oauth_identities dependents registrations payments privacy_requests account_lifecycle_events].sum do |key|
        Array(payload_hash[key]).size
      end + 3
    end
  end
end
