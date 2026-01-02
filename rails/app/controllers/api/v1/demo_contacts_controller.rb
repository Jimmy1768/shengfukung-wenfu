module Api
  module V1
    class DemoContactsController < Api::BaseController
      def create
        sender = Contact::DemoInquirySender.new(
          email: params[:email],
          name: params[:name],
          locale_code: params[:locale],
          message: params[:message],
          metadata: enriched_metadata
        )

        result = sender.call

        if result.success?
          render json: {
            message: I18n.t(
              "demo_admin.contact.demo_auto_reply.confirmation",
              locale: result.locale_key,
              email: params[:email]
            )
          }, status: :created
        else
          render json: { error: error_message(result) }, status: :unprocessable_entity
        end
      end

      private

      def enriched_metadata
        # Combine browser-supplied metadata with trusted request facts so admins
        # see both perspectives in the notification email.
        raw_metadata = safe_hash(params[:metadata])
        client_meta = safe_hash(raw_metadata[:client])
        server_meta = safe_hash(raw_metadata[:server])

        server_enrichment = {
          remote_ip: request.remote_ip,
          geo_country: safe_location_value(:country),
          geo_region: safe_location_value(:state),
          request_id: request.request_id,
          referer: request.referer,
          user_agent: request.user_agent
        }

        {
          client: client_meta,
          server: server_meta.merge(server_enrichment) { |_key, original_value, enriched_value| enriched_value.presence || original_value }
        }
      end

      def safe_location_value(attribute)
        return nil unless request.respond_to?(:location)

        location = request.location
        return nil unless location

        location.public_send(attribute)
      rescue StandardError
        nil
      end

      def safe_hash(value)
        return {} if value.blank?

        if value.respond_to?(:to_unsafe_h)
          value.to_unsafe_h
        elsif value.respond_to?(:to_h)
          value.to_h
        else
          value
        end
      rescue StandardError
        {}
      end

      def error_message(result)
        error_key = result.error_code || :generic
        I18n.t(
          "demo_admin.contact.demo_auto_reply.errors.#{error_key}",
          locale: result.locale_key,
          default: I18n.t("demo_admin.contact.demo_auto_reply.errors.generic", locale: result.locale_key)
        )
      end
    end
  end
end
