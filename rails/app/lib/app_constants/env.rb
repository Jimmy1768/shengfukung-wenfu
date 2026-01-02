# frozen_string_literal: true

module AppConstants
  module Env
    LOCAL_PREFIX = ".env".freeze
    DEFAULT_ENV = "development".freeze

    # Example: `.env.development`
    def self.filename_for(env = ENV.fetch("RAILS_ENV", DEFAULT_ENV))
      "#{LOCAL_PREFIX}.#{env}"
    end

    def self.local
      filename_for
    end

    def self.credentials_path
      "config/credentials.yml.enc"
    end
  end
end
