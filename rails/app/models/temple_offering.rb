# frozen_string_literal: true

class TempleOffering < TempleEvent
  # Maintain legacy naming so existing helpers/routes keep working while the
  # admin console migrates to TempleEvent/TempleService.
  def self.table_name = "temple_events"

  def self.model_name
    ActiveModel::Name.new(self, nil, "Offering")
  end
end
