# frozen_string_literal: true

class UserDependent < ApplicationRecord
  belongs_to :user
  belongs_to :dependent

  validates :role, presence: true
end
