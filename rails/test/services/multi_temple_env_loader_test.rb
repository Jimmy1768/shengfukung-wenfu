# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "json"
require Rails.root.join("lib/multi_temple_env_loader")

class MultiTempleEnvLoaderTest < ActiveSupport::TestCase
  class FakeDotenv
    attr_reader :loaded, :overloaded

    def initialize
      @loaded = []
      @overloaded = []
    end

    def load(path)
      loaded << path
    end

    def overload(path)
      overloaded << path
    end
  end

  def setup
    @tmp_root = Pathname.new(Dir.mktmpdir("multi-temple-env-loader"))
    write_json(@tmp_root.join("shared/app_constants/project.json"), { slug: "alpha" })
  end

  def teardown
    FileUtils.remove_entry(@tmp_root) if @tmp_root&.exist?
  end

  test "loads temple override when env file exists" do
    write_file(@tmp_root.join(".env"))
    write_file(@tmp_root.join(".env.test"))
    write_file(@tmp_root.join("etc/default/alpha.env"))

    dotenv = FakeDotenv.new
    MultiTempleEnvLoader.load!(dotenv:, env: {}, rails_env: "test", root: @tmp_root)

    assert_includes dotenv.loaded, @tmp_root.join(".env").to_s
    assert_includes dotenv.loaded, @tmp_root.join(".env.test").to_s
    assert_equal [@tmp_root.join("etc/default/alpha.env").to_s], dotenv.overloaded
  end

  test "falls back to .env.development when temple file is missing" do
    write_file(@tmp_root.join(".env"))
    write_file(@tmp_root.join(".env.test"))
    write_file(@tmp_root.join(".env.development"))

    dotenv = FakeDotenv.new
    MultiTempleEnvLoader.load!(dotenv:, env: {}, rails_env: "test", root: @tmp_root)

    assert_equal [@tmp_root.join(".env.development").to_s], dotenv.overloaded
  end

  test "prefers explicit TEMPLE_SLUG env" do
    write_file(@tmp_root.join(".env"))
    write_file(@tmp_root.join(".env.test"))
    write_file(@tmp_root.join("etc/default/beta.env"))

    dotenv = FakeDotenv.new
    MultiTempleEnvLoader.load!(dotenv:, env: { "TEMPLE_SLUG" => "beta" }, rails_env: "test", root: @tmp_root)

    assert_equal [@tmp_root.join("etc/default/beta.env").to_s], dotenv.overloaded
  end

  private

  def write_file(path, contents = "")
    FileUtils.mkdir_p(path.dirname)
    path.write(contents)
  end

  def write_json(path, payload)
    write_file(path, JSON.dump(payload))
  end
end
