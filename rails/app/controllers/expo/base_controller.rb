# Expo::BaseController
# Base controller for endpoints that configure the "app layer" (Expo / mobile).
# Examples:
# - Serving feature flags or app configuration.
# - Providing metadata used during app startup.
module Expo
  class BaseController < ApplicationController
    # TODO: add helpers for app-specific auth / configuration.
  end
end
