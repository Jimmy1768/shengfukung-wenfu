module Account
  class TemplesController < BaseController
    skip_before_action :authenticate_user!, only: :index
    skip_before_action :ensure_temple_context, only: :index

    def index
      @temples = Temples::Manifest.all.map do |entry|
        record = Temple.find_by(slug: entry["slug"])
        entry.merge(
          "display_name" => record&.name || entry["label"] || entry["slug"].humanize,
          "hero_image_url" => record&.hero_images&.dig("home") || record&.primary_image_url
        )
      end
    end
  end
end
