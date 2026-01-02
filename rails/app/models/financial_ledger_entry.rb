class FinancialLedgerEntry < ApplicationRecord
  belongs_to :user, optional: true

  validates :entry_type, :currency, :country_code, :entry_date, presence: true
  validates :amount, numericality: true
  validates :tax_amount, numericality: true
end
