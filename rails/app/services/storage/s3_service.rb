
# app/services/storage/s3_service.rb
#
# Wrapper around S3 (or compatible) storage.
# This service is responsible for:
# - Generating presigned URLs for direct uploads/downloads.
# - (Optionally) performing server-side uploads or deletions.
#
# NOTE:
# - Backed by environment variables for bucket, region, and credentials.
# - Implementation can reuse your existing, working S3 code.
module Storage
  class S3Service
    # Example accessors for configuration (fill in as needed).
    # def self.client
    #   @client ||= Aws::S3::Client.new(
    #     region: ENV["S3_REGION"],
    #     access_key_id: ENV["S3_ACCESS_KEY_ID"],
    #     secret_access_key: ENV["S3_SECRET_ACCESS_KEY"]
    #   )
    # end

    # def self.bucket
    #   ENV.fetch("S3_BUCKET") { "change-me" }
    # end

    # Returns a presigned URL for uploading a file.
    # @param key [String] object key/path
    # @param expires_in [Integer] seconds until expiration
    # @return [String] presigned URL
    def self.presigned_upload_url(key:, expires_in: 15 * 60)
      # TODO: implement using Aws::S3::Presigner
      raise NotImplementedError, "Storage::S3Service.presigned_upload_url is not implemented yet"
    end

    # Returns a presigned URL for downloading a file.
    def self.presigned_download_url(key:, expires_in: 15 * 60)
      # TODO: implement using Aws::S3::Presigner
      raise NotImplementedError, "Storage::S3Service.presigned_download_url is not implemented yet"
    end

    # Deletes an object at the given key.
    def self.delete(key:)
      # TODO: implement object deletion
      raise NotImplementedError, "Storage::S3Service.delete is not implemented yet"
    end
  end
end
