module Account
  class DashboardController < BaseController
    def index
      @upcoming_items = [
        { title: "Welcome tour", body: "Replace this section with upcoming bookings or tasks." },
        { title: "Billing status", body: "Show invoices, usage, or subscription info here." }
      ]
    end
  end
end
