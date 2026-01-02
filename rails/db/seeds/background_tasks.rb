# frozen_string_literal: true

# frozen_string_literal: true

module Seeds
  module BackgroundTasks
    extend self

    def seed
      puts "Seeding background task registry..." # rubocop:disable Rails/Output
      BackgroundTask.find_or_initialize_by(task_key: "seed:cache-refresh").tap do |task|
        task.status = "queued"
        task.queue_name = "default"
        task.attempts = 1
        task.scheduled_at = 5.minutes.from_now
        task.payload = { reason: "seed job" }
        task.metadata = seed_metadata
        task.save! if task.changed?
      end
    end

    private

    def seed_metadata
      {
        seeded_at: Time.current.iso8601,
        seeded_by: "db:seed:background_tasks"
      }
    end
  end
end
