# frozen_string_literal: true

module Admin
  class PatronsController < BaseController
    before_action :require_manage_registrations!

    def index
      patrons = filtered_scope
      patrons = patrons.limit(20)

      render json: {
        patrons: patrons.map { |user| patron_payload(user) }
      }
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

    private

    def require_manage_registrations!
      require_capability!(:manage_registrations)
    end

    def patron_scope
      User.all
    end

    def filtered_scope
      query = params[:q].to_s.strip
      return patron_scope.order(created_at: :desc) if query.blank?

      tokens = query.split(/\s+/).presence || [query]

      conditions = tokens.each_with_index.map do |_, index|
        "(english_name ILIKE :token#{index} OR native_name ILIKE :token#{index} OR email ILIKE :token#{index})"
      end.join(" AND ")
      bindings = tokens.each_with_index.to_h do |token, index|
        ["token#{index}".to_sym, "%#{token}%"]
      end

      patron_scope
        .where(conditions, bindings)
        .order(Arel.sql(sanitized_order_clause(tokens.first)))
    end

    def sanitized_order_clause(first_token)
      exact_match = "#{ActiveRecord::Base.sanitize_sql_like(first_token)}%"
      ApplicationRecord.send(
        :sanitize_sql_array,
        ["CASE WHEN english_name ILIKE :exact THEN 0 ELSE 1 END, english_name ASC NULLS LAST", { exact: exact_match }]
      )
    end

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
