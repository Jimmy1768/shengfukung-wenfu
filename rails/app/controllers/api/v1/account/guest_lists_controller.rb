# frozen_string_literal: true

module Api
  module V1
    module Account
      class GuestListsController < BaseController
        def show
          offering = accessible_offerings.find_by(slug: params[:offering_id]) ||
            accessible_offerings.find_by(id: params[:offering_id])
          raise ActiveRecord::RecordNotFound unless offering
          unless ensure_admin_capability!(:view_guest_lists, offering.temple)
            render_forbidden
            return
          end

          registrations = offering.temple_event_registrations.includes(:user).order(created_at: :asc)
          render json: Account::Api::GuestListSerializer.new(offering:, registrations:).as_json
        end

        private

        def accessible_offerings
          return TempleOffering.none unless admin_scope?

          TempleOffering.where(temple_id: accessible_admin_temples.select(:id))
        end
      end
    end
  end
end
