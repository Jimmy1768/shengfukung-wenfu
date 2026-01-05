# frozen_string_literal: true

class AdminPermission < ApplicationRecord
  belongs_to :admin_account, class_name: "AdminAccount", foreign_key: :admin_account_id
  belongs_to :temple

  CAPABILITIES = %i[
    manage_offerings
    manage_registrations
    record_cash_payments
    view_financials
    export_financials
    view_guest_lists
    manage_permissions
  ].freeze

  validates :admin_account_id, uniqueness: { scope: :temple_id }

  def allow?(capability)
    respond_to?(capability) && public_send(capability)
  end
end
