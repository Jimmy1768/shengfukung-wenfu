class SystemAuditLog < ApplicationRecord
  belongs_to :admin_account,
    class_name: "AdminAccount",
    foreign_key: :admin_id,
    optional: true
  belongs_to :user, optional: true
  belongs_to :temple, optional: true
  belongs_to :target, polymorphic: true, optional: true

  validates :action, :occurred_at, presence: true

  alias_method :admin, :admin_account
  alias_method :admin=, :admin_account=
end
