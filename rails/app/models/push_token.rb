# frozen_string_literal: true

class PushToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: { scope: %i[user platform] }
end
