# Account Portal Build Plan

Progress tracking: fill in each `Completed:` line after the section ships and is verified.

## Phase 1 – Theme & Design Foundations

- Keep `/account` aligned with the shared design system: palettes live in `shared/design-system/themes.json` and require `node bin/sync_design_system.js` after edits.
- Ensure each temple’s default theme key lives in `shared/app_constants/project.json` (override via `PROJECT_DEFAULT_THEME_KEY`) so the portal + marketing site stay in sync.
- Maintain the dev-only theme toggle (cookie-driven) so designers can preview alternate looks locally while production locks to the configured theme.
- Use the shared design tokens (colors, typography, spacing, button styles) but build dedicated `/account` layouts/components on top so patron-facing pages aren’t constrained by the admin UI grid.

Completed:
- `/account/temples` (slug selector) renders hero cards per temple and routes the entire card to `/account/login?temple=<slug>`.
- Login + sign-up capture `temple`/`account_action`/`offering` params and store them in the session so post-auth routing can happen in 3B.
- OAuth/email login share the same modal; unauthenticated deep links immediately show the modal atop the background.
- `/account/login` header now mentions the active temple by name so patrons know where they’re signing in.
- Tokens + theme files already power both marketing + account shells, and the account layout (`layouts/account`) loads the shared CSS while rendering its own hero/nav. Dev theme toggle works via `Account::BaseController` + `_dev_toggle`, so Phase 1 is ✅.

## Phase 2 – Rails Account Shell

- `Account::BaseController` must resolve the active theme (cookie in dev, default otherwise) and expose it to `layouts/account`.
- Keep the account layout hero/header in `rails/app/stylesheets/account/account.scss` and verify shared CSS tokens load correctly.
- Retain the `/dev/theme` endpoints used by both Rails and Vue dev toggles so overrides stay consistent across surfaces.

Completed:
- `Account::BaseController` already assigns `@active_theme_key`/`@theme_palette`, handles the dev cookie, and enforces `authenticate_user!`.
- `layouts/account.html.erb` + `app/stylesheets/account/account.scss` define the dedicated shell while importing shared tokens.
- `/dev/theme` remains available for toggling themes locally, so the Rails account surface stays in sync with Vue dev previews.

## Phase 3A – Auth + Entry Experience

- Scope `/account` to authenticated workflows only. Offerings (events/services/gatherings) remain on the public Vue site; patrons tap “Register” there and deep-link into `/account` with the offering slug in tow.
- `/account/login` reuses the same modal for email/password across all entry points; OAuth stays the default path.
- Add `/account/temples` as the neutral landing screen when no temple slug is provided. Cards come from `rails/app/lib/temples/manifest.yml` and link back to each temple’s marketing site + deep-link slug.
- Registration hand-off flow:
  1. Vue deep-links patrons to `/account/login?temple=<slug>&account_action=<event|service|gathering>&offering=<offering_slug>` whenever they tap “Register.”
  2. If the patron isn’t signed in, show the login modal atop the page background; once authenticated, continue the flow.
  3. After login, `Account::RegistrationsController` checks `current_user.temple_event_registrations` for an existing enrollment on that offering. If one exists (one active registration per patron per offering), redirect to the registration detail page so they can view/cancel. Otherwise, render the new-registration form for that offering.
  4. Prefill personal info from `users` table metadata; if they edit those fields, save back to their profile. Offering-specific metadata (ancestor names, dedications) is read-only outside the registration form—patrons view it per registration but admins remain the only editors.
  5. Notes/comments stay admin-only for now; patrons don’t see or edit them.
  6. Lock edits once the registration is fulfilled or the start time passes. Allow cancel/refund actions only while the offering is still open; otherwise surface a contact-the-temple message.
- For the registration flow, accept these query params, prefill the form for logged-in patrons, and fall back to guided login if they arrive without a session.

Completed:

## Phase 3B – Member Surfaces

- Scope `/account` to authenticated workflows only. Offerings (events/services/gatherings) remain on the public Vue site; patrons tap “Register” there and deep-link into `/account` with the offering slug in tow.
- Sections to implement:
  - **Dashboard** – show the next registration + quick links to profile/orders.
  - **Registrations** – list active orders (status, payment, actions like cancel/request help).
  - **History** – past orders/payments with PDF receipt/LINE Pay reference download.
  - **Profile & Settings** – read/edit contact info, privacy, QR code for switching temples.
- Registration hand-off flow:
  1. Vue deep-links patrons to `/account/login?temple=<slug>&account_action=<event|service|gathering>&offering=<offering_slug>` whenever they tap “Register.” OAuth is the default authentication path; the email/password modal is always available as the fallback.
  2. If the patron isn’t signed in, show the login modal (same component used on `/account/login`) atop the page background; once authenticated, continue the flow.
  3. After login, `Account::RegistrationsController` checks `current_user.temple_event_registrations` for an existing enrollment on that offering. If one exists (one active registration per patron per offering), redirect to the registration detail page so they can view/cancel. Otherwise, render the new-registration form for that offering.
  4. Prefill personal info from `users` table metadata; if they edit those fields, save back to their profile. Offering-specific metadata (ancestor names, dedications) is read-only outside the registration form—patrons view it per registration but admins remain the only editors.
  5. Notes/comments stay admin-only for now; patrons don’t see or edit them.
  6. Lock edits once the registration is fulfilled or the start time passes. Allow cancel/refund actions only while the offering is still open; otherwise surface a contact-the-temple message.
- For the registration flow, accept these query params, prefill the form for logged-in patrons, and fall back to guided login if they arrive without a session.
- Profile & dependents:
  - Patrons can edit all standard `users` fields (name, email, phone, address, language) plus opt-ins. The profile page shows their own info first, followed by expandable cards for each dependent.
  - Dependents are full profiles (name, relationship, optional birthdate, contact info). CRUD lives under the profile screen: “Add dependent” inserts a new card; if saved empty, the card disappears.
  - Dependents don’t get login credentials—registrations created in their name still belong to the controller account. Payments lists show the registrant name (self or dependent) in an additional column.
- Certificates:
  - Dashboard/history list certificates with their numbers and status but no downloads yet. Copy explains “Temple provides printed certificates on-site; check back when digital downloads are available.” Keep the slot ready for future PDF links.
- Use existing account APIs (`/account/api/registrations`, `/account/api/payment_statuses/:reference`, etc.); add endpoints only if gaps appear (e.g., certificate downloads).
- Keep future enhancements (LINE Pay, certificate requests) behind feature flags so the portal shell can ship incrementally.
  - When Vue links patrons into `/account`, pass the registration/offering slug in the query so the portal can redirect to the matching registration detail once they log in.
  - Implement `Account::RegistrationsController#index/show`, `Account::PaymentsController#index`, and `Account::ProfileController#show/update` to back the sections listed above; reuse the API serializers so fields stay consistent.

Completed:

## Phase 4 – Workflow & Deployment

- Standard workflow: edit themes → run `node bin/sync_design_system.js` → set default theme → preview via dev toggle → deploy. Document this sequence for designers/engineers.
- Confirm that admin console + Expo share the Golden Template UI while only marketing + account surfaces respond to theme switching.
- Add regression tests (controller + system) to ensure theme resolution, toggles, and per-temple overrides remain intact.

Completed:

## Phase 5 – Temple Context & Entry Flow

- `/account` must always know which temple the patron is managing.
  - Deep links from the marketing Vue site include the temple slug so login/registration already have context.
  - If someone visits `/account/login` without a slug (e.g., typed manually), redirect them to a “Select your temple” screen that renders cards from `rails/app/lib/temples/manifest.yml` (new `/account/temples` page) and links back to the correct public site/login deep link.
  - After sign-in, store the active temple slug in the session so the dashboard/orders load the right data. (Future work: allow patrons with multiple memberships to switch temples from within the account portal.)
- Never sign a patron into a generic, slugless session—every workflow should start from a specific temple domain or the manifest selector.

Completed:

## Mobile Alignment Notes

- Slug resolution must stay consistent so both account portal and future Expo clients consume the same scoped payloads.
- Expo remains a convenience endpoint: reuse existing APIs/cache payloads instead of inventing new contract types.
- Push notifications or lightweight screens can live in Expo, but heavy workflows should continue to target the account web surface.
- Mobile should mirror the Rails cache payloads 1:1, skipping only the sections explicitly omitted from the app to keep the experience focused.

Completed:
