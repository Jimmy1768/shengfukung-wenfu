# frozen_string_literal: true

module Admin
  class PatronsController < BaseController
    before_action :require_patron_access!, only: :index
    before_action :require_manage_permissions!, only: %i[promote revoke create]
    before_action :set_patron, only: %i[promote revoke]

    def index
      patrons = filtered_scope

      respond_to do |format|
        format.html do
          @query = params[:q].to_s.strip.presence
          @view = permitted_view
          @patrons = patrons
            .includes(:dependents, admin_account: :admin_temple_memberships)
            .limit(25)
          @can_manage_admins = can_manage_admins?
        end
        format.json do
          render json: {
            patrons: patrons.limit(50).map { |user| patron_payload(user) }
          }
        end
      end
    end

    def create
      form = Admin::PatronForm.new(patron_params)
      if form.save
        log_patron_creation(form.user)
        render json: { patron: patron_payload(form.user) }, status: :created
      else
        render json: { errors: form.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def promote
      manager.promote!(user: @patron, temple: current_temple, promoted_by: current_admin)
      redirect_to admin_patrons_path(view: params[:view], q: params[:q]), notice: t("admin.patrons.flash.promoted", name: @patron.english_name)
    rescue Admin::PatronAdminManager::Error => e
      redirect_to admin_patrons_path(view: params[:view], q: params[:q]), alert: e.message
    end

    def revoke
      manager.revoke!(user: @patron, temple: current_temple, revoked_by: current_admin)
      redirect_to admin_patrons_path(view: params[:view], q: params[:q]), notice: t("admin.patrons.flash.revoked", name: @patron.english_name)
    rescue Admin::PatronAdminManager::Error => e
      redirect_to admin_patrons_path(view: params[:view], q: params[:q]), alert: e.message
    end

    private

    def require_manage_permissions!
      unless can_manage_admins?
        redirect_to admin_dashboard_path, alert: t("admin.patrons.flash.forbidden")
      end
    end

    def require_patron_access!
      return if can_manage_admins? || current_admin_permissions&.allow?(:manage_registrations)

      redirect_to admin_dashboard_path, alert: t("admin.patrons.flash.forbidden")
    end

    def patron_scope
      User.all
    end

    def filtered_scope
      scope = base_scope
      query = params[:q].to_s.strip
      return scope.order(created_at: :desc) if query.blank?

      tokens = query.split(/\s+/).presence || [query]

      conditions = tokens.each_with_index.map do |_, index|
        "(english_name ILIKE :token#{index} OR native_name ILIKE :token#{index} OR email ILIKE :token#{index})"
      end.join(" AND ")
      bindings = tokens.each_with_index.to_h do |token, index|
        ["token#{index}".to_sym, "%#{token}%"]
      end

      scope
        .where(conditions, bindings)
        .order(Arel.sql(sanitized_order_clause(tokens.first)))
    end

    def base_scope
      if permitted_view == "admins"
        admin_user_scope
      else
        patron_scope.where.not(id: current_admin&.id)
      end
    end

    def admin_user_scope
      patron_scope
        .joins(admin_account: :admin_temple_memberships)
        .where(admin_temple_memberships: { temple_id: current_temple.id })
        .distinct
    end

    def permitted_view
      view = params[:view].to_s
      %w[admins all].include?(view) ? view : "all"
    end

    def sanitized_order_clause(first_token)
      exact_match = "#{ActiveRecord::Base.sanitize_sql_like(first_token)}%"
      ApplicationRecord.send(
        :sanitize_sql_array,
        ["CASE WHEN english_name ILIKE :exact THEN 0 ELSE 1 END, english_name ASC NULLS LAST", { exact: exact_match }]
      )
    end

    def set_patron
      @patron = User.find(params[:id])
    end

    def manager
      @manager ||= Admin::PatronAdminManager.new
    end

    def can_manage_admins?
      current_admin&.admin_account&.owner_role? || current_admin_permissions&.allow?(:manage_permissions)
    end

    helper_method :can_manage_admins?

    def patron_payload(user)
      metadata = user.metadata || {}
      {
        id: user.id,
        name: user.english_name,
        email: user.email,
        dependents: user.dependents.pluck(:english_name),
        phone: metadata["phone"],
        notes: metadata["notes"],
        offerings: metadata["offerings"] || {}
      }
    end

    def patron_params
      params.require(:patron).permit(:english_name, :email, :phone, :notes)
    end

    def log_patron_creation(user)
      SystemAuditLogger.log!(
        action: "admin.patrons.create",
        admin: current_admin,
        target: user,
        metadata: {
          user_id: user.id,
          email: user.email
        },
        temple: current_temple
      )
    end
  end
end
