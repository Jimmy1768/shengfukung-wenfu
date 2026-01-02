# frozen_string_literal: true

class Temple < ApplicationRecord
  has_many :temple_pages,
    inverse_of: :temple,
    dependent: :destroy
  has_many :temple_sections,
    through: :temple_pages
  has_many :media_assets,
    dependent: :destroy
  has_many :admin_temple_memberships,
    dependent: :destroy
  has_many :admin_accounts,
    through: :admin_temple_memberships
  has_many :system_audit_logs,
    dependent: :nullify

  scope :published, -> { where(published: true) }
  scope :for_admin, lambda { |admin_account|
    joins(:admin_temple_memberships).where(admin_temple_memberships: { admin_account_id: admin_account.id })
  }

  validates :slug, :name, presence: true

  def contact_details
    contact_info.presence || {}
  end

  def service_schedule
    service_times.presence || {}
  end
end
