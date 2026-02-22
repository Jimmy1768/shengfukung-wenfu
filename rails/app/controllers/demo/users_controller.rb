module Demo
  class UsersController < BaseController
    def index
      data = I18n.t("demo_admin.users", default: {})
      @users = Array.wrap(data[:entries])
      @user_actions = Array.wrap(data[:actions])
      @last_active_prefix = data[:last_active_prefix] || "Last active"
      @staff_count = @users.count { |user| user[:status].to_s.downcase == "active" }
    end
  end
end
