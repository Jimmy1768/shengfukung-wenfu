# frozen_string_literal: true

class PaymentWebhookLog < ApplicationRecord
  belongs_to :temple

  validates :provider, :event_type, :provider_reference, presence: true

  scope :pending, -> { where(processed: false) }
end
