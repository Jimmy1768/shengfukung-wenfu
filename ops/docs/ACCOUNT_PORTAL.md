# Account Portal Build Plan

Progress tracking: fill in each `Completed:` line after the section ships and is verified.

## Phase 1 – Theme & Design Foundations

- Keep `/account` aligned with the shared design system: palettes live in `shared/design-system/themes.json` and require `node bin/sync_design_system.js` after edits.
- Ensure each temple’s default theme key lives in `shared/app_constants/project.json` (override via `PROJECT_DEFAULT_THEME_KEY`) so the portal + marketing site stay in sync.
- Maintain the dev-only theme toggle (cookie-driven) so designers can preview alternate looks locally while production locks to the configured theme.

Completed:

## Phase 2 – Rails Account Shell

- `Account::BaseController` must resolve the active theme (cookie in dev, default otherwise) and expose it to `layouts/account`.
- Keep the account layout hero/header in `rails/app/stylesheets/account/account.scss` and verify shared CSS tokens load correctly.
- Retain the `/dev/theme` endpoints used by both Rails and Vue dev toggles so overrides stay consistent across surfaces.

Completed:

## Phase 3 – Member Surfaces

- Flesh out the `/account` sections: Dashboard (quick links + upcoming cards), Profile (read/edit), Events (upcoming grid + past timeline), and Payments (LINE Pay history placeholder until the pipeline is ready).
- Replace placeholder data with real services once offerings + payments APIs are available, ensuring each section reads the active temple slug.
- Keep future enhancements (offerings, LINE Pay) scoped behind feature flags so the shell can ship incrementally.
- Generate cache payloads on Rails for account experiences where pre-processed data (upcoming events, payment summaries) avoids heavy client-side logic; Vue marketing pages can continue consuming APIs directly without a cache layer.

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
