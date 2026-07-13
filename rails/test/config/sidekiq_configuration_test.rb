# frozen_string_literal: true

require "test_helper"
require "erb"
require "yaml"

class SidekiqConfigurationTest < ActiveSupport::TestCase
  test "configuration renders before Rails boots" do
    path = Rails.root.join("config/sidekiq.yml")
    rendered = Dir.chdir(Rails.root) { ERB.new(path.read).result }
    config = YAML.safe_load(rendered, permitted_classes: [Symbol], aliases: true)

    assert_equal ".", config.fetch(:require)
    assert_equal Profile::Infrastructure::JOB_CONCURRENCY, config.fetch(:concurrency)
    assert_equal Profile::Infrastructure::JobQueues.ordered.map(&:to_s), config.fetch(:queues)
  end
end
