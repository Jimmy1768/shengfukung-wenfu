class AgreementAcceptance < ApplicationRecord
  belongs_to :agreement
  belongs_to :user

  validates :accepted_at, :body_snapshot, presence: true
end
