# Api::BaseController
# Base controller for all JSON API endpoints.
# Used by versioned API namespaces (e.g. Api::V1::SomeController).
#
# Responsibilities (to be implemented later):
# - Authentication via JWT / session.
# - Current user lookup.
# - Standard JSON error rendering.
module Api
  class BaseController < ActionController::API
    include TempleContext

    # TODO: add before_action :authenticate_api_user!
    # TODO: add common rescue_from handlers for API errors.
  end
end
