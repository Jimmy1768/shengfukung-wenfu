# frozen_string_literal: true

module Admin
  module PermissionsHelper
    CAPABILITY_LABELS = {
      manage_offerings: "Manage offerings",
      manage_registrations: "Manage registrations",
      record_cash_payments: "Record cash payments",
      view_financials: "View financial summaries",
      export_financials: "Export ledgers",
      view_guest_lists: "View guest lists",
      manage_permissions: "Manage permissions"
    }.freeze

    CAPABILITY_HINTS = {
      manage_offerings: "Create and edit offerings shown on the site.",
      manage_registrations: "Access registration records and onsite orders.",
      record_cash_payments: "Record offline/cash payments for orders.",
      view_financials: "See payment history and dashboard totals.",
      export_financials: "Download CSV exports of payments and ledgers.",
      view_guest_lists: "View attendee rosters for onsite events.",
      manage_permissions: "Grant or revoke staff access levels."
    }.freeze

    def capability_label(capability)
      CAPABILITY_LABELS.fetch(capability) { capability.to_s.humanize }
    end

    def capability_hint(capability)
      CAPABILITY_HINTS[capability]
    end
  end
end
