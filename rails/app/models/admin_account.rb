# frozen_string_literal: true

class AdminAccount < ApplicationRecord
  self.table_name = "admins"

  belongs_to :user, inverse_of: :admin_account
  has_many :dev_mode_tokens,
    dependent: :destroy,
    foreign_key: :admin_id,
    inverse_of: :admin_account
  has_many :admin_temple_memberships,
    dependent: :destroy
  has_many :temples,
    through: :admin_temple_memberships
  has_many :admin_permissions,
    dependent: :destroy
  has_many :closed_temple_assistance_requests,
    class_name: "TempleAssistanceRequest",
    foreign_key: :closed_by_admin_id,
    dependent: :nullify
  has_many :temple_payments,
    dependent: :nullify

  enum role: {
    staff: "staff",
    owner: "owner",
    support: "support"
  }, _suffix: true

  scope :active, -> { where(active: true) }

  def self.seeded_metadata
    {
      seeded_at: Time.current.iso8601,
      seeded_by: "db:seed:admin_controls"
    }
  end

  def permissions_for(temple)
    admin_permissions.find_by(temple:) || default_permissions_for(temple)
  end

  private

  def default_permissions_for(temple)
    record = admin_permissions.build(temple:)
    if owner_role? || support_role?
      AdminPermission::CAPABILITIES.each do |capability|
        record[capability] = true if record.respond_to?(capability)
      end
    end
    record
  end
end
