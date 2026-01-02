
# config/initializers/storage_s3.rb
#
# Documents expected environment variables for S3 integration.
#
# Used by Storage::S3Service and any direct S3 clients.
REQUIRED_S3_VARS = %w[S3_BUCKET S3_REGION S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY].freeze

missing = REQUIRED_S3_VARS.select { |key| ENV[key].nil? }
unless missing.empty?
  Rails.logger.info("[S3] Missing S3 env vars: #{missing.join(", ")}")
end
