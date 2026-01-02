
# config/initializers/brevo.rb
#
# Placeholder for Brevo (Sendinblue) configuration.
#
# Expects:
# - BREVO_API_KEY
#
# Implementation for a Brevo client can be added here when wiring real emails.
if ENV["BREVO_API_KEY"].nil?
  Rails.logger.info("[Brevo] BREVO_API_KEY is not set; Brevo email client is not configured.")
end
