class ApiRequestCounter < ApplicationRecord
  belongs_to :scope, polymorphic: true, optional: true

  validates :bucket, presence: true
end
