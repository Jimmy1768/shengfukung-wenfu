require "test_helper"

class AdminLayoutCssTest < ActiveSupport::TestCase
  test "admin stack items use available workspace instead of shrink wrapping" do
    source_css = Rails.root.join("app/stylesheets/admin/_layout.scss").read
    compiled_css = Rails.root.join("public/backend/assets/admin.css").read

    assert_match(/\.admin-stack__row > \.stack-item\s*\{[^}]*width:\s*100%;/m, source_css)
    assert_match(/\.admin-stack__row > \.stack-item\.stack-item--wide\s*\{[^}]*max-width:\s*min\(100%, 960px\);/m, source_css)
    assert_no_match(/\.admin-stack__row > \.stack-item[^}]*fit-content/m, source_css)
    assert_no_match(/\.admin-stack__row > \.stack-item[^}]*fit-content/m, compiled_css)
  end
end
