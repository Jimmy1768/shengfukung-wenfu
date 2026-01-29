
module Storage
  class S3Service
    class << self
      def upload(io:, key:, content_type: nil)
        storage_key = namespaced_key(key)
        io.rewind if io.respond_to?(:rewind)
        client.put_object(
          bucket: bucket,
          key: storage_key,
          body: io,
          content_type: content_type
        )
        storage_key
      end

      def delete(key:)
        storage_key = namespaced_key(key)
        client.delete_object(bucket:, key: storage_key)
      end

      def public_url(key)
        storage_key = namespaced_key(key)
        base = ENV["S3_PUBLIC_BASE_URL"].presence
        return "#{base}/#{storage_key}" if base

        "https://#{bucket}.s3.#{region}.amazonaws.com/#{storage_key}"
      end

      private

      def client
        @client ||= Aws::S3::Client.new(
          region: region,
          access_key_id: ENV["S3_ACCESS_KEY_ID"],
          secret_access_key: ENV["S3_SECRET_ACCESS_KEY"]
        )
      end

      def region
        ENV.fetch("S3_REGION") { raise "S3_REGION is not configured" }
      end

      def bucket
        ENV.fetch("S3_BUCKET") { raise "S3_BUCKET is not configured" }
      end

      def object_prefix
        ENV["S3_OBJECT_PREFIX"].to_s
      end

      def namespaced_key(key)
        raw = key.to_s
        prefix = object_prefix
        return raw if prefix.blank?

        normalized_prefix = prefix.end_with?("/") ? prefix : "#{prefix}/"
        return raw if raw.start_with?(normalized_prefix) || raw == prefix

        File.join(prefix, raw)
      end
    end
  end
end
