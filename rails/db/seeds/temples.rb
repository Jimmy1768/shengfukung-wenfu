# frozen_string_literal: true

require "yaml"

module Seeds
  module Temples
    extend self

    PROFILE_DIR = Rails.root.join("db", "temples")
    DEFAULT_PAGES = %w[home about events services contact].freeze
    DEFAULT_HERO_COPY = "用簡潔的段落說明本廟的宗旨、服務與交通資訊。"
    PLACEHOLDER_QR_PATH = "system/placeholders/line-pay-qr.png"
    DEFAULT_HERO_IMAGE = "https://placehold.co/1600x900/111827/FFFFFF?text=Temple+Hero"

    def seed(slug: AppConstants::Project.slug)
      config = profile_config(slug)
      puts "Seeding temple profile for #{config.fetch('slug')}..." # rubocop:disable Rails/Output
      temple = ensure_temple(config)
      ensure_hero_media_assets(temple)
      ensure_pages(temple)
      ensure_sections(temple)
       ensure_news_posts(temple, config["news_posts"])
       ensure_gallery_entries(temple, config["gallery_entries"])
      puts "Temple profile ready (#{temple.slug})." # rubocop:disable Rails/Output
    end

    private

    def profile_config(slug)
      path = PROFILE_DIR.join("#{slug}.yml")
      unless File.exist?(path)
        raise ArgumentError, "Missing temple profile config at #{path}. Add one under rails/db/temples."
      end

      raw = YAML.safe_load(
        File.read(path),
        permitted_classes: [Time, Date],
        aliases: true
      ) || {}
      config = raw.deep_stringify_keys
      config["slug"] ||= slug
      config
    end

    def ensure_temple(config)
      Temple.find_or_initialize_by(slug: config.fetch("slug")).tap do |record|
        record.assign_attributes(
          name: config.fetch("name"),
          tagline: config["tagline"],
          hero_copy: config["hero_copy"] || DEFAULT_HERO_COPY,
          primary_image_url: config["primary_image_url"],
          about_html: config["about_html"],
          hero_images: normalized_hero_images(config["hero_images"]),
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

    def ensure_hero_media_assets(temple)
      temple.hero_images.each do |tab, url|
        next if url.blank?

        asset = temple.media_assets.hero.where("metadata ->> 'hero_tab' = ?", tab).first_or_initialize
        asset.role = :hero_image
        asset.file_uid = asset.file_uid.presence || url
        meta = (asset.metadata || {}).merge("hero_tab" => tab, "url" => url)
        asset.metadata = meta.merge(seed_metadata)
        asset.save!
      end
    end

    def ensure_news_posts(temple, entries)
      Array(entries).each do |attrs|
        next if attrs.blank?

        identifier = attrs["slug"].presence || attrs["title"]
        next unless identifier

        temple.temple_news_posts.find_or_initialize_by(title: attrs["title"]).tap do |post|
          post.body = attrs["body"]
          post.published_at = attrs["published_at"]
          post.published = attrs.fetch("published", true)
          post.pinned = attrs.fetch("pinned", false)
          post.metadata = (post.metadata || {}).merge(attrs["metadata"] || {}).merge(seed_metadata).merge("seed_slug" => identifier)
          post.save!
        end
      end
    end

    def ensure_gallery_entries(temple, entries)
      Array(entries).each do |attrs|
        next if attrs.blank?

        temple.temple_gallery_entries.find_or_initialize_by(title: attrs["title"]).tap do |entry|
          entry.body = attrs["body"]
          entry.event_date = attrs["event_date"]
          entry.photo_urls = Array(attrs["photo_urls"])
          entry.metadata = (entry.metadata || {}).merge(attrs["metadata"] || {}).merge(seed_metadata)
          entry.save!
        end
      end
    end

    def normalized_hero_images(images)
      data = images.to_h.stringify_keys rescue {}
      Temple::HERO_TABS.index_with do |tab|
        data[tab].presence || data["home"].presence || DEFAULT_HERO_IMAGE
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
