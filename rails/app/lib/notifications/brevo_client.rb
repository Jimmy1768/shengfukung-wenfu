# app/lib/notifications/brevo_client.rb
#
# Notifications::BrevoClient
# ------------------------------------------------------------------
# Pure transport-layer adapter for Brevo HTTP API.
# - No DB writes
# - No business logic
# - No identity details inside this file
#
# It reads:
# - sender identity from Notifications::EmailConfig
#
# Business-level orchestration (building subjects, bodies, templates)
# happens in:
#   app/services/notifications/send_email_delivery.rb
#

require "httparty"
require "socket"
require "net/http"

module Notifications
  class BrevoClient
    include HTTParty
    base_uri "https://api.brevo.com/v3"

    DEFAULT_TOTAL_TIMEOUT = 5
    DEFAULT_OPEN_TIMEOUT  = 3
    DEFAULT_READ_TIMEOUT  = 5

    def initialize
      @api_key = ENV["BREVO_API_KEY"]
      raise "Missing BREVO_API_KEY" if @api_key.blank?
    end

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------
    def send_email(to:, subject:, html:, sender_name:, sender_email:)
      payload = {
        sender:      { name: sender_name, email: sender_email },
        to:          normalize_recipients(to),
        subject:     subject,
        htmlContent: html
      }

      with_retries do
        if force_ipv4?
          Rails.logger.info "[Brevo] Using IPv4 fallback"
          response = post_json_ipv4("/v3/smtp/email", payload)
        else
          response = self.class.post(
            "/smtp/email",
            headers: default_headers,
            body:    payload.to_json,
            timeout: total_timeout,
            open_timeout: open_timeout,
            read_timeout: read_timeout
          )
        end

        Rails.logger.debug "[Brevo] Response: #{response.code} #{response.body.to_s[0..200]}"
        response.code.to_i == 201
      end
    end

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------
    private

    def default_headers
      {
        "api-key"      => @api_key,
        "Content-Type" => "application/json",
        "accept"       => "application/json"
      }
    end

    def normalize_recipients(to)
      case to
      when String then [{ email: to, name: to }]
      when Hash   then [to]
      when Array  then to.map { |r| r.is_a?(String) ? { email: r, name: r } : r }
      else
        raise ArgumentError, "Unsupported recipient type: #{to.class}"
      end
    end

    def with_retries(max: 3, backoff: 0.5)
      attempts = 0
      begin
        attempts += 1
        yield
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ETIMEDOUT, SocketError => e
        if attempts < max
          sleep(backoff * (2 ** (attempts - 1)))
          retry
        else
          Rails.logger.error "[Brevo] Timeout after #{attempts} attempts: #{e.class}: #{e.message}"
          false
        end
      end
    end

    # ------------------------------------------------------------------
    # Fallback: Force IPv4 route (digital ocean sometimes requires this)
    # ------------------------------------------------------------------
    def post_json_ipv4(path, payload)
      host = "api.brevo.com"
      ipv4 = Addrinfo.getaddrinfo(host, nil, :INET).first&.ip_address
      raise "No IPv4 found for #{host}" unless ipv4

      Net::HTTP.start(
        host, 443,
        ipaddr: ipv4,
        use_ssl: true,
        open_timeout: open_timeout,
        read_timeout: read_timeout
      ) do |http|
        request = Net::HTTP::Post.new(path)
        request["api-key"]      = @api_key
        request["Content-Type"] = "application/json"
        request["accept"]       = "application/json"
        request.body = payload.to_json
        http.request(request)
      end
    end

    def force_ipv4?
      ActiveModel::Type::Boolean.new.cast(ENV["BREVO_FORCE_IPV4"])
    end

    def total_timeout
      (ENV["BREVO_TOTAL_TIMEOUT"] || DEFAULT_TOTAL_TIMEOUT).to_f
    end

    def open_timeout
      (ENV["BREVO_OPEN_TIMEOUT"] || DEFAULT_OPEN_TIMEOUT).to_f
    end

    def read_timeout
      (ENV["BREVO_READ_TIMEOUT"] || DEFAULT_READ_TIMEOUT).to_f
    end
  end
end
