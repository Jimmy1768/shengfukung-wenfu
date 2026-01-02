module Dev
  module Demo
    module Rails
      class PlaygroundController < BaseController
      def show
        data = I18n.t("demo_admin.custom_features", default: {})
        @features = Array.wrap(data[:entries])
        @cta = data[:cta]
        @hero = data[:hero] || {}
      end
      end
    end
  end
end
