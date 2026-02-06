# frozen_string_literal: true

class AdminTempleMembership < ApplicationRecord
  belongs_to :admin_account
  belongs_to :temple

  enum role: {
    staff: "staff",
    owner: "owner",
    support: "support"
  }, _suffix: true

  validates :admin_account_id, uniqueness: { scope: :temple_id }
end
