class ConfigEntry < ApplicationRecord
  belongs_to :scope, polymorphic: true, optional: true
  has_one :feature_flag_rollout, dependent: :destroy

  validates :key, presence: true
  validates :scope_type, presence: true
end
