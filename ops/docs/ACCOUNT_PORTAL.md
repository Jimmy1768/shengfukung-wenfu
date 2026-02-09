# Account Portal Build Plan

Progress tracking: fill in each `Completed:` line after the section ships and is verified.

## Phase 1 – Theme & Design Foundations

- Keep `/account` aligned with the shared design system: palettes live in `shared/design-system/themes.json` and require `node bin/sync_design_system.js` after edits.
- Ensure each temple’s default theme key lives in `shared/app_constants/project.json` (override via `PROJECT_DEFAULT_THEME_KEY`) so the portal + marketing site stay in sync.
- Maintain the dev-only theme toggle (cookie-driven) so designers can preview alternate looks locally while production locks to the configured theme.
- Use the shared design tokens (colors, typography, spacing, button styles) but build dedicated `/account` layouts/components on top so patron-facing pages aren’t constrained by the admin UI grid.

Completed:

## Phase 2 – Rails Account Shell

- `Account::BaseController` must resolve the active theme (cookie in dev, default otherwise) and expose it to `layouts/account`.
- Keep the account layout hero/header in `rails/app/stylesheets/account/account.scss` and verify shared CSS tokens load correctly.
- Retain the `/dev/theme` endpoints used by both Rails and Vue dev toggles so overrides stay consistent across surfaces.

Completed:

## Phase 3 – Member Surfaces

- Scope `/account` to authenticated workflows only. Offerings (events/services/gatherings) remain on the public Vue site; patrons tap “Register” there and deep-link into `/account` with the offering slug in tow.
- Sections to implement:
  - **Dashboard** – show the next registration + quick links to profile/orders.
  - **Registrations** – list active orders (status, payment, actions like cancel/request help).
  - **History** – past orders/payments with PDF receipt/LINE Pay reference download.
  - **Profile & Settings** – read/edit contact info, privacy, QR code for switching temples.
- For the registration flow, accept offering references from Vue, prefill the form for logged-in patrons, and fall back to guided login if they arrive without a session.
- Use existing account APIs (`/account/api/registrations`, `/account/api/payment_statuses/:reference`, etc.); add endpoints only if gaps appear (e.g., certificate downloads).
- Keep future enhancements (LINE Pay, certificate requests) behind feature flags so the portal shell can ship incrementally.

Completed:

## Phase 4 – Workflow & Deployment

- Standard workflow: edit themes → run `node bin/sync_design_system.js` → set default theme → preview via dev toggle → deploy. Document this sequence for designers/engineers.
- Confirm that admin console + Expo share the Golden Template UI while only marketing + account surfaces respond to theme switching.
- Add regression tests (controller + system) to ensure theme resolution, toggles, and per-temple overrides remain intact.

Completed:

## Mobile Alignment Notes

- Slug resolution must stay consistent so both account portal and future Expo clients consume the same scoped payloads.
- Expo remains a convenience endpoint: reuse existing APIs/cache payloads instead of inventing new contract types.
- Push notifications or lightweight screens can live in Expo, but heavy workflows should continue to target the account web surface.
- Mobile should mirror the Rails cache payloads 1:1, skipping only the sections explicitly omitted from the app to keep the experience focused.

Completed:
