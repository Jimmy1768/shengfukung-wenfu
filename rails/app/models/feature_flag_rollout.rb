class FeatureFlagRollout < ApplicationRecord
  belongs_to :config_entry

  validates :rollout_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
