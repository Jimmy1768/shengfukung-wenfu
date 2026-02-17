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
- Temple profile YAML now declares `registration_periods` (`{ key, label_zh, label_en }`). `/admin/services/:id` surfaces these keys in a dropdown (with an “Other” escape hatch) and persists the selection as `registration_period_key`. Service cards and order lists display the chosen label for quick context.
- Registrations copy the service’s `registration_period_key` into `metadata["period_key"]`. Duplicate detection enforces one active registration per `(registrant_scope, service.slug, period_key)` so recurring services (lanterns, tables, donations) cannot be double-booked.
- Admin filters and CSV exports accept `period_key`, enabling per-period audits without custom SQL.

## Admin UX Enhancements

- All admin sections use localized copy, improved spacing, and consistent card scaffolding. Payments dashboards, ledger tables, and archive filters adopt the latest visual system.
- The patrons directory (owner-only) adds search and table views plus actions that serve as the precursor to the “promote patron to admin” workflow.
- The temple switcher lets owners jump between slugs locally while remaining disabled in production.

## Public API Surface

- `/api/v1/temples/:slug` exposes profile, news, archive, events, and services payloads. Serializers (`TempleEventSerializer`, `TempleServiceSerializer`) include the metadata Vue/Expo require.
- These endpoints mirror what the cache payloads provide for admin/account flows, keeping mobile/web consumers in sync.

## Vue Frontend Integration

- The Vue app reads `VITE_TEMPLE_SLUG`, bootstraps `useTempleContent`, and hydrates hero/news/archive/events/services views from the Rails APIs.
- Events and Services pages now consume the new feeds, while the home page highlights the first two upcoming events instead of hardcoded placeholders.

## Deployment & Onboarding

- Each temple ships with its own `<slug>.env`, systemd units, and `bin/load_temple_env` helper so scripts/deployments run with the right credentials.
- Deploy helpers (`bin/deploy_vue`, `bin/deploy_vue_all`, `bin/expo_prebuild`, `bin/expo_build`) automatically source the slug env. Smoke tests (`bin/run_smoke_tests`) hit the per-slug API to verify deployments.
- `DEPLOYMENT_READINESS.md` outlines the droplet/nginx rollout plan once a temple graduates to production.

## Mobile Alignment

- Expo reuses the same APIs/cache payloads as Vue, keeping the slug-driven framework authoritative. Mobile remains a convenience client while heavy admin flows live on the web.

## Future Enhancements / Notes

- Patron → Admin promotions need a full UI plus owner-only filters for current admins.
- Rolling offerings Phase B (dependents) will introduce “Who is this for?” selectors, dependent metadata storage, and per-dependent duplicate enforcement.
- Consider scripts for advancing all services to the next `registration_period_key` and tooling for renewal reminders once temples request it.
