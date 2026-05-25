# frozen_string_literal: true

module Admin
  class OfferingSetupDraftsController < BaseController
    before_action -> { require_capability!(:manage_offerings) }
    before_action :set_draft, only: %i[show edit update submit review apply]

    def index
      @drafts = current_temple.temple_offering_setup_drafts.recent_first
    end

    def show; end

    def new
      @draft = current_temple.temple_offering_setup_drafts.new(
        offering_kind: "service",
        currency: "TWD",
        price_cents: 0
      )
    end

    def create
      @draft = current_temple.temple_offering_setup_drafts.new(draft_params)
      @draft.created_by_admin = current_admin.admin_account

      if @draft.save
        log_draft_event("admin.offering_setup_drafts.create")
        redirect_to admin_offering_setup_draft_path(@draft), notice: t("admin.offering_setup_drafts.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      redirect_to admin_offering_setup_draft_path(@draft), alert: t("admin.offering_setup_drafts.flash.locked") unless @draft.editable?
    end

    def update
      unless @draft.editable?
        redirect_to admin_offering_setup_draft_path(@draft), alert: t("admin.offering_setup_drafts.flash.locked")
        return
      end

      if @draft.update(draft_params)
        log_draft_event("admin.offering_setup_drafts.update")
        redirect_to admin_offering_setup_draft_path(@draft), notice: t("admin.offering_setup_drafts.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def submit
      unless @draft.editable?
        redirect_to admin_offering_setup_draft_path(@draft), alert: t("admin.offering_setup_drafts.flash.submit_blocked")
        return
      end

      @draft.submit!(current_admin)
      log_draft_event("admin.offering_setup_drafts.submit")
      redirect_to admin_offering_setup_draft_path(@draft), notice: t("admin.offering_setup_drafts.flash.submitted")
    end

    def review
      unless @draft.status == "submitted"
        redirect_to admin_offering_setup_draft_path(@draft), alert: t("admin.offering_setup_drafts.flash.review_blocked")
        return
      end

      @draft.review!(current_admin, notes: params.dig(:temple_offering_setup_draft, :review_notes))
      log_draft_event("admin.offering_setup_drafts.review")
      redirect_to admin_offering_setup_draft_path(@draft), notice: t("admin.offering_setup_drafts.flash.reviewed")
    end

    def apply
      result = Offerings::SetupDraftApplier.call(draft: @draft, admin: current_admin)
      unless result.success?
        @apply_errors = result.errors
        flash.now[:alert] = result.errors.join(" ")
        render :show, status: :unprocessable_content
        return
      end

      @draft = @draft.reload
      log_draft_event("admin.offering_setup_drafts.apply", applied_target: result.target)
      redirect_to admin_offering_setup_draft_path(@draft), notice: t("admin.offering_setup_drafts.flash.applied")
    end

    private

    def set_draft
      @draft = current_temple.temple_offering_setup_drafts.find(params[:id])
    end

    def draft_params
      permitted = params.require(:temple_offering_setup_draft).permit(
        :offering_kind,
        :slug,
        :label,
        :registration_period_key,
        :price_cents,
        :currency,
        :category,
        :field_requirements_text,
        :options_text,
        :operational_notes,
        field_requirements: [],
        options: [
          :field,
          :label,
          :value
        ]
      )
      currency = permitted[:currency].presence || "TWD"
      {
        offering_kind: permitted[:offering_kind],
        slug: permitted[:slug],
        label: permitted[:label],
        registration_period_key: permitted[:registration_period_key],
        price_cents: Currency::Symbols.admin_input_to_amount_cents(permitted[:price_cents], currency),
        currency: currency,
        setup_payload: setup_payload_from(permitted)
      }
    end

    def setup_payload_from(permitted)
      {
        category: permitted[:category].presence,
        field_requirements: selected_field_requirements(permitted),
        options: selected_options(permitted),
        operational_notes: permitted[:operational_notes].presence
      }.compact
    end

    def selected_field_requirements(permitted)
      selected = Array(permitted[:field_requirements]).map(&:presence).compact
      legacy = lines_from(permitted[:field_requirements_text])
      (selected + legacy).uniq
    end

    def selected_options(permitted)
      raw_options =
        case permitted[:options]
        when ActionController::Parameters, Hash
          permitted[:options].values
        else
          Array(permitted[:options])
        end
      structured = raw_options.filter_map do |entry|
        next unless entry.respond_to?(:to_h)

        option = entry.to_h.with_indifferent_access
        next if option[:field].blank? || option[:label].blank?

        {
          "field" => option[:field],
          "label" => option[:label],
          "value" => option[:value].presence || option[:label].to_s.parameterize
        }
      end
      (structured + option_lines_from(permitted[:options_text])).uniq
    end

    def lines_from(value)
      value.to_s.lines.map(&:strip).reject(&:blank?)
    end

    def option_lines_from(value)
      lines_from(value).filter_map do |line|
        field, label, option_value = line.split("|", 3).map(&:strip)
        next if field.blank? || label.blank?

        {
          "field" => field,
          "label" => label,
          "value" => option_value.presence || label.parameterize
        }
      end
    end

    def log_draft_event(action, applied_target: nil)
      SystemAuditLogger.log!(
        action: action,
        admin: current_admin,
        target: @draft,
        temple: current_temple,
        metadata: {
          draft_id: @draft.id,
          status: @draft.status,
          slug: @draft.slug,
          offering_kind: @draft.offering_kind,
          applied_offering_type: applied_target&.class&.name || @draft.applied_offering_type,
          applied_offering_id: applied_target&.id || @draft.applied_offering_id
        }.compact
      )
    end
  end
end
