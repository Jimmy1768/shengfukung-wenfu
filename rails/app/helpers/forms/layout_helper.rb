# frozen_string_literal: true

# Helpers for composing horizontally aligned form sections (e.g., two-column rows
# with synced heights).
module Forms
  module LayoutHelper
    def field_row(options = {}, &block)
      classes = ["field-row", options.delete(:class)].compact.join(" ")
      content_tag(:div, capture(&block), **options.merge(class: classes))
    end

    def field_panel(options = {}, &block)
      classes = ["field-panel", options.delete(:class)].compact.join(" ")
      content_tag(:div, capture(&block), **options.merge(class: classes))
    end
  end
end
