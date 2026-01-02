class BlacklistEntry < ApplicationRecord
  belongs_to :scope, polymorphic: true, optional: true

  validates :reason, presence: true
end
