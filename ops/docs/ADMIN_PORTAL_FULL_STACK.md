# Admin Portal Full-Stack Rework

This note captures the changes needed so Golden Template apps (and shenfukung-wenfu) can ship an HTML admin portal without bolting on one-off fixes. Copy this file to the template repo so every future project starts from the same baseline.

## Why this change?

- The template still boots Rails in `api_only` mode, so Rack::MethodOverride, CSRF handling, helper modules, and asset helpers are absent by default.
- Admin pages already rely on form submissions, flash messages, uploads, and layouts. Re-adding middleware piecemeal is brittle and leads to regressions for non-GET actions.
- We need a sanctioned way to serve both JSON APIs and HTML admin dashboards from the same codebase, with clear controller boundaries.

## Target architecture

1. **Rails configuration**
   - Set `config.api_only = false` in `config/application.rb` so the full middleware stack (method override, forgery protection, conditional get, etc.) loads automatically.
   - Keep the explicit cookie/session/flash/static middleware plus `ApiProtection::AuditMiddleware` that the template already adds.
   - Ensure `config.session_store` remains defined and `config.action_controller.default_protect_from_forgery = true` (default when api_only is false).
2. **Controller hierarchy**
   - Make `ApplicationController < ActionController::Base`, enabling layouts, helpers, cookies, and CSRF tokens for HTML surfaces.
   - Add `Api::BaseController < ActionController::API` and update all API namespaces to inherit from it (`skip_forgery_protection`, JSON defaults, shared auth helpers).
   - Add `Admin::BaseController < ApplicationController` that enforces admin auth, loads the admin layout, and keeps HTML defaults intact.
3. **Routing defaults**
   - Group API routes under `/api` (or the existing namespace) with `defaults format: :json`.
   - Group admin routes under `/admin`, `defaults format: :html`, and point them at controllers inheriting from `Admin::BaseController`.
4. **Assets + frontend helpers**
   - Re-enable the asset pipeline (`sprockets-rails` or propshaft) in the template Gemfile and add an admin entry point (CSS + JS) so `stylesheet_link_tag`/`javascript_include_tag` work.
   - Add an admin layout (`app/views/layouts/admin.html.erb`) that includes CSRF meta tags, flash display, and the compiled assets.
   - Provide a lightweight JS entry that loads `@rails/ujs` or Turbo so method-override form submissions behave consistently.
5. **CSRF, sessions, and method override**
   - With `api_only = false`, Rails injects authenticity tokens into forms and honors `_method` hidden inputs for PATCH/DELETE.
   - Keep CSRF protection enabled for admin controllers (`protect_from_forgery with: :exception`). API controllers should continue using token auth and `skip_forgery_protection`.
6. **Testing**
   - Add request or system specs that submit an admin form with `_method: :patch` and expect a successful update (proves method override + CSRF work).
   - Add specs ensuring API controllers still behave statelessly (e.g., POST without cookies still succeeds, CSRF not enforced).

## Implementation steps

1. Update `config/application.rb` and `config/environments/*` as needed when `api_only` is false (e.g., asset config, generators).
2. Introduce the new controller hierarchy and update existing controllers to inherit from the appropriate base class.
3. Restore asset pipeline dependencies/config, create admin layout/assets, and wire them into the manifest (`config/initializers/assets.rb`).
4. Adjust routes to clearly separate `/admin` HTML routes from `/api` JSON routes.
5. Add/adjust specs covering both surfaces.
6. Document the pattern here and in Golden Template so all new services follow it.

## Rollout plan

1. Apply these changes in the Golden Template repository first so new projects start with the correct defaults.
2. Mirror the same edits in shenfukung-wenfu (and any existing apps) once the template is merged.
3. Verify deployments by:
   - Submitting a PATCH/DELETE form in the admin UI without console errors.
   - Hitting an API endpoint to confirm JSON behavior is unchanged.
4. Share this note with the Golden Template team so they understand the rationale and can review the refactor holistically.

## Golden Template handoff prompt

```
Team – please read ops/docs/ADMIN_PORTAL_FULL_STACK.md in this repo. It summarizes why the template should drop pure API mode, how to split controllers, and what assets/routes/tests we need so HTML admin flows behave correctly. Once the refactor lands in Golden Template, we’ll mirror the same changes here.
```
