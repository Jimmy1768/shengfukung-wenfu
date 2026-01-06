# frozen_string_literal: true

module Admin
  class PatronsController < BaseController
    before_action :require_manage_registrations!

    def index
      patrons = patron_scope
      patrons = patrons.where("english_name ILIKE :q OR email ILIKE :q", q: "%#{params[:q].to_s.strip}%") if params[:q].present?
      patrons = patrons.order("english_name asc NULLS LAST").limit(20)

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

    def patron_payload(user)
      {
        id: user.id,
        name: user.english_name,
        email: user.email,
        dependents: user.dependents.pluck(:english_name)
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
