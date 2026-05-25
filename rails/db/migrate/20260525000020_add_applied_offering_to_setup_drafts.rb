# frozen_string_literal: true

class AddAppliedOfferingToSetupDrafts < ActiveRecord::Migration[7.1]
  def change
    add_reference :temple_offering_setup_drafts,
      :applied_offering,
      polymorphic: true,
      index: { name: "idx_offering_setup_drafts_on_applied_target" }
  end
end
