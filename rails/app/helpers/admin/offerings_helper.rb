# frozen_string_literal: true

module Admin
  module OfferingsHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::FormTagHelper
    SECTION_TITLES = {
      basics: ->(metadata) { metadata[:form_label] || I18n.t("admin.offering_form.sections.basics") },
      donation: ->(_) { "捐獻說明" },
      ritual: ->(_) { "儀式資訊" },
      certificate: ->(_) { I18n.t("admin.offering_form.sections.certificate") },
      logistics: ->(_) { I18n.t("admin.offering_form.sections.logistics") },
      schedule: ->(_) { "檔期設定" },
      blessing: ->(_) { "祈福內容" },
      ancestor: ->(_) { "祖先資訊" },
      fulfillment: ->(_) { "作業方式" }
    }.freeze

    def render_offering_sections(form, metadata)
      defaults = metadata[:form_defaults] || {}
      option_map = metadata[:form_options] || {}
      sections = metadata[:form_fields] || {}

      safe_join(sections.map do |section_key, config|
        render_offering_section(form, section_key, config, defaults, option_map, metadata)
      end.compact)
    end

    private

    def render_offering_section(form, section_key, config, defaults, option_map, metadata)
      fields = normalize_field_config(section_key, config)
      return if fields.empty?

      title_proc = SECTION_TITLES[section_key.to_sym]
      title = title_proc ? title_proc.call(metadata) : section_key.to_s.titleize

      content_tag(:section, class: "card form-section") do
        safe_join([
          content_tag(:header) do
            content_tag(:h2, title)
          end,
          render_offering_fields(form, fields, defaults, option_map)
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

    def render_offering_fields(form, fields, defaults, option_map)
      safe_join(fields.map do |field|
        render_offering_field(form, field, defaults, option_map)
      end.compact)
    end

    def render_offering_field(form, field, defaults, option_map)
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
      when :active
        render_checkbox_field(form, :active, I18n.t("admin.offering_form.fields.active"))
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
      content_tag(:div, class: "field checkbox-field") do
        content_tag(:label) do
          safe_join([
            form.check_box(field),
            content_tag(:span, label)
          ])
        end
      end
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
  end
end
