# frozen_string_literal: true

class SimplifyAdminRoles < ActiveRecord::Migration[7.1]
  LEGACY_NON_OWNER_ROLES = %w[staff support].freeze

  def up
    execute <<~SQL.squish
      UPDATE admins
      SET role = 'admin'
      WHERE role IN ('staff', 'support')
    SQL

    execute <<~SQL.squish
      UPDATE admin_temple_memberships
      SET role = 'admin'
      WHERE role IN ('staff', 'support')
    SQL

    change_column_default :admins, :role, from: "staff", to: "admin"
    change_column_default :admin_temple_memberships, :role, from: "staff", to: "admin"
  end

  def down
    execute <<~SQL.squish
      UPDATE admins
      SET role = 'staff'
      WHERE role = 'admin'
    SQL

    execute <<~SQL.squish
      UPDATE admin_temple_memberships
      SET role = 'staff'
      WHERE role = 'admin'
    SQL

    change_column_default :admins, :role, from: "admin", to: "staff"
    change_column_default :admin_temple_memberships, :role, from: "admin", to: "staff"
  end
end
