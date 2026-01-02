# ApplicationController
# Base controller for API-style and JSON responses.
# Used by:
# - Api::BaseController
# - App::BaseController
# - UploadsController
# - Other JSON / mobile-facing controllers
#
# NOTE:
# - In Golden-Template, this inherits from ActionController::API
# - Auth helpers, current_user, JWT handling, etc. will be added later.
class ApplicationController < ActionController::API
  include Themes::PaletteResolver
  include Forms::LayoutHelper

  require Rails.root.join("app/lib/app_constants/emails")

  if respond_to?(:helper)
    helper Themes::PaletteResolver
    helper Forms::LayoutHelper
  end
  if respond_to?(:helper_method)
    helper_method :theme_palette
  end

  # TODO: add authentication helpers (current_user, authenticate_user!, etc.)
  # TODO: add common JSON error handling.
end
