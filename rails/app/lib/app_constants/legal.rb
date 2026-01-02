# frozen_string_literal: true

module AppConstants
  module Legal
    DEFAULT_TERMS_VERSION = "2024-01-01".freeze

    def self.default_terms_version
      ENV.fetch("PROJECT_TERMS_VERSION", DEFAULT_TERMS_VERSION)
    end
  end
end
