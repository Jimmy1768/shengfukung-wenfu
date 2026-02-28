# frozen_string_literal: true

module Admin
  module NavigationHelper
    NAV_ITEMS = [
      {
        key: :dashboard,
        label: "Dashboard",
        description: "掌握指標與待辦",
        path: -> { admin_dashboard_path }
      },
      {
        key: :registrations,
        label: "Registrations",
        description: "建立與管理現場報名",
        path: -> { admin_registrations_path },
        capabilities: :manage_registrations
      },
      {
        key: :orders,
        label: "Orders",
        description: "檢視報名與紙本訂單",
        path: -> { admin_orders_path },
        capabilities: :manage_registrations
      },
      {
        key: :payments,
        label: "Payments",
        description: "查看付款統計與記錄",
        path: -> { admin_payments_path },
        capabilities: :view_financials
      },
      {
        key: :gatherings,
        label: "Gatherings",
        description: "社群活動與交流場次",
        path: -> { admin_gatherings_path },
        capabilities: :manage_offerings
      },
      {
        key: :offerings,
        label: "Offerings",
        description: "管理法會供品與祈福供品",
        path: -> { admin_offerings_path },
        capabilities: :manage_offerings
      },
      {
        key: :temple_profile,
        label: "Temple Profile",
        description: "更新官網基本資料",
        path: -> { admin_temple_profile_path },
        capabilities: :manage_profile
      },
      {
        key: :news_posts,
        label: "最新消息",
        description: "公告與最新消息",
        path: -> { admin_news_posts_path },
        capabilities: :manage_news
      },
      {
        key: :gallery_entries,
        label: "活動回顧",
        description: "活動回顧與相簿",
        path: -> { admin_gallery_entries_path },
        capabilities: :manage_gallery
      },
      {
        key: :patrons,
        label: "Patrons",
        description: "查看信眾與管理員候選人",
        path: -> { admin_patrons_path },
        capabilities: %i[manage_permissions manage_registrations]
      },
      {
        key: :archives,
        label: "Archives",
        description: "年度紀錄與報表",
        path: -> { admin_archives_path },
        capabilities: %i[view_financials export_financials]
      },
      {
        key: :permissions,
        label: "Permissions",
        description: "管理管理員權限",
        path: -> { admin_permissions_path },
        capabilities: :manage_permissions
      }
    ].freeze

    def admin_navigation_items
      NAV_ITEMS
        .select { |item| nav_item_visible?(item) }
        .map { |item| item.merge(label: nav_item_label(item)) }
    end

    def admin_navigation_link_path(item)
      instance_exec(&item[:path])
    end

    private

    def nav_item_visible?(item)
      return false if item[:owner_only] && !owner_admin_account?

      capabilities = Array(item[:capabilities]).compact
      return true if capabilities.empty?

      permissions = current_admin_permissions
      return false if permissions.nil?

      capabilities.any? { |capability| permissions.allow?(capability) }
    end

    def owner_admin_account?
      current_admin&.admin_account&.owner_role?
    end

    def nav_item_label(item)
      default_label = item[:label] || item[:key].to_s.humanize
      fallback_chain = []
      fallback_chain << item[:label_key] if item[:label_key]
      I18n.t("admin.nav.items.#{item[:key]}.label", default: fallback_chain + [default_label])
    end
  end
end
