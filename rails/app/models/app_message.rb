# frozen_string_literal: true

class AppMessage < ApplicationRecord
  validates :key, :channel, :locale, presence: true
end
