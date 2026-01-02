class AccountLifecycleEvent < ApplicationRecord
  belongs_to :user

  validates :event_type, :occurred_at, presence: true
end
