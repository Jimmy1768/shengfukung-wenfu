# frozen_string_literal: true

module Offerings
  class SetupDraftApplier
    Result = Struct.new(:success?, :target, :errors, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(draft:, admin:)
      @draft = draft
      @admin = admin
      @errors = []
    end

    def call
      return Result.new(success?: true, target: draft.applied_offering, errors: []) if idempotent_applied?

      validate
      return failure if errors.any?

      target = upsert_target!
      draft.update!(
        status: "applied",
        applied_by_admin: admin.admin_account,
        applied_at: Time.current,
        applied_offering: target,
        generated_template: draft.build_generated_template
      )

      Result.new(success?: true, target: target, errors: [])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, target: nil, errors: e.record.errors.full_messages)
    end

    private

    attr_reader :draft, :admin, :errors

    def failure
      Result.new(success?: false, target: nil, errors: errors)
    end

    def validate
      errors << I18n.t("admin.offering_setup_drafts.apply_errors.not_reviewed") unless draft.status == "reviewed"
      errors << I18n.t("admin.offering_setup_drafts.apply_errors.events_blocked") if draft.offering_kind == "event"
      validate_admin_fields
      validate_options
      validate_registration_fields
      validate_slug_collision
    end

    def idempotent_applied?
      draft.status == "applied" && draft.applied_offering.present?
    end

    def validate_admin_fields
      unsupported = admin_fields.reject { |field| SetupFieldCatalog.supported?(field) }
      return if unsupported.empty?

      errors << I18n.t("admin.offering_setup_drafts.apply_errors.unsupported_fields", fields: unsupported.join(", "))
    end

    def validate_options
      option_map.each_key do |field|
        next if SetupFieldCatalog.option_bearing?(field)

        errors << I18n.t("admin.offering_setup_drafts.apply_errors.unsupported_option_field", field: field)
      end
    end

    def validate_registration_fields
      unsupported = unsupported_registration_fields
      return if unsupported.empty?

      errors << I18n.t("admin.offering_setup_drafts.apply_errors.unsupported_registration_fields", fields: unsupported.join(", "))
    end

    def validate_slug_collision
      return unless draft.offering_kind == "service"

      existing = draft.temple.temple_services.find_by(slug: draft.slug)
      return if existing.blank?
      return if draft.applied_offering == existing

      errors << I18n.t("admin.offering_setup_drafts.apply_errors.slug_collision", slug: draft.slug)
    end

    def upsert_target!
      target = linked_target || draft.temple.temple_services.new(slug: draft.slug)
      target.assign_attributes(service_attributes)
      target.save!
      target
    end

    def linked_target
      return unless draft.applied_offering.is_a?(TempleService)
      return unless draft.applied_offering.status == "draft"

      draft.applied_offering
    end

    def service_attributes
      {
        slug: draft.slug,
        title: draft.label,
        description: operational_notes,
        price_cents: draft.price_cents,
        currency: draft.currency,
        status: "draft",
        registration_period_key: draft.registration_period_key,
        period_label: draft.registration_period_key.present? ? draft.temple.registration_period_label_for(draft.registration_period_key) : nil,
        metadata: service_metadata
      }
    end

    def service_metadata
      {
        "offering_type" => category,
        "form_fields" => form_fields,
        "form_defaults" => form_defaults,
        "form_options" => option_map,
        "form_ui" => form_ui,
        "form_label" => draft.label,
        "registration_form" => registration_form,
        "allow_repeat_registrations" => true,
        "generated_from_setup_draft_id" => draft.id
      }
    end

    def form_fields
      fields = admin_fields - %w[offering_type price_cents currency description]
      {
        "basics" => {
          "title" => I18n.t("admin.offering_setup_drafts.generated.basics_title"),
          "fields" => %w[offering_type price_cents currency description]
        },
        "setup" => {
          "title" => I18n.t("admin.offering_setup_drafts.generated.setup_title"),
          "fields" => fields
        }
      }.reject { |_section, config| config["fields"].empty? }
    end

    def form_defaults
      {
        "offering_type" => category,
        "currency" => draft.currency,
        "operational_notes" => operational_notes
      }.compact
    end

    def form_ui
      {
        "generated_from" => "admin_offering_setup_draft",
        "setup_draft_id" => draft.id,
        "lock_registration_period_key" => draft.registration_period_key.present?
      }
    end

    def registration_form
      {
        "sections" => registration_sections,
        "defaults" => {
          "order" => { "quantity" => 1 }
        }
      }
    end

    def admin_fields
      @admin_fields ||= Array(payload["field_requirements"]).map { |field| field.to_s.strip }.reject(&:blank?)
    end

    def option_map
      @option_map ||= Array(payload["options"]).each_with_object({}) do |option, memo|
        field = option["field"].to_s.strip
        next if field.blank?

        memo[field] ||= []
        memo[field] << (option["value"].presence || option["label"])
      end
    end

    def registration_sections
      registration_fields.each_with_object({}) do |(section, fields), memo|
        memo[section] = fields.any? ? { "fields" => fields } : false
      end
    end

    def registration_fields
      @registration_fields ||= begin
        raw = payload["registration_fields"]
        selected_fields =
          if raw.present? && raw.respond_to?(:to_h)
            raw.to_h.with_indifferent_access
          else
            SetupFieldCatalog.default_registration_fields
          end

        SetupFieldCatalog.registration_sections.each_with_object({}) do |section, memo|
          memo[section] = Array(selected_fields[section]).map { |field| field.to_s.strip }.reject(&:blank?).uniq
        end
      end
    end

    def unsupported_registration_fields
      raw = payload["registration_fields"]
      return [] if raw.blank?
      return [] unless raw.respond_to?(:to_h)

      raw.to_h.each_with_object([]) do |(section, fields), memo|
        Array(fields).each do |field|
          field = field.to_s.strip
          next if field.blank?
          next if SetupFieldCatalog.registration_field_supported?(section, field)

          memo << "#{section}.#{field}"
        end
      end
    end

    def category
      payload["category"].presence || draft.offering_kind
    end

    def operational_notes
      payload["operational_notes"].presence
    end

    def payload
      @payload ||= draft.setup_payload.with_indifferent_access
    end
  end
end
