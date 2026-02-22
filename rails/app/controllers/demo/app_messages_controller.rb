module Demo
  class AppMessagesController < BaseController
    def index
      entries = Array.wrap(I18n.t("demo_admin.messages.entries", default: []))
      @messages = entries.map(&:deep_symbolize_keys)

      @actions = Array.wrap(I18n.t("demo_admin.messages.actions", default: []))
      coverage_lists = I18n.t("demo_admin.messages.coverage_lists", default: {})
      @channels = Array.wrap(coverage_lists[:channels])
      @locales = Array.wrap(coverage_lists[:locales])
    end
  end
end
