# frozen_string_literal: true

class AddAccountLinkingFieldsToOAuthIdentities < ActiveRecord::Migration[7.1]
  def up
    add_column :oauth_identities, :email_verified, :boolean
    add_column :oauth_identities, :linked_at, :datetime
    add_column :oauth_identities, :last_login_at, :datetime

    add_index :oauth_identities, :last_login_at

    execute <<~SQL
      UPDATE oauth_identities
      SET linked_at = COALESCE(linked_at, created_at, CURRENT_TIMESTAMP),
          last_login_at = COALESCE(last_login_at, updated_at, created_at, CURRENT_TIMESTAMP)
    SQL
  end

  def down
    remove_index :oauth_identities, :last_login_at

    remove_column :oauth_identities, :last_login_at
    remove_column :oauth_identities, :linked_at
    remove_column :oauth_identities, :email_verified
  end
end
