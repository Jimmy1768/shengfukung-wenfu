# frozen_string_literal: true

class UserPreference < ApplicationRecord
  belongs_to :user

  before_validation :apply_defaults

  class << self
    def for_user(user)
      find_or_create_by!(user:) do |preference|
        preference.apply_defaults
      end
    end
  end

  def display_mode_for(surface)
    metadata.to_h.dig("display_modes", surface.to_s).presence
  end

  def set_display_mode(surface, mode_id)
    data = metadata_payload
    display_modes = (data["display_modes"] || {}).deep_dup
    display_modes[surface.to_s] = mode_id.to_s
    data["display_modes"] = display_modes
    self.metadata = data
  end

  def mobile_theme_id
    metadata_payload["mobile_theme_id"].presence
  end

  def set_mobile_theme_id(theme_id)
    data = metadata_payload
    data["mobile_theme_id"] = theme_id.to_s
    self.metadata = data
  end

  def theme_preferences_payload
    {
      account_display_mode: display_mode_for(:account),
      admin_display_mode: display_mode_for(:admin),
      mobile_theme_id:
    }.compact
  end

  def apply_defaults
    self.locale = self.class.column_defaults["locale"] if locale.blank?
    self.timezone = self.class.column_defaults["timezone"] if timezone.blank?
    self.currency = self.class.column_defaults["currency"] if currency.blank?
    self.theme = self.class.column_defaults["theme"] if theme.blank?
    self.temperature_unit = self.class.column_defaults["temperature_unit"] if temperature_unit.blank?
    self.measurement_system = self.class.column_defaults["measurement_system"] if measurement_system.blank?
    self.twenty_four_hour_time = false if twenty_four_hour_time.nil?
    self.metadata = {} if metadata.blank?
  end

  private

  def metadata_payload
    (metadata || {}).deep_dup
  end
end
