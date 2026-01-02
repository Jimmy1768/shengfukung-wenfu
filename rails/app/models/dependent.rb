# frozen_string_literal: true

class Dependent < ApplicationRecord
  has_many :user_dependents, dependent: :destroy
  has_many :users, through: :user_dependents

  validates :english_name, presence: true
end
