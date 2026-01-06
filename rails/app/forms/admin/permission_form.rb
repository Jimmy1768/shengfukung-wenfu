# frozen_string_literal: true

module Admin
  class PermissionForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :admin_account, :temple

    AdminPermission::CAPABILITIES.each do |capability|
      attribute capability, :boolean, default: false
    end

    validates :admin_account, :temple, presence: true

    def initialize(admin_account:, temple:, params: nil)
      @admin_account = admin_account
      @temple = temple
      attributes = params.presence || attributes_from_record
      super(attributes)
    end

    def save(current_admin:)
      return false unless valid?

      record = admin_account.admin_permissions.find_or_initialize_by(temple:)
      AdminPermission::CAPABILITIES.each do |capability|
        record[capability] = public_send(capability)
      end
      record.save!

      SystemAuditLogger.log!(
        action: "admin.permissions.update",
        admin: current_admin,
        target: record,
        metadata: {
          admin_account_id: admin_account.id,
          capabilities: snapshot
        },
        temple:
      )

      true
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    private

    def attributes_from_record
      AdminPermission::CAPABILITIES.index_with do |capability|
        permission_record.public_send(capability)
      end
    end

    def permission_record
      @permission_record ||= admin_account.permissions_for(temple)
    end

    def snapshot
      AdminPermission::CAPABILITIES.index_with { |capability| public_send(capability) }
    end
  end
end
