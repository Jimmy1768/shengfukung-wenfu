# UiGatewayController
# Central HTML/Turbo entry point that acts as the home for cross-platform web views.
# Used by:
# - Account::BaseController / Admin::BaseController (browser UI surfaces)
# - Utils::MobileController (deep links + in-app webviews)
#
# Responsibilities:
# - Provides layout rendering (e.g. account/admin layouts)
# - Handles CSRF protection for browser sessions or hybrids.
# - Includes Turbo helpers and the TurboModal concern.
class UiGatewayController < ActionController::Base
  # Include Turbo helpers as needed (when Turbo is wired up).
  # include Turbo::Streams
  # include Turbo::FramesHelper

  # TurboModal is defined in app/controllers/concerns/turbo_modal.rb
  include TurboModal

  # CSRF protection for browser-based requests.
  protect_from_forgery with: :exception

  # Downstream controllers should set their own layouts (account/admin/etc).
  layout false
end
