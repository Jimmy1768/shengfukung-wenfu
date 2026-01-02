class ApiUsageLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :request_path, :http_method, :occurred_at, presence: true
end
