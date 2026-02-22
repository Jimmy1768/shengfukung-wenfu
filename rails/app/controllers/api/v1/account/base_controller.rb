# frozen_string_literal: true

module Api
  module V1
    module Account
      class BaseController < ::Account::BaseController
        layout false
        protect_from_forgery with: :null_session

        skip_before_action :assign_account_theme
        before_action :force_json_format

        rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

        private

        def render_not_found
          render json: { error: "not_found" }, status: :not_found
        end

        def render_forbidden
          render json: { error: "forbidden" }, status: :forbidden
        end

        def force_json_format
          request.format = :json
        end

        def admin_scope?
          current_user&.admin_account&.active?
        end

        def accessible_admin_temples
          return Temple.none unless admin_scope?

          @accessible_admin_temples ||= Temple.for_admin(current_user.admin_account)
        end

        def default_registration_scope
          return current_user.temple_event_registrations unless admin_scope?

          if current_user.admin_account.owner_role?
            TempleEventRegistration.where(temple_id: accessible_admin_temples.select(:id))
          else
            current_user.temple_event_registrations
          end
        end

        def ensure_admin_capability!(capability, temple)
          return false unless admin_scope?

          permission = current_user.admin_account.permissions_for(temple)
          return false unless permission.allow?(capability)

          true
        end
      end
    end
  end
end
