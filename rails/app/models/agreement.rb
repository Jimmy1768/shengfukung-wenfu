class Agreement < ApplicationRecord
  has_many :agreement_acceptances, dependent: :destroy

  validates :key, :version, :title, :body, :effective_on, presence: true
end
