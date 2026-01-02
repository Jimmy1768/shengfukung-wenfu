# Be sure to restart your server when you modify this file.

# Prevent sensitive parameters from being logged.
# Rails filters these keys out of logs and exception traces.
Rails.application.config.filter_parameters += %i[
  password
  password_confirmation

  token
  access_token
  refresh_token

  api_key
  secret
  otp
  code

  authorization
  auth
  session
  cookie

  firebase_token
  push_token
  device_token

  email_token
  magic_link_token

  # For safety, mask anything that might contain JWTs
  jwt
  id_token
]
