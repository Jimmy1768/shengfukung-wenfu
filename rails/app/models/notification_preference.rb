# frozen_string_literal: true

class NotificationPreference < ApplicationRecord
  belongs_to :user

  validates :channel, presence: true
end
