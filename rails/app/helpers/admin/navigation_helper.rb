# frozen_string_literal: true

module Admin
  module NavigationHelper
    NAV_ITEMS = [
      {
        key: :dashboard,
        label: I18n.t("admin.navigation.dashboard", default: "Dashboard"),
        description: "掌握指標與待辦",
        path: -> { admin_dashboard_path }
      },
      {
        key: :temple_profile,
        label: I18n.t("admin.navigation.profile", default: "Temple Profile"),
        description: "更新官網基本資料",
        path: -> { admin_temple_profile_path }
      },
      {
        key: :news_posts,
        label: I18n.t("admin.navigation.news", default: "最新消息"),
        description: "公告與最新消息",
        path: -> { admin_news_posts_path },
        capabilities: :manage_news
      },
      {
        key: :gallery_entries,
        label: I18n.t("admin.navigation.gallery", default: "活動回顧"),
        description: "活動回顧與相簿",
        path: -> { admin_gallery_entries_path },
        capabilities: :manage_gallery
      },
      {
        key: :offerings,
        label: "Offerings",
        description: "管理登記項目與檔期",
        path: -> { admin_offerings_path },
        capabilities: :manage_offerings
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
        capabilities: %i[view_financials export_financials]
      },
      {
        key: :archives,
        label: "Archives",
        description: "年度紀錄與報表",
        path: -> { admin_archives_path }
      },
      {
        key: :patrons,
        label: "Patrons",
        description: "查看信眾與管理員候選人",
        path: -> { admin_patrons_path },
        capabilities: %i[manage_permissions manage_registrations]
      },
      {
        key: :permissions,
        label: "Permissions",
        description: "管理管理員權限",
        path: -> { admin_permissions_path },
        owner_only: true
      }
    ].freeze

    def admin_navigation_items
      NAV_ITEMS.select { |item| nav_item_visible?(item) }
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
  end
end
