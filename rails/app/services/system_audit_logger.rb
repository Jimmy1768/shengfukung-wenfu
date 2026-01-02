# frozen_string_literal: true

class SystemAuditLogger
  def self.log!(action:, admin: nil, target: nil, metadata: {}, temple: nil)
    new(action:, admin:, target:, metadata:, temple:).log!
  end

  def initialize(action:, admin:, target:, metadata:, temple:)
    @action = action
    @admin = admin
    @target = target
    @metadata = metadata
    @temple = temple
  end

  def log!
    SystemAuditLog.create!(
      admin: admin&.admin_account,
      user: admin,
      temple: temple_for_log,
      target: target,
      action: action,
      occurred_at: Time.current,
      metadata: metadata.with_indifferent_access,
      admin_name_snapshot: admin&.english_name || admin&.email || "system",
      user_name_snapshot: admin&.english_name || admin&.email || "system"
    )
  end

  private

  attr_reader :action, :admin, :target, :metadata, :temple

  def temple_for_log
    return temple if temple.present?
    return target.temple if target.respond_to?(:temple)

    nil
  end
end
