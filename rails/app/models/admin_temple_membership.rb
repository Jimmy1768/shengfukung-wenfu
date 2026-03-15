# frozen_string_literal: true

class AdminTempleMembership < ApplicationRecord
  belongs_to :admin_account
  belongs_to :temple

  enum role: {
    admin: "admin",
    owner: "owner",
  }, _suffix: true

  validates :admin_account_id, uniqueness: { scope: :temple_id }
end
