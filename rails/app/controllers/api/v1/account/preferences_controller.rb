# frozen_string_literal: true

module Api
  module V1
    module Account
      class PreferencesController < BaseController
        def show
          render json: preference_payload(UserPreference.for_user(current_user))
        end

        def update
          preference = UserPreference.for_user(current_user)
          updates = preference_params.to_h.symbolize_keys
          errors = apply_updates(preference, updates)

          if errors.any?
            return render json: { error: "invalid_preferences", details: errors }, status: :unprocessable_entity
          end

          if preference.changed?
            preference.save!
            SystemAuditLogger.log!(
              action: "preferences.theme_updated",
              admin: current_user,
              target: preference,
              temple: current_temple,
              metadata: { updated_fields: updates.keys.map(&:to_s) }
            )
          end

          render json: preference_payload(preference)
        end

        private

        def preference_params
          params.fetch(:preferences, {}).permit(:account_display_mode, :admin_display_mode, :mobile_theme_id)
        end

        def apply_updates(preference, updates)
          errors = []

          if updates.key?(:account_display_mode)
            value = updates[:account_display_mode].to_s
            if Themes::Policy.mode_ids(:account).include?(value)
              preference.set_display_mode(:account, value)
            else
              errors << "account_display_mode"
            end
          end

          if updates.key?(:admin_display_mode)
            value = updates[:admin_display_mode].to_s
            if Themes::Policy.mode_ids(:admin).include?(value)
              preference.set_display_mode(:admin, value)
            else
              errors << "admin_display_mode"
            end
          end

          if updates.key?(:mobile_theme_id)
            value = updates[:mobile_theme_id].to_s
            if Themes::Policy.valid_mobile_theme_id?(value)
              preference.set_mobile_theme_id(value)
            else
              errors << "mobile_theme_id"
            end
          end

          errors
        end

        def preference_payload(preference)
          {
            preferences: preference.theme_preferences_payload
          }
        end
      end
    end
  end
end

