# frozen_string_literal: true

class DevModeToken < ApplicationRecord
  belongs_to :admin_account,
    class_name: "AdminAccount",
    foreign_key: :admin_id,
    inverse_of: :dev_mode_tokens

  alias_method :admin, :admin_account
  alias_method :admin=, :admin_account=

  validates :token, presence: true, uniqueness: true

  def active?
    expires_at.nil? || expires_at.future?
  end
end
