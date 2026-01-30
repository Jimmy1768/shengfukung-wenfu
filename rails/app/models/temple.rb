# frozen_string_literal: true

class Temple < ApplicationRecord
  has_many :temple_pages,
    inverse_of: :temple,
    dependent: :destroy
  has_many :temple_sections,
    through: :temple_pages
  has_many :media_assets,
    dependent: :destroy
  has_many :admin_temple_memberships,
    dependent: :destroy
  has_many :admin_accounts,
    through: :admin_temple_memberships
  has_many :system_audit_logs,
    dependent: :nullify
  has_many :temple_offerings,
    dependent: :destroy
  has_many :temple_event_registrations,
    dependent: :destroy
  has_many :temple_payments,
    through: :temple_event_registrations
  has_many :admin_permissions,
    dependent: :destroy
  has_many :temple_news_posts,
    dependent: :destroy
  has_many :temple_gallery_entries,
    dependent: :destroy

  scope :published, -> { where(published: true) }
  scope :for_admin, lambda { |admin_account|
    joins(:admin_temple_memberships)
      .where(admin_temple_memberships: { admin_account_id: admin_account.id })
      .distinct
  }

  validates :slug, :name, presence: true

  HERO_TABS = %w[home about events event archive news services contact].freeze

  def contact_details
    contact_info.presence || {}
  end

  def service_schedule
    service_times.presence || {}
  end

  def visit_info
    data = metadata.is_a?(Hash) ? metadata : {}
    info = data["visit_info"]
    info.is_a?(Hash) ? info : {}
  end

  def hero_images
    value = self[:hero_images]
    value.present? ? value.stringify_keys : {}
  end

  def hero_image_for(tab)
    tab_key = tab.to_s
    hero_media_asset_for(tab_key)&.metadata&.dig("url") ||
      hero_images[tab_key].presence ||
      hero_images["home"].presence
  end

  def hero_images_with_fallback
    HERO_TABS.each_with_object({}) do |tab, buffer|
      buffer[tab] = hero_image_for(tab)
    end
  end

  def hero_media_asset_for(tab)
    media_assets.hero.where("metadata ->> 'hero_tab' = ?", tab.to_s).first
  end
end
