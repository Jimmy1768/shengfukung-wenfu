# TurboModal
# Shared concern for controllers that use Turbo Streams to control
# a modal + main content layout.
#
# Assumes there are DOM elements with IDs:
# - "modal": container for the modal dialog.
# - "main":  main content area to be replaced.
#
# Usage:
# - Include in UiGatewayController (and therefore in any HTML controller) when Turbo modal wiring is needed.
# - Call turbo_close_and_replace_main_with("path/to/template")
module TurboModal
  extend ActiveSupport::Concern

  def turbo_close_and_replace_main_with(template_path)
    # Force HTML view, WITHOUT layout, so we don’t nest the main layout.
    html = render_to_string(template: template_path, formats: [:html], layout: false)

    render turbo_stream: [
      turbo_stream.update("modal", ""),        # close modal
      turbo_stream.replace("main", html: html) # refresh main pane
    ]
  end
end
