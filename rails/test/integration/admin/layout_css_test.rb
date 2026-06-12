require "test_helper"

class AdminLayoutCssTest < ActiveSupport::TestCase
  test "setup draft form uses droplet-style fluid two-column offering stage" do
    layout_css = Rails.root.join("app/stylesheets/admin/_layout.scss").read
    components_css = Rails.root.join("app/stylesheets/admin/_components.scss").read
    setup_form = Rails.root.join("app/views/admin/offering_setup_drafts/_form.html.erb").read
    gathering_form = Rails.root.join("app/views/admin/gatherings/_form.html.erb").read
    gathering_new = Rails.root.join("app/views/admin/gatherings/new.html.erb").read
    compiled_css = Rails.root.join("public/backend/assets/admin.css").read

    assert_match(/@supports \(width: fit-content\(560px\)\)/, layout_css)
    assert_includes setup_form, 'class: "form-stack stack-item stack-item--fluid"'
    assert_includes setup_form, 'class="offering-form-stage offering-setup-form-stage"'
    assert_includes setup_form, 'class="offering-form-stage__primary"'
    assert_includes setup_form, 'class="offering-form-stage__secondary-list"'
    assert_match(/@media \(min-width: 900px\)\s*\{[^}]*\.offering-form-stage\s*\{[^}]*grid-template-columns:\s*minmax\(360px, 1\.15fr\) minmax\(280px, 0\.9fr\);/m, components_css)
    assert_match(/@media \(min-width: 900px\)\s*\{[^}]*\.offering-form-stage\s*\{[^}]*grid-template-columns:\s*minmax\(360px, 1\.15fr\) minmax\(280px, 0\.9fr\);/m, compiled_css)

    assert_includes gathering_form, 'class: "form-stack stack-item stack-item--fluid gathering-form"'
    assert_includes gathering_form, 'class="offering-form-stage gathering-form-stage"'
    assert_includes gathering_form, 'class="offering-form-stage__primary"'
    assert_includes gathering_form, 'class="offering-form-stage__secondary-list"'
    assert_match(/<section class="card stack-item stack-item--wide">[\s\S]*<\/section>\s*<\/div>\s*\n\s*<div class="admin-stack__row">\s*<%= render "form", gathering: @gathering %>/, gathering_new)
    assert_includes components_css, ".gathering-form-stage"
    assert_includes compiled_css, ".gathering-form-stage"
  end
end
