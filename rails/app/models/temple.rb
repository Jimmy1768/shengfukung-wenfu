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
  has_many :temple_events,
    dependent: :destroy
  has_many :temple_services,
    dependent: :destroy
  has_many :temple_gatherings,
    dependent: :destroy
  has_many :temple_offerings,
    class_name: "TempleEvent",
    dependent: :destroy
  has_many :temple_registrations,
    dependent: :destroy
  has_many :temple_event_registrations,
    class_name: "TempleEventRegistration",
    dependent: :destroy
  has_many :temple_payments,
    through: :temple_registrations
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

  def about_content
    data = metadata.is_a?(Hash) ? metadata : {}
    about = data["about"]
    about.is_a?(Hash) ? about : {}
  end

  def registration_periods
    data = metadata.is_a?(Hash) ? metadata : {}
    periods = Array(data["registration_periods"])
    periods.map do |entry|
      entry = entry.with_indifferent_access rescue { key: entry }
      {
        "key" => entry[:key] || entry["key"] || entry,
        "label_zh" => entry[:label_zh] || entry["label_zh"],
        "label_en" => entry[:label_en] || entry["label_en"]
      }.with_indifferent_access
    end
  end

  def registration_period_options(locale = I18n.locale)
    registration_periods.map do |entry|
      [registration_period_label(entry, locale), entry[:key]]
    end
  end

  def registration_period_label(entry, locale = I18n.locale)
    entry = entry.with_indifferent_access
    case locale
    when :"zh-TW"
      entry[:label_zh].presence || entry[:label_en].presence || entry[:key]
    else
      entry[:label_en].presence || entry[:label_zh].presence || entry[:key]
    end
  end

  def registration_period_label_for(key, locale = I18n.locale)
    entry = registration_periods.find { |period| period[:key].to_s == key.to_s }
    entry ? registration_period_label(entry, locale) : key
  end

  def hero_images
    value = self[:hero_images]
    value.present? ? value.stringify_keys : {}
  end

  def hero_image_for(tab)
    tab_key = tab.to_s
    image_from_map = sanitized_hero_source(hero_images[tab_key], allow_placeholder: tab_key == "home")
    return image_from_map if image_from_map.present?

    hero_media_asset_for(tab_key)&.metadata&.dig("url").presence ||
      sanitized_hero_source(hero_images["home"], allow_placeholder: true)
  end

  def hero_images_with_fallback
    HERO_TABS.each_with_object({}) do |tab, buffer|
      buffer[tab] = hero_image_for(tab)
    end
  end

  def profile_complete?
    details = contact_details
    [name, tagline, hero_copy, details["phone"], details["mapUrl"]].all?(&:present?)
  end

  def hero_media_asset_for(tab)
    media_assets.hero.where("metadata ->> 'hero_tab' = ?", tab.to_s).first
  end

  def sanitized_hero_source(value, allow_placeholder: false)
    return nil if value.blank?
    return value if allow_placeholder
    placeholder_hero?(value) ? nil : value
  end

  def placeholder_hero?(value)
    value.to_s.match?(/placehold\.co/i)
  end
end
