module Demo
  class DashboardController < BaseController
    def index
      data = I18n.t("demo_admin.dashboard", default: {})
      @selected_locale_label = data[:selected_locale_label]
      @selected_locale_value =
        active_locale_entry[:name].presence || data[:selected_locale_value] || data[:selected_locale_fallback]
      @system_settings = Array.wrap(data[:system_settings_entries])
      @theme_keys_label = data[:theme_keys_label]
      @theme_keys = Array.wrap(data[:theme_keys_list])
    end
  end
end
