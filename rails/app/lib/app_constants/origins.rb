# frozen_string_literal: true

module AppConstants
  module Origins
    DEV_MARKETING_ORIGIN = "http://localhost:5173/marketing".freeze
    DEV_ADMIN_ORIGIN = "http://localhost:3002/marketing/admin".freeze

    PROD_MARKETING_FALLBACK = "/marketing".freeze
    PROD_ADMIN_FALLBACK = "/marketing/admin".freeze

    def self.marketing_origin
      configured_origin("PROJECT_MARKETING_ORIGIN", DEV_MARKETING_ORIGIN, PROD_MARKETING_FALLBACK)
    end

    def self.admin_origin
      configured_origin("PROJECT_ADMIN_ORIGIN", DEV_ADMIN_ORIGIN, PROD_ADMIN_FALLBACK)
    end

    def self.marketing_url(path: "/")
      build_url(marketing_origin, path, ensure_trailing_slash: true)
    end

    def self.admin_url(path: "/")
      build_url(admin_origin, path)
    end

    def self.configured_origin(env_key, dev_value, prod_value)
      env_value = ENV[env_key]
      return env_value if env_value.present?
      return dev_value if Rails.env.development?

      prod_value
    end

    def self.build_url(origin, path, ensure_trailing_slash: false)
      base = origin.to_s.sub(%r{/+$}, "")
      suffix =
        if path.nil? || path == "" || path == "/"
          ""
        elsif path.start_with?("?", "#")
          path
        else
          "/#{path.to_s.sub(%r{^/+}, "")}"
        end
      if suffix == ""
        return base.end_with?("/") || !ensure_trailing_slash ? base : "#{base}/"
      end

      combined = "#{base}#{suffix}"
      combined.present? ? combined : "/"
    end
  end
end
