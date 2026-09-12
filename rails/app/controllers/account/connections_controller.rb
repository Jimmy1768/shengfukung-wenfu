# frozen_string_literal: true

module Account
  # Where a patron gets the code the TempleMate app scans.
  #
  # Joining already happened on the web (see TempleConnection); this hands the
  # app the temple identity -- the slug is carried in the code itself, so the
  # app loads this temple rather than whichever one it was built with -- and
  # nothing here needs typing.
  #
  # Required for recovery, not just for multi-temple. The app's "switch temple"
  # control clears the current binding and returns to the scanner, and a
  # reinstall or cleared app data does the same. Without this page there is
  # nowhere to obtain a code, so the patron is stranded at a scanner. Everything
  # starts from the website, and recovery happens there.
  class ConnectionsController < BaseController
    def show
      @connection_url = Templemate::ConnectionLink.for(temple: current_temple)
      @qr_svg = Templemate::ConnectionLink.qr_svg(@connection_url)
    end
  end
end
