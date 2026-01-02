# frozen_string_literal: true

require Rails.root.join("db", "seeds", "temples").to_s

namespace :temples do
  desc "Seed or update a temple profile from db/temples/<slug>.yml (defaults to PROJECT_SLUG)"
  task :seed, [:slug] => :environment do |_task, args|
    slug = args[:slug] || AppConstants::Project.slug
    Seeds::Temples.seed(slug:)
  end
end
