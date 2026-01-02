class ClientCacheMetric < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :client_checkin, optional: true

  validates :metric_key, presence: true
end
