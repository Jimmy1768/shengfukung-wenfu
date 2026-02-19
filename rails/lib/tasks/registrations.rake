# frozen_string_literal: true

namespace :registrations do
  desc "Auto-cancel stale unpaid registrations whose hold window expired"
  task expire_unpaid: :environment do
    cancelled = Registrations::PendingExpiryManager.cancel_stale_unpaid!
    puts "Expired unpaid registrations cancelled: #{cancelled}"
  end
end
