# frozen_string_literal: true

module Admin
  class ServicesController < BaseController
    before_action :require_manage_offerings!, except: %i[index show]
    before_action :set_service, only: %i[show edit update]
    before_action :load_template_loader

    def index
      @offerings = current_temple.temple_services.order(created_at: :desc)
    end

    def show; end

    def new
      @offering = current_temple.temple_services.new(price_cents: nil, currency: "TWD")
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
        metadata_settings: {}
      )
      permitted[:currency] = permitted[:currency].presence || "TWD"
      permitted[:metadata] = merge_metadata_settings(permitted.delete(:metadata_settings))
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
      offering.metadata["form_label"] = template[:label]
      offering.metadata["registration_form"] = template[:registration_form]
      offering.slug ||= template[:slug]
    end

    def load_template_loader
      @template_loader = Offerings::TemplateLoader.new(current_temple.slug)
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
