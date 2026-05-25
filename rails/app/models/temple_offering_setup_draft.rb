# frozen_string_literal: true

require "yaml"

class TempleOfferingSetupDraft < ApplicationRecord
  STATUSES = %w[draft submitted reviewed applied].freeze
  OFFERING_KINDS = %w[event service].freeze

  belongs_to :temple
  belongs_to :created_by_admin, class_name: "AdminAccount", optional: true
  belongs_to :reviewed_by_admin, class_name: "AdminAccount", optional: true
  belongs_to :applied_by_admin, class_name: "AdminAccount", optional: true

  validates :status, inclusion: { in: STATUSES }
  validates :offering_kind, inclusion: { in: OFFERING_KINDS }
  validates :slug, :label, :currency, presence: true
  validates :slug, uniqueness: { scope: :temple_id }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  before_validation :normalize_slug
  before_validation :refresh_generated_template

  scope :recent_first, -> { order(updated_at: :desc) }

  def submit!(admin)
    update!(
      status: "submitted",
      submitted_at: Time.current,
      generated_template: build_generated_template
    )
  end

  def review!(admin, notes:)
    update!(
      status: "reviewed",
      reviewed_by_admin: admin.admin_account,
      review_notes: notes,
      reviewed_at: Time.current,
      generated_template: build_generated_template
    )
  end

  def apply!(admin)
    update!(
      status: "applied",
      applied_by_admin: admin.admin_account,
      applied_at: Time.current,
      generated_template: build_generated_template
    )
  end

  def editable?
    status == "draft"
  end

  def generated_template_yaml
    YAML.dump(generated_template.deep_stringify_keys)
  end

  def build_generated_template
    payload = setup_payload.with_indifferent_access
    {
      slug: slug,
      kind: offering_kind,
      label: label,
      registration_period_key: registration_period_key.presence,
      attributes: {
        title: label,
        price_cents: price_cents,
        currency: currency,
        status: "draft"
      }.compact,
      defaults: {
        offering_type: payload[:category].presence || offering_kind,
        operational_notes: payload[:operational_notes].presence
      }.compact,
      form_fields: Array(payload[:field_requirements]).compact_blank,
      options: Array(payload[:options]).compact_blank,
      ui: {
        generated_from: "admin_offering_setup_draft",
        draft_id: id
      }.compact
    }.compact
  end

  private

  def normalize_slug
    self.slug = slug.to_s.parameterize if slug.present?
  end

  def refresh_generated_template
    self.generated_template = build_generated_template
  end
end
