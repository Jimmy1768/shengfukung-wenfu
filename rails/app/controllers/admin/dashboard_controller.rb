module Admin
  class DashboardController < BaseController
    def index
      @metrics = [
        { label: "Active members", value: User.count },
        { label: "Pending invites", value: 3 },
        { label: "Revenue (placeholder)", value: "$12.3K" }
      ]
    end
  end
end
