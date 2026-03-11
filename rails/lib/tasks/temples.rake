# frozen_string_literal: true

require Rails.root.join("db", "seeds", "temples").to_s

namespace :temples do
  desc "Seed or update a temple profile from db/temples/<slug>.yml (defaults to PROJECT_SLUG)"
  task :seed, [:slug] => :environment do |_task, args|
    slug = args[:slug] || AppConstants::Project.slug
    Seeds::Temples.seed(slug:)
  end

  desc "Create or update the minimal temple row from db/temples/<slug>.yml (name + registration periods only)"
  task :bootstrap, [:slug] => :environment do |_task, args|
    slug = args[:slug] || AppConstants::Project.slug
    Seeds::Temples.bootstrap(slug:)
  end

  desc "Remove temple-scoped financial records for a fresh bootstrap state"
  task :cleanup, [:slug] => :environment do |_task, args|
    slug = args[:slug] || AppConstants::Project.slug
    result = Temples::Cleanup.call(slug:)

    puts(
      "Temple cleanup complete for #{slug}: " \
      "#{result.registrations} registrations, " \
      "#{result.events} events, " \
      "#{result.services} services, " \
      "#{result.gatherings} gatherings removed."
    )
  end
end
