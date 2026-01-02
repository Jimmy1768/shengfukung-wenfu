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

  enum role: {
    staff: "staff",
    owner: "owner"
  }, _suffix: true

  scope :active, -> { where(active: true) }

  def self.seeded_metadata
    {
      seeded_at: Time.current.iso8601,
      seeded_by: "db:seed:admin_controls"
    }
  end
end
