# frozen_string_literal: true

module Admin
  module OfferingsHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::FormTagHelper
    SECTION_TITLES = {
      basics: ->(metadata) { metadata[:form_label] || I18n.t("admin.offering_form.sections.offering_details") },
      default: ->(_) { I18n.t("admin.offering_form.sections.offering_details") }
    }.freeze

    def render_offering_sections(form, metadata, skip_fields: [], skip_sections: [])
      defaults = metadata[:form_defaults] || {}
      option_map = metadata[:form_options] || {}
      sections = metadata[:form_fields] || {}

      safe_join(sections.map do |section_key, config|
        render_offering_section(form, section_key, config, defaults, option_map, metadata, skip_fields, skip_sections)
      end.compact)
    end

    private

    def render_offering_section(form, section_key, config, defaults, option_map, metadata, skip_fields, skip_sections)
      return if skip_sections.include?(section_key.to_sym)

      custom_title = section_title_override(config)
      fields = normalize_field_config(section_key, config)
      fields = fields.reject { |field| skip_fields.include?(field.to_sym) }
      return if fields.empty?

      title = custom_title.presence || section_title(section_key, metadata)

      content_tag(:section, class: "card form-section") do
        safe_join([
          content_tag(:header) do
            content_tag(:h2, title)
          end,
          render_offering_fields(form, fields, defaults, option_map, skip_fields)
        ])
      end
    end

    def normalize_field_config(section_key, config)
      case config
      when TrueClass
        [section_key]
      when Symbol, String
        [config]
      when Array
        config
      when Hash
        Array.wrap(config[:fields])
      else
        []
      end
    end

    def section_title_override(config)
      config.is_a?(Hash) ? config[:title] : nil
    end

    def section_title(section_key, metadata)
      renderer = SECTION_TITLES[section_key.to_sym] || SECTION_TITLES[:default]
      renderer.call(metadata)
    end

    def render_offering_fields(form, fields, defaults, option_map, skip_fields)
      safe_join(fields.map do |field|
        render_offering_field(form, field, defaults, option_map, skip_fields)
      end.compact)
    end

    def render_offering_field(form, field, defaults, option_map, skip_fields = [])
      return if skip_fields.include?(field.to_sym)

      case field.to_sym
      when :title
        render_text_field(form, :title, I18n.t("admin.offering_form.fields.title"), defaults[:title])
      when :offering_type
        render_static_field(form, :offering_type, I18n.t("admin.offering_form.fields.offering_type"), defaults[:offering_type])
      when :period
        render_select_or_text_field(form, :period, I18n.t("admin.offering_form.fields.period"), option_map[:period], defaults[:period])
      when :price_cents
        render_number_field(form, :price_cents, I18n.t("admin.registration_form.fields.unit_price"))
      when :currency
        render_select_field(
          form,
          :currency,
          I18n.t("admin.offering_form.fields.currency"),
          option_map[:currency].presence || Currency::Symbols.options,
          defaults[:currency] || form.object.currency || "TWD"
        )
      when :description
        render_text_area(form, :description, I18n.t("admin.offering_form.fields.description"))
      when :starts_on
        render_date_field(form, :starts_on, I18n.t("admin.offering_form.fields.starts_on"))
      when :ends_on
        render_date_field(form, :ends_on, I18n.t("admin.offering_form.fields.ends_on"))
      when :available_slots, :quota
        render_number_field(form, :available_slots, I18n.t("admin.offering_form.fields.available_slots"))
      when :lamp_type
        render_select_field(form, :lamp_type, "燈別", option_map[:lamp_type], defaults[:lamp_type])
      when :lamp_location
        render_text_field(form, :lamp_location, "燈位位置", defaults[:lamp_location])
      when :lamp_code_prefix
        form.hidden_field(:lamp_code_prefix, value: defaults[:lamp_code_prefix])
      when :blessing_purpose
        render_text_field(form, :blessing_purpose, "祈福事項")
      when :blessing_names
        render_text_area(form, :blessing_names, "祈福姓名")
      when :fulfillment_method
        render_select_field(form, :fulfillment_method, "作業方式", option_map[:fulfillment_method], defaults[:fulfillment_method])
      when :logistics_notes
        render_text_area(form, :logistics_notes, I18n.t("admin.offering_form.fields.logistics_notes"))
      when :blessing_target_type
        render_select_field(form, :blessing_target_type, "祈福對象", option_map[:blessing_target_type], defaults[:blessing_target_type])
      when :blessing_names_list
        render_text_area(form, :blessing_names_list, "祈福者姓名")
      when :ritual_date
        render_date_field(form, :ritual_date, "儀式日期")
      when :ritual_description
        render_text_area(form, :ritual_description, "儀式說明")
      when :certificate_prefix
        render_text_field(form, :certificate_prefix, I18n.t("admin.offering_form.fields.certificate_prefix"))
      when :certificate_hint
        render_text_field(form, :certificate_hint, I18n.t("admin.offering_form.fields.certificate_hint"))
      when :certificate_enabled
        render_checkbox_field(form, :certificate_enabled, "啟用證書")
      when :ancestor_name
        render_text_field(form, :ancestor_name, "祖先姓名")
      when :ancestor_generation
        render_select_field(form, :ancestor_generation, "祭拜代數", option_map[:ancestor_generation], defaults[:ancestor_generation])
      when :sponsor_name
        render_text_field(form, :sponsor_name, "陽上人姓名")
      when :sponsor_relation
        render_text_field(form, :sponsor_relation, "與祖先關係")
      when :table_size
        render_select_field(form, :table_size, "供桌尺寸", option_map[:table_size], defaults[:table_size])
      when :table_items
        render_text_area(form, :table_items, "供桌內容")
      else
        nil
      end
    end

    def render_text_field(form, field, label, value = nil)
      content_tag(:div, class: "field") do
        safe_join([
          form.label(field, label),
          form.text_field(field, value: value)
        ])
      end
    end

    def render_number_field(form, field, label)
      content_tag(:div, class: "field") do
        safe_join([
          form.label(field, label),
          form.number_field(field)
        ])
      end
    end

    def render_select_field(form, field, label, options, selected = nil)
      options = Array.wrap(options)
      return render_text_field(form, field, label, selected) if options.empty?

      content_tag(:div, class: "field") do
        safe_join([
          form.label(field, label),
          form.select(field, options_for_select(options, selected))
        ])
      end
    end

    def render_select_or_text_field(form, field, label, options, selected = nil)
      options&.any? ? render_select_field(form, field, label, options, selected) : render_text_field(form, field, label, selected)
    end

    def render_text_area(form, field, label)
      content_tag(:div, class: "field") do
        safe_join([
          form.label(field, label),
          form.text_area(field, rows: 3)
        ])
      end
    end

    def render_checkbox_field(form, field, label)
      selected_value = ActiveModel::Type::Boolean.new.cast(form.object.public_send(field)) ? "1" : "0"

      render(
        "admin/shared/segmented_boolean",
        name: "#{form.object_name}[#{field}]",
        id_prefix: "#{form.object_name}_#{field}",
        label:,
        selected_value:,
        options: [[1, I18n.t("admin.shared.binary.enabled")], [0, I18n.t("admin.shared.binary.disabled")]]
      )
    end

    def render_date_field(form, field, label)
      content_tag(:div, class: "field") do
        safe_join([
          form.label(field, label),
          form.date_field(field)
        ])
      end
    end

    def render_static_field(form, field, label, default)
      value = form.object.send(field) || default
      safe_join([
        form.hidden_field(field, value: value),
        content_tag(:div, class: "field") do
          safe_join([
            content_tag(:label, label),
            content_tag(:p, value, class: "static-value")
          ])
        end
      ])
    end

    def localized_options(options)
      Array.wrap(options).map do |value|
        case value
        when Array
          value
        else
          [I18n.t("admin.offerings.types.#{value}", default: value.to_s), value]
        end
      end
    end

    def currency_options
      Currency::Symbols.options
    end

    def admin_offering_path_for(offering)
      case offering
      when TempleService
        admin_service_path(offering)
      when TempleGathering
        edit_admin_gathering_path(offering)
      else
        admin_event_path(offering)
      end
    end

    def admin_offering_orders_path_for(offering)
      case offering
      when TempleService
        admin_service_offering_orders_path(offering)
      when TempleGathering
        admin_gathering_offering_orders_path(offering)
      else
        admin_event_offering_orders_path(offering)
      end
    end

    def new_admin_offering_order_path_for(offering)
      case offering
      when TempleService
        new_admin_service_offering_order_path(offering)
      when TempleGathering
        new_admin_gathering_offering_order_path(offering)
      else
        new_admin_event_offering_order_path(offering)
      end
    end

    def admin_offering_order_path_for(offering, registration)
      case offering
      when TempleService
        admin_service_offering_order_path(offering, registration)
      when TempleGathering
        admin_gathering_offering_order_path(offering, registration)
      else
        admin_event_offering_order_path(offering, registration)
      end
    end

    def edit_admin_offering_order_path_for(offering, registration)
      case offering
      when TempleService
        edit_admin_service_offering_order_path(offering, registration)
      when TempleGathering
        edit_admin_gathering_offering_order_path(offering, registration)
      else
        edit_admin_event_offering_order_path(offering, registration)
      end
    end
  end
end
