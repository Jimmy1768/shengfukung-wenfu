# frozen_string_literal: true

module Admin
  module OfferingOrdersHelper
    def registration_field_control(builder, field, type:, schema:, value:, html_options: {})
      options = schema.field_options(field)
      if options.present?
        builder.select(field, options_for_select(options, value), {}, html_options)
      else
        render_input(builder, field, type, html_options, value)
      end
    end

    def registration_multi_value_toggle(field, schema)
      return unless schema.allow_multiple?(field)

      field_id = "multi-value-#{field}"
      content_tag(:div, class: "field-addon multi-value-toggle") do
        safe_join([
          content_tag(:label, for: field_id) do
            safe_join([
              check_box_tag("temple_event_registration[multi_value_fields][]", field, false, id: field_id),
              content_tag(:span, I18n.t("admin.registration_form.labels.save_additional"))
            ])
          end,
          content_tag(:p, I18n.t("admin.registration_form.hints.save_additional"), class: "hint")
        ])
      end
    end

    private

    def render_input(builder, field, type, html_options, value)
      case type
      when :number
        builder.number_field(field, html_options.merge(value: value))
      when :email
        builder.email_field(field, html_options.merge(value: value))
      when :telephone
        builder.telephone_field(field, html_options.merge(value: value))
      when :textarea
        rows = html_options.delete(:rows)
        builder.text_area(field, html_options.merge(value: value, rows: rows || 3))
      when :date
        builder.date_field(field, html_options.merge(value: value))
      else
        builder.text_field(field, html_options.merge(value: value))
      end
    end
  end
end
