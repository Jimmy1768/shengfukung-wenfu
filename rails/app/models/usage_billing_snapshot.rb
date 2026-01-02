class UsageBillingSnapshot < ApplicationRecord
  belongs_to :user, optional: true

  validates :usage_type, :bucket_date, presence: true
end
