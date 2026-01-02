class MessageDeliveryArchive < ApplicationRecord
  belongs_to :user, optional: true

  validates :channel, :recipient, presence: true
end
