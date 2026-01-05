# frozen_string_literal: true

module Account
  class EventsController < BaseController
    def index
      @upcoming_events = mock_upcoming_events
      @past_events = mock_past_events
    end

    private

    def mock_upcoming_events
      [
        { title: "新春點燈", date: "2026/02/01", status: "已報名", location: "主殿", notes: "九點報到" },
        { title: "祈福法會", date: "2026/03/15", status: "報名中", location: "禮堂", notes: "家人可同行" }
      ]
    end

    def mock_past_events
      [
        { title: "歲末感恩", date: "2025/12/20", gallery: true },
        { title: "祖師聖誕", date: "2025/09/05", gallery: false }
      ]
    end
  end
end
