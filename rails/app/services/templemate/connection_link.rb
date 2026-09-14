# frozen_string_literal: true

module Templemate
  # The exact string the TempleMate app expects to scan.
  #
  # mobile/app/tenant/binding.js#parseProductionConnectionLink accepts it only
  # when: scheme is https, origin is exactly ORIGIN, path is PATH_PREFIX
  # followed by a single slug segment, and there is no userinfo, query or
  # fragment. Anything else is rejected as invalid_connection_link.
  module ConnectionLink
    # The platform's origin, deliberately not the temple's.
    #
    # Each client temple gets its own Vue domain, so a tenant domain cannot be
    # the anchor the app trusts -- it changes per client, and one app serves
    # them all. This host is the one part that stays constant, which is what
    # makes pinning it meaningful rather than decorative.
    #
    # It is also not the API origin. The app still talks to the shared Rails
    # backend; this is only where the code points, so that scanning with a
    # phone's own camera lands on the TempleMate page instead of failing.
    #
    # Historical note: this used to be built from request.base_url, with www
    # stripped, because the app compared the origin to its configured
    # apiBaseUrl exactly and nginx serves www.<domain> directly -- a code
    # generated on www was rejected with no visible reason, which is how it
    # failed for the Director's staff on 2026-09-02. Deriving the origin from
    # the request is what created that failure mode; a fixed constant removes
    # the class of bug rather than patching the one host that triggered it.
    ORIGIN = "https://sourcegridlabs.com"
    PATH_PREFIX = "/templemate/connect"
    MODULE_SIZE = 6
    QUIET_ZONE = 2

    # The temple is passed in rather than resolved here. The page already has
    # it -- Account::BaseController has resolved current_temple long before
    # this runs -- and the slug is what the app needs in order to load a temple
    # it was never compiled with.
    def self.for(temple:)
      "#{ORIGIN}#{PATH_PREFIX}/#{temple.slug}"
    end

    # standalone: true keeps the <svg> element (standalone: false omits it and
    # returns bare shapes); the XML prolog it also emits is stripped, since
    # this is inlined into an HTML page rather than served as a document.
    def self.qr_svg(url)
      RQRCode::QRCode.new(url, level: :m).as_svg(
        module_size: MODULE_SIZE,
        offset: QUIET_ZONE * MODULE_SIZE,
        standalone: true,
        use_path: true,
        color: "000",
        fill: "fff",
        viewbox: true,
        svg_attributes: { role: "img" }
      ).sub(/\A<\?xml[^>]*\?>/, "").html_safe
    end
  end
end
