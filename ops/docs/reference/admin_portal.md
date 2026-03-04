# Admin Portal Reference

This document captures what exists in the admin portal today so future work can plug into the right layers without re-discovering prior decisions.

## Temple Content & Media Management

- `/admin/temple/profile` persists hero copy, per-tab hero images, contact/service/visit metadata, and validates map links. Hero uploads use the AJAX uploader with fallback URL inputs, and a floating save CTA appears when media sections are in view.
- News (`TempleNewsPost`) and gallery (`TempleGalleryEntry`) entries live under `/admin/news_posts` and `/admin/gallery_entries`. Each supports localized copy, publish toggles, and optional recap uploads via the shared MediaAsset/S3 pipeline.
- Event/service/gathering CRUD screens share the same card layout, localized labels, and datetime pickers; slugs auto-generate per temple so admins never manage URL tokens manually.
- Gatherings cover non-offering meetups but still flow through the unified registrations/payments stack so reporting stays consistent.

## Offerings, Registrations & Period Keys

- Offerings are defined by YAML under `rails/db/temples/offerings/<slug>.yml`. Templates include `form_fields`, registration form schema, and optional `attributes` that prefill base model columns (e.g., price, description, currency).
- A template picker on `/admin/offerings/new` lets admins start from those configs. Selecting a template copies metadata, defaults, and prefilled attributes into the new event/service record before validations run.
- Temple profile YAML declares `registration_periods` (`{ key, label_zh, label_en }`). `/admin/services/:id` surfaces only those keys in a dropdown and persists the selection as `registration_period_key`.
- Registrations copy the service’s `registration_period_key` into `metadata["registration_period_key"]`. Duplicate detection enforces one active registration per `(registrant_scope, service.slug, registration_period_key)` so recurring services (lanterns, tables, donations) cannot be double-booked.
- Admin filters and CSV exports accept `period_key`, enabling per-period audits without custom SQL.
- `/admin/events/:id/orders`, `/admin/services/:id/orders`, and `/admin/gatherings/:id/orders` now support full create/show/edit/update for registrations. This includes editing patron-created records from the admin side.
- `pending` on order/registration tables means payment is still outstanding (not an “incomplete form” state).

## Registration Lifecycle Automation

- Unpaid holds are managed by `Registrations::PendingExpiryManager` and exposed via `bin/rails registrations:expire_unpaid`.
- The lifecycle run order is: send `registration.expiring_soon` notifications, cancel stale unpaid registrations, then send `registration.expired` notifications.
- Notification fan-out currently targets the patron plus active temple admins, honoring `notification_rules` and `notification_preferences`.
- Delivery writes `Notification` records and stores dedupe markers in `registration.metadata["expiry_notifications"]` to avoid duplicate reminders.
- In development, recipient routing is safely overridden to `DEV_APP_NOTIFICATION_EMAIL` (fallback default is in `AppConstants::Emails.dev_app_notification_email`).
- Until Sidekiq scheduling is wired for this flow, run the task from cron/systemd timer or an explicit admin runbook command.

## Period-Key Yearly Rollover Ops

- Annual period-key maintenance is automated by `bin/rails registration_period_keys:rollover_year`.
- Default mode is dry-run (`WRITE` absent/false) and emits a report so admins can review key/label changes before applying.
- `WRITE=true` applies YAML updates; `UPDATE_SERVICES=true` additionally updates existing `TempleService.registration_period_key` and `period_label` values.
- Post-rollover duplicate key collisions fail fast and are reported, so admins can fix labels/keys before finalizing.

## Admin UX Enhancements

- All admin sections use localized copy, improved spacing, and consistent card scaffolding. Payments dashboards, ledger tables, and archive filters adopt the latest visual system.
- The patrons directory (owner-only) adds search and table views plus actions that serve as the precursor to the “promote patron to admin” workflow.
- The temple switcher lets owners jump between slugs locally while remaining disabled in production.
- Shared visual/preference policy details (Rails display modes, mobile sync contract, token boundaries) live in `ops/docs/reference/visual_preference_systems.md`.

## Permission Model (Current Policy)

- Baseline policy direction: admins should have read access to core console surfaces, while permissions gate mutation actions (create/edit/delete/export/record cash).
- Navigation should mirror effective access (avoid showing links that always redirect to forbidden states).
- Current aligned gates:
  - `Payments` nav requires `view_financials`, matching `/admin/payments` index access.
  - `Temple Profile` nav requires `manage_profile`, matching `/admin/temple/profile` controller gate.
  - `Permissions` nav requires `manage_permissions`, matching permissions controller gate.
  - `Archives` nav requires `view_financials` or `export_financials`; `/admin/archives` index now enforces the same access rule.
- Mutation paths remain capability-gated server-side via `require_capability!` and should not rely on UI hiding alone.
- Ongoing refinement target: keep nav visibility, page-level read access, and action-level mutation permissions fully consistent for each admin capability.

## Public API Surface

- `/api/v1/temples/:slug` exposes profile, news, archive, events, and services payloads. Serializers (`TempleEventSerializer`, `TempleServiceSerializer`) include the metadata Vue/Expo require.
- These endpoints mirror what the cache payloads provide for admin/account flows, keeping mobile/web consumers in sync.

## Vue Frontend Integration

- The Vue app reads `VITE_TEMPLE_SLUG`, bootstraps `useTempleContent`, and hydrates hero/news/archive/events/services views from the Rails APIs.
- Events and Services pages now consume the new feeds, while the home page highlights the first two upcoming events instead of hardcoded placeholders.

## Deployment & Onboarding

- Each temple uses per-slug credentials (local `.env.development`, production `/etc/default/<slug>-env`), alongside systemd units and `bin/load_temple_env` so scripts/deployments run with the right values.
- Deploy helpers (`bin/deploy_vue`, `bin/deploy_vue_all`, `bin/expo_prebuild`, `bin/expo_build`) automatically source the slug env. Smoke tests (`bin/run_smoke_tests`) hit the per-slug API to verify deployments.
- `DEPLOYMENT_READINESS.md` outlines the droplet/nginx rollout plan once a temple graduates to production.

## Mobile Alignment

- Expo reuses the same APIs/cache payloads as Vue, keeping the slug-driven framework authoritative. Mobile remains a convenience client while heavy admin flows live on the web.

## Future Enhancements / Notes

- Patron → Admin promotions need a full UI plus owner-only filters for current admins.
- Rolling offerings Phase B (dependents) will introduce “Who is this for?” selectors, dependent metadata storage, and per-dependent duplicate enforcement.
- Consider scripts for advancing all services to the next `registration_period_key` and tooling for renewal reminders once temples request it.
