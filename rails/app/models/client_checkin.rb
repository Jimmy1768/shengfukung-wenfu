# frozen_string_literal: true

class ClientCheckin < ApplicationRecord
  belongs_to :user, optional: true
end
