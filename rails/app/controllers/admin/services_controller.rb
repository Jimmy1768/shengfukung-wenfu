# frozen_string_literal: true

module Admin
  class ServicesController < BaseController
    before_action :require_manage_offerings!, except: %i[index show]
    before_action :set_service, only: %i[show edit update]
    before_action :load_template_loader
    helper_method :registration_period_options

    def index
      @offerings = current_temple.temple_services.order(created_at: :desc)
    end

    def show; end

    def new
      @offering = current_temple.temple_services.new(price_cents: nil, currency: "TWD")
      assign_default_location(@offering)
      apply_template_defaults(@offering, selected_template_slug, :services)
      @offering.currency ||= "TWD"
    end

    def create
      @offering = current_temple.temple_services.new(offering_params)
      apply_template_defaults(@offering, selected_template_slug, :services)

      missing_fields = Forms::FieldValidation.missing_fields(:offering, offering_params)
      missing_fields.each { |field| @offering.errors.add(field, :blank) }

      if missing_fields.empty? && @offering.save
        log_offering_event("admin.offerings.create")
        redirect_to admin_service_path(@offering), notice: "Service created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @offering.update(offering_params)
        log_offering_event("admin.offerings.update")
        redirect_to admin_service_path(@offering), notice: "Service updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_service
      @offering = current_temple.temple_services.find(params[:id])
    end

    def offering_params
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
      permitted[:metadata] = merge_metadata_settings(permitted.delete(:metadata_settings))
      if permitted[:registration_period_key].present?
        offered_period = current_temple.registration_period_label_for(permitted[:registration_period_key])
        permitted[:period_label] = offered_period if offered_period.present?
      end
      permitted
    end

    def merge_metadata_settings(raw)
      base = (@offering&.metadata || {}).with_indifferent_access
      settings =
        case raw
        when ActionController::Parameters then raw.to_unsafe_h
        when Hash then raw
        else {}
        end
      base.merge(settings)
    end

    def selected_template_slug
      params[:template_slug].presence
    end

    def apply_template_defaults(offering, template_slug, kind)
      return unless template_slug
      template = @template_loader.template_for(template_slug, kind: kind)
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
      offering.registration_period_key ||= template[:registration_period_key]
      apply_period_label(offering)
      assign_default_location(offering)
    end

    def load_template_loader
      @template_loader = Offerings::TemplateLoader.new(current_temple.slug)
    end

    def registration_period_options
      @registration_period_options ||= current_temple.registration_period_options
    end

    def apply_period_label(offering)
      return unless offering.registration_period_key.present?

      offering.period_label = current_temple.registration_period_label_for(offering.registration_period_key)
    end

    def assign_default_location(offering)
      return if offering.default_location.present?

      details = current_temple.contact_details
      offering.default_location = details["mapUrl"].presence ||
        details["addressZh"].presence ||
        details["addressEn"]
    end

    def require_manage_offerings!
      require_capability!(:manage_offerings)
    end

    def log_offering_event(action)
      SystemAuditLogger.log!(
        action:,
        admin: current_admin,
        target: @offering,
        metadata: {
          offering_id: @offering.id,
          changes: @offering.previous_changes.except("updated_at", "created_at")
        },
        temple: current_temple
      )
    end
  end
end
