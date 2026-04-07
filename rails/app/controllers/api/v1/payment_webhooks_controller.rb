# frozen_string_literal: true

module Api
  module V1
    class PaymentWebhooksController < ActionController::API
      def create
        payload = webhook_payload
        temple = resolve_temple(payload)
        return render_webhook_error("temple_not_found", status: :unprocessable_entity) unless temple

        result = Payments::WebhookIngestService.new.call(
          temple: temple,
          provider: params[:provider],
          payload: payload,
          headers: webhook_headers
        )

        render_webhook_success(result)
      rescue Payments::WebhookIngestService::InvalidWebhookSignature => e
        render_webhook_error("invalid_signature", detail: e.message, status: :unauthorized)
      rescue ArgumentError => e
        render_webhook_error("invalid_request", detail: e.message, status: :unprocessable_entity)
      rescue JSON::ParserError => e
        render_webhook_error("invalid_json", detail: e.message, status: :bad_request)
      end

      private

      def webhook_payload
        raw_body = request.raw_post
        parsed =
          if raw_body.present? && request.content_mime_type&.json?
            JSON.parse(raw_body)
          else
            request.request_parameters
          end
        payload = parsed.is_a?(Hash) ? parsed.deep_symbolize_keys : {}
        payload[:_raw_body] = raw_body if raw_body.present?
        payload
      end

      def resolve_temple(payload)
        temple_slug = params[:temple].presence ||
          payload[:temple_slug].presence ||
          payload.dig(:metadata, :temple_slug).presence
        return nil if temple_slug.blank?

        Temple.find_by(slug: temple_slug)
      end

      def webhook_headers
        request.headers
          .to_h
          .select { |key, _| key.start_with?("HTTP_") || %w[CONTENT_TYPE CONTENT_LENGTH].include?(key) }
          .transform_values(&:to_s)
      end

      def ecpay_provider?
        params[:provider].to_s == "ecpay"
      end

      def render_webhook_success(result)
        return render plain: "1|OK" if ecpay_provider?

        render json: {
          ok: true,
          duplicate: result.duplicate,
          payment_id: result.payment&.id,
          event_log_id: result.event_log&.id
        }
      end

      def render_webhook_error(code, detail: nil, status:)
        return render plain: "0|#{code}", status: status if ecpay_provider?

        render json: { error: code, detail: detail }, status: status
      end
    end
  end
end
