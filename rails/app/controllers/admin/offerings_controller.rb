# frozen_string_literal: true

module Admin
  class OfferingsController < BaseController
    before_action :require_manage_offerings!, except: :index
    before_action :set_archive_filter, only: :index
    before_action :load_template_loader, only: %i[new create]
    before_action :load_templates, only: %i[new create]
    before_action :resolve_selected_template, only: %i[new create]
    before_action :set_offering_kind, only: %i[new create]

    def index
      collections =
        if @show_archived
          [
            current_temple.temple_events.where(status: "archived"),
            current_temple.temple_services.where(status: "archived")
          ]
        else
          [
            current_temple.temple_events.where(status: %w[draft published]),
            current_temple.temple_services.where(status: %w[draft published])
          ]
        end
      @offerings = collections.flat_map(&:to_a).sort_by(&:updated_at).reverse
    end

    def new
      if @selected_template.present?
        @offering = build_offering_instance(@offering_kind, persist: false)
        apply_template_defaults(@offering, @selected_template[:slug], kind: @offering_kind)
        @offering.currency ||= "TWD" if @offering.respond_to?(:currency)
      else
        @offering = nil
      end
    end

    def create
      unless @offering_kind
        redirect_to new_admin_offering_path, alert: "Please select a template before saving." and return
      end

      attributes = offering_params
      @offering = build_offering_instance(@offering_kind, persist: true, attributes:)
      apply_template_defaults(@offering, params[:template_slug], kind: @offering_kind)

      missing_fields = Forms::FieldValidation.missing_fields(:offering, attributes)
      missing_fields.each { |field| @offering.errors.add(field, :blank) }

      if missing_fields.empty? && @offering.save
        log_offering_event("admin.offerings.create")
        redirect_to offering_path_for(@offering), notice: "Offering created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def load_template_loader
      @template_loader = Offerings::TemplateLoader.new(current_temple.slug)
    end

    def load_templates
      @templates = @template_loader.templates
    end

    def resolve_selected_template
      slug = params[:template_slug].presence
      @selected_template = slug.present? ? @template_loader.template_for(slug) : nil
    end

    def set_offering_kind
      @offering_kind =
        if params[:offering_kind].present?
          params[:offering_kind].to_sym
        else
          @selected_template&.fetch(:kind, nil)
        end
    end

    def build_offering_instance(kind, persist:, attributes: {})
      case kind
      when :service, :services
        relation = current_temple.temple_services
      else
        relation = current_temple.temple_events
      end

      persist ? relation.new(attributes) : relation.new(price_cents: nil, currency: "TWD")
    end

    def offering_path_for(offering)
      if offering.is_a?(TempleService)
        admin_service_path(offering)
      else
        admin_event_path(offering)
      end
    end

    def offering_params
      case @offering_kind
      when :service, :services
        service_params
      else
        event_params
      end
    end

    def event_params
      permitted = params.require(:temple_event).permit(
        :title,
        :subtitle,
        :description,
        :price_cents,
        :currency,
        :starts_on,
        :ends_on,
        :start_time,
        :end_time,
        :location_name,
        :location_address,
        :location_notes,
        :capacity_total,
        :status,
        :hero_image_url,
        metadata_settings: {}
      )
      permitted[:currency] = permitted[:currency].presence || "TWD"
      permitted[:metadata] = merge_metadata_settings(@offering&.metadata, permitted.delete(:metadata_settings))
      permitted
    end

    def service_params
      permitted = params.require(:temple_service).permit(
        :title,
        :subtitle,
        :description,
        :price_cents,
        :currency,
        :period_label,
        :available_from,
        :available_until,
        :quantity_limit,
        :default_location,
        :fulfillment_notes,
        :status,
        :hero_image_url,
        :registration_period_key,
        metadata_settings: {}
      )
      permitted[:currency] = permitted[:currency].presence || "TWD"
      permitted[:metadata] = merge_metadata_settings(@offering&.metadata, permitted.delete(:metadata_settings))
      if permitted[:registration_period_key].present?
        offered_period = current_temple.registration_period_label_for(permitted[:registration_period_key])
        permitted[:period_label] = offered_period if offered_period.present?
      end
      permitted
    end

    def merge_metadata_settings(existing_metadata, raw)
      base = (existing_metadata || {}).with_indifferent_access
      settings =
        case raw
        when ActionController::Parameters then raw.to_unsafe_h
        when Hash then raw
        else {}
        end
      base.merge(settings)
    end

    def apply_template_defaults(offering, template_slug, kind:)
      return if template_slug.blank?

      template = @template_loader.template_for(template_slug, kind:)
      return unless template

      offering.title ||= template[:label]
      offering.metadata ||= {}
      offering.metadata["offering_type"] = template.dig(:defaults, :offering_type)
      offering.metadata["form_fields"] = template[:form_fields]
      offering.metadata["form_defaults"] = template[:defaults]
      offering.metadata["form_options"] = template[:options]
      offering.metadata["form_ui"] = template[:ui]
      offering.metadata["form_label"] = template[:label]
      offering.metadata["registration_form"] = template[:registration_form]
      offering.slug ||= template[:slug]
      offering.registration_period_key ||= template[:registration_period_key] if offering.respond_to?(:registration_period_key=)
      apply_period_label(offering) if offering.respond_to?(:registration_period_key)

      attribute_defaults = template[:attributes] || {}
      attribute_defaults.each do |attr, value|
        writer = "#{attr}="
        next unless offering.respond_to?(writer)
        current_value = offering.public_send(attr)
        next if current_value.present?

        offering.public_send(writer, value)
      end
    end

    def apply_period_label(offering)
      return unless offering.respond_to?(:registration_period_key)
      return unless offering.registration_period_key.present?

      offering.period_label = current_temple.registration_period_label_for(offering.registration_period_key)
    end

    def log_offering_event(action)
      SystemAuditLogger.log!(
        action:,
        admin: current_admin,
        target: @offering,
        metadata: {
          offering_id: @offering&.id,
          changes: @offering&.previous_changes&.except("updated_at", "created_at")
        },
        temple: current_temple
      )
    end

    def set_archive_filter
      @show_archived = ActiveModel::Type::Boolean.new.cast(params[:archived])
    end

    def require_manage_offerings!
      require_capability!(:manage_offerings)
    end

    helper_method :archived_view?

    def archived_view?
      @show_archived
    end
  end
end
