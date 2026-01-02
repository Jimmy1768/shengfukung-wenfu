# Dev::BaseController
# Base controller for the internal dev console.
# Accessible only to dev / operator users.
module Dev
  class BaseController < UiGatewayController
    # TODO: add before_action :require_dev! to restrict access.
  end
end
