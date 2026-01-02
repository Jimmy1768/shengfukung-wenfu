# frozen_string_literal: true

module AppConstants
  module Sessions
    module_function

    def key(scope)
      case scope.to_s
      when "admin", "real_admin"
        :admin_user_id
      when "demo", "marketing_admin"
        :demo_admin_user_id
      when "user", "account"
        :user_id
      else
        "#{scope}_session".to_sym
      end
    end
  end
end
