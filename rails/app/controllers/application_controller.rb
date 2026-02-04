# ApplicationController
# Base controller for API-style and JSON responses.
# Used by:
# - Api::BaseController
# - App::BaseController
# - UploadsController
# - Other JSON / mobile-facing controllers
#
# NOTE:
# - In the HTML/JSON hybrid stack this inherits from ActionController::Base so
#   layouts, helpers, CSRF protection, and cookies all work by default.
# - Api::BaseController now subclasses ActionController::API for JSON-only
#   surfaces.
class ApplicationController < ActionController::Base
  include Themes::PaletteResolver
  include Forms::LayoutHelper
  include TempleContext

  protect_from_forgery with: :exception

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
