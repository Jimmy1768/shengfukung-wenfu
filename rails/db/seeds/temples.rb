# frozen_string_literal: true

require "yaml"

module Seeds
  module Temples
    extend self

    PROFILE_DIR = Rails.root.join("db", "temples")
    DEFAULT_PAGES = %w[home about events services contact].freeze
    DEFAULT_HERO_COPY = "用簡潔的段落說明本廟的宗旨、服務與交通資訊。"
    PLACEHOLDER_QR_PATH = "system/placeholders/line-pay-qr.png"

    def seed(slug: AppConstants::Project.slug)
      config = profile_config(slug)
      puts "Seeding temple profile for #{config.fetch('slug')}..." # rubocop:disable Rails/Output
      temple = ensure_temple(config)
      ensure_pages(temple)
      ensure_sections(temple)
      ensure_placeholder_qr(temple)
      puts "Temple profile ready (#{temple.slug})." # rubocop:disable Rails/Output
    end

    private

    def profile_config(slug)
      path = PROFILE_DIR.join("#{slug}.yml")
      unless File.exist?(path)
        raise ArgumentError, "Missing temple profile config at #{path}. Add one under rails/db/temples."
      end

      raw = YAML.safe_load(File.read(path), aliases: true) || {}
      config = raw.deep_stringify_keys
      config["slug"] ||= slug
      config
    end

    def ensure_placeholder_qr(temple)
      placeholder = Rails.root.join("public", PLACEHOLDER_QR_PATH)
      return unless File.exist?(placeholder)

      temple.media_assets.find_or_create_by!(role: :line_pay_qr) do |asset|
        asset.file_uid = "line-pay-qr-placeholder"
        asset.alt_text = "LINE Pay QR placeholder"
        asset.metadata = {
          "url" => "/#{PLACEHOLDER_QR_PATH}",
          "source" => "placeholder"
        }
      end
    end

    def ensure_temple(config)
      Temple.find_or_initialize_by(slug: config.fetch("slug")).tap do |record|
        record.assign_attributes(
          name: config.fetch("name"),
          tagline: config["tagline"],
          hero_copy: config["hero_copy"] || DEFAULT_HERO_COPY,
          primary_image_url: config["primary_image_url"],
          about_html: config["about_html"],
          contact_info: config.fetch("contact", {}),
          service_times: config.fetch("service_times", {}),
          published: config.fetch("published", true),
          metadata: (record.metadata || {}).merge(seed_metadata).merge(config.fetch("metadata", {}))
        )
        record.save!
      end
    end

    def ensure_pages(temple)
      DEFAULT_PAGES.each_with_index do |kind, index|
        temple.temple_pages.find_or_create_by!(kind:) do |page|
          page.title = I18n.t("temples.pages.#{kind}.title", default: kind.titleize)
          page.slug = kind
          page.position = index + 1
          page.meta = {
            subtitle: I18n.t("temples.pages.#{kind}.subtitle", default: "預設頁面")
          }
        end
      end
    end

    def ensure_sections(temple)
      home = temple.temple_pages.find_by(kind: :home)
      return unless home

      home.temple_sections.find_or_create_by!(section_type: :event_list) do |section|
        section.title = "近期活動 / 法會"
        section.body = "從後台輸入活動資訊即可顯示在前台。"
        section.position = 1
        section.payload = {
          events: [
            { slug: "new-year", month: "JAN", day: "05", title: "新年祈福", when: "2026/01/05 09:00", where: "本廟主殿", summary: "簡短說明來自種子資料。", badge: "可報名" },
            { slug: "lantern-festival", month: "FEB", day: "12", title: "元宵祈福", when: "2026/02/12 10:00", where: "服務處", summary: "示範資料，稍後改由 Admin 輸入。", badge: "名額有限" }
          ]
        }
      end
    end

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:temples"
      }
    end
  end
end
