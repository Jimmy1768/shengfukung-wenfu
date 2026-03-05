# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Auth
  class CentralOAuthClient
    class Error < StandardError; end
    class ConfigError < Error; end
    class RequestError < Error; end

    def initialize(
      base_url: ENV["AUTH_BASE_URL"],
      client_id: ENV["AUTH_CLIENT_ID"],
      client_secret: ENV["AUTH_CLIENT_SECRET"],
      open_timeout: 5,
      read_timeout: 10
    )
      @base_url = base_url.to_s.strip
      @client_id = client_id.to_s.strip
      @client_secret = client_secret.to_s.strip
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def configured?
      [@base_url, @client_id, @client_secret].all?(&:present?)
    end

    def start(provider:, return_url:, context: {})
      ensure_configured!

      post_json(
        "/oauth/start",
        {
          provider: provider,
          return_url: return_url,
          client_id: @client_id,
          client_secret: @client_secret,
          context: context
        }
      )
    end

    def exchange(params:)
      ensure_configured!

      post_json(
        "/oauth/token/exchange",
        params.merge(
          client_id: @client_id,
          client_secret: @client_secret
        )
      )
    end

    private

    def ensure_configured!
      return if configured?

      raise ConfigError, "Central auth client is not configured. Set AUTH_BASE_URL, AUTH_CLIENT_ID, AUTH_CLIENT_SECRET."
    end

    def post_json(path, payload)
      uri = URI.join(ensure_trailing_slash(@base_url), path.sub(%r{\A/+}, ""))
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: @open_timeout,
        read_timeout: @read_timeout
      ) do |http|
        http.request(request)
      end

      parse_response!(response)
    rescue JSON::ParserError => e
      raise RequestError, "Central auth returned malformed JSON: #{e.message}"
    rescue StandardError => e
      raise RequestError, "Central auth request failed: #{e.message}"
    end

    def parse_response!(response)
      body = response.body.to_s
      parsed = body.present? ? JSON.parse(body) : {}

      return parsed if response.code.to_i.between?(200, 299)

      message = parsed["error"].presence || parsed["message"].presence || "HTTP #{response.code}"
      raise RequestError, message
    end

    def ensure_trailing_slash(url)
      url.end_with?("/") ? url : "#{url}/"
    end
  end
end
