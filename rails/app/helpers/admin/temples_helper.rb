# frozen_string_literal: true

module Admin
  module TemplesHelper
    PLACEHOLDER_ASSET = "admin/hero-placeholder.svg"

    def hero_image_preview_for(form, tab)
      tab_key = tab.to_s
      preview = form.hero_images[tab_key].presence || form.temple.hero_image_for(tab_key)
      preview.presence || asset_path(PLACEHOLDER_ASSET)
    end
  end
end
