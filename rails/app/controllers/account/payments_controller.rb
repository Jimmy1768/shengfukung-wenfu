# frozen_string_literal: true

module Account
  class PaymentsController < BaseController
    def index
      @entries = mock_entries
    end

    private

    def mock_entries
      [
        { code: "LF-202601", title: "新春點燈", amount: 1200, status: "paid", date: "2026/01/02", method: "LINE Pay" },
        { code: "EV-202512", title: "歲末感恩", amount: 800, status: "paid", date: "2025/12/18", method: "LINE Pay" },
        { code: "EV-202510", title: "祖師聖誕", amount: 500, status: "refunded", date: "2025/10/02", method: "LINE Pay" }
      ]
    end
  end
end
