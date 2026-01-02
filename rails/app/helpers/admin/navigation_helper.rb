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
        key: :temple_profile,
        label: "Temple Profile",
        description: "更新官網基本資料",
        path: -> { admin_temple_profile_path }
      }
    ].freeze

    def admin_navigation_items
      NAV_ITEMS
    end

    def admin_navigation_link_path(item)
      instance_exec(&item[:path])
    end
  end
end
