# frozen_string_literal: true

require "net/http"
require "json"
require "cgi"

module Maps
  class PlaceDetailsFetcher
    class Error < StandardError; end

    FIND_PLACE_ENDPOINT = URI("https://maps.googleapis.com/maps/api/place/findplacefromtext/json").freeze
    PLACE_DETAILS_ENDPOINT = URI("https://maps.googleapis.com/maps/api/place/details/json").freeze

    def initialize(input)
      @input = input.to_s.strip
      @api_key = ENV["GOOGLE_MAPS_API_KEY"]
    end

    def call
      raise Error, "缺少 GOOGLE_MAPS_API_KEY，請先設定環境變數。" if api_key.blank?
      raise Error, "請輸入有效的 Google Maps 連結。" if input.blank?

      place_id = find_place_id
      raise Error, "找不到對應的 Google Maps 位置，請確認連結是否正確。" if place_id.blank?

      details_zh = fetch_details(place_id, language: "zh-TW")
      details_en = fetch_details(place_id, language: "en")

      {
        address_zh: details_zh.dig("result", "formatted_address"),
        address_en: details_en.dig("result", "formatted_address"),
        plus_code: details_zh.dig("result", "plus_code", "global_code") || details_en.dig("result", "plus_code", "global_code"),
        map_url: details_zh.dig("result", "url") || details_en.dig("result", "url") || resolved_input,
        latitude: details_zh.dig("result", "geometry", "location", "lat"),
        longitude: details_zh.dig("result", "geometry", "location", "lng"),
        place_id: place_id
      }
    end

    private

    attr_reader :input, :api_key

    def resolved_input
      @resolved_input ||= begin
        uri = URI.parse(input)
        expand_google_short_link(uri) || input
      rescue URI::InvalidURIError
        input
      end
    end

    def search_input
      @search_input ||= begin
        uri = URI.parse(resolved_input)
        extract_google_hint(uri) || resolved_input
      rescue URI::InvalidURIError
        resolved_input
      end
    end

    def find_place_id
      response = perform_request(
        FIND_PLACE_ENDPOINT,
        input: search_input,
        inputtype: "textquery",
        fields: "place_id"
      )
      candidates = response["candidates"] || []
      candidates.first&.dig("place_id")
    end

    def fetch_details(place_id, language: "zh-TW")
      perform_request(
        PLACE_DETAILS_ENDPOINT,
        place_id: place_id,
        language: language,
        fields: "formatted_address,plus_code,geometry,url",
        key: api_key
      )
    end

    def perform_request(uri, params = {})
      query = URI.encode_www_form({ key: api_key }.merge(params))
      request_uri = uri.dup
      request_uri.query = query

      response = Net::HTTP.get_response(request_uri)
      raise Error, "Google Maps API 無回應，請稍後再試。" unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      status = data["status"]
      if status != "OK"
        message = data["error_message"] || data["status"] || "未知錯誤"
        raise Error, "Google Maps API 錯誤：#{message}"
      end
      data
    rescue JSON::ParserError
      raise Error, "無法解析 Google Maps 回應，請稍後再試。"
    end

    GOOGLE_SHORT_HOST = "maps.app.goo.gl"
    MAX_REDIRECTS = 5

    def expand_google_short_link(uri)
      return unless uri.host&.end_with?(GOOGLE_SHORT_HOST)

      current_uri = uri
      MAX_REDIRECTS.times do
        response = Net::HTTP.get_response(current_uri)
        case response
        when Net::HTTPRedirection
          location = response["location"]
          break if location.blank?

          new_uri = URI.parse(location)
          new_uri = current_uri + location if new_uri.relative?
          current_uri = new_uri
          next
        when Net::HTTPSuccess
          return response.uri ? response.uri.to_s : current_uri.to_s
        else
          break
        end
      rescue StandardError
        break
      end
      nil
    end

    GOOGLE_MAP_HOST_PATTERN = /(^|\.)google\./.freeze

    def extract_google_hint(uri)
      return unless uri.host&.match?(GOOGLE_MAP_HOST_PATTERN)

      hint_from_query(uri) || hint_from_path(uri)
    end

    def hint_from_query(uri)
      query_params = CGI.parse(uri.query.to_s)
      %w[q query destination].each do |key|
        next unless query_params[key]&.first.present?

        return decode_hint(query_params[key].first)
      end
      nil
    end

    def hint_from_path(uri)
      path = uri.path.to_s
      if path.include?("/maps/place/")
        segment = path.split("/maps/place/").last
        token = segment.split("/").first
        return decode_hint(token)
      elsif path.include?("/maps/search/")
        segment = path.split("/maps/search/").last
        token = segment.split("/").first
        return decode_hint(token)
      end
      nil
    end

    def decode_hint(value)
      decoded = CGI.unescape(value.to_s).tr("+", " ").strip
      decoded unless decoded.empty?
    end
  end
end
