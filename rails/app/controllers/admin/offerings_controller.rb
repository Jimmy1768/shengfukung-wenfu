# frozen_string_literal: true

module Admin
  class OfferingsController < BaseController
    before_action :set_offering, only: %i[show edit update]
    before_action :load_template_loader
    before_action :require_manage_offerings!, except: %i[index show]

    def index
      @offerings = current_temple.temple_offerings.order(created_at: :desc)
    end

    def show; end

    def new
      @offering = current_temple.temple_offerings.new(price_cents: nil, currency: "TWD")
      apply_template_defaults(@offering, selected_template_slug)
      @offering.currency ||= "TWD"
    end

    def create
      @offering = current_temple.temple_offerings.new(offering_params)

      apply_template_defaults(@offering, selected_template_slug)

      missing_fields = Forms::FieldValidation.missing_fields(:offering, offering_params)
      missing_fields.each do |field|
        @offering.errors.add(field, :blank)
      end

      if missing_fields.empty? && @offering.save
        log_offering_event("admin.offerings.create")
        redirect_to admin_offering_path(@offering), notice: "Offering created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @offering.update(offering_params)
        log_offering_event("admin.offerings.update")
        redirect_to admin_offering_path(@offering), notice: "Offering updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_offering
      @offering = current_temple.temple_offerings.find(params[:id])
    end

    def require_manage_offerings!
      require_capability!(:manage_offerings)
    end

    def offering_params
      permitted = params.require(:temple_offering).permit(
        :slug,
        :offering_type,
        :title,
        :description,
        :price_cents,
        :currency,
        :period,
        :starts_on,
        :ends_on,
        :available_slots,
        :active,
        metadata_settings: {}
      )
      permitted[:currency] = permitted[:currency].presence || "TWD"
      permitted[:price_cents] = nil if permitted[:price_cents].blank?
      permitted[:metadata] = merge_metadata_settings(permitted.delete(:metadata_settings))
      permitted
    end

    def merge_metadata_settings(raw)
      base = (@offering&.metadata || {}).with_indifferent_access
      settings = raw.to_h
      base.merge(settings)
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

    def selected_template_slug
      params[:template_slug].presence
    end

    def apply_template_defaults(offering, template_slug)
      return unless template_slug

      template = @template_loader.template_for(template_slug)
      return unless template

      offering.title ||= template[:label]
      offering.offering_type = template.dig(:defaults, :offering_type)
      offering.metadata ||= {}
      offering.metadata["form_fields"] = template[:form_fields]
      offering.metadata["form_defaults"] = template[:defaults]
      offering.metadata["form_options"] = template[:options]
      offering.metadata["form_label"] = template[:label]
      offering.metadata["registration_form"] = template[:registration_form]
    end

    def load_template_loader
      @template_loader = Offerings::TemplateLoader.new(current_temple.slug)
    end
  end
end
