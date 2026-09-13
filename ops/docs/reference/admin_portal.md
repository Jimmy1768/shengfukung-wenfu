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
- **Registration lifecycle: nine stages, six states, two work queues.** A registration moves patron-or-admin intake -> admin completion -> payment -> fulfilment. The six states are plain SQL scopes on `TempleRegistration` (`awaiting_admin_completion`, `awaiting_payment`, `awaiting_fulfilment`, `fulfilled`, `cancelled`, plus `admin_completed`), deliberately queryable rather than derived in Ruby — the reason the queues exist is that pending work was unfindable at volume, and a state you cannot filter, sort or paginate on reproduces that problem. `#lifecycle_stage` derives the label for display only.
  - **Temple delinquency is not part of those scopes.** It is a property of the temple, not of a registration, and every admin queue is already temple-scoped, so it relabels a set of rows ("awaiting payment" vs "blocked on billing") rather than selecting a different set. Keeping it out is what lets all six express as SQL with no JSON/association/time-arithmetic join.
  - Two of the six are admin work queues ("waiting on us"): awaiting completion, and awaiting fulfilment. Surfaced as dashboard counts and as filter chips on the orders index, ordered ahead of paid/unpaid.
- **Semi-automatic registration checkpoint** (every registrable type, gatherings included since 2026-08-28): a patron's own self-registration is intent, not a finished order — the patron-side form can't capture offering-specific fields (lamp type, dedication message, certificate details, etc.). A registration's own online-checkout path stays blocked until an admin explicitly marks it `TempleRegistration#mark_admin_completed!` from the registration's own show page ("Mark ready for payment", visible whenever `!registration.admin_completed?`). This does **not** gate admin cash acceptance — the same admin routinely completes a registration and accepts cash in one sitting, and gating that too would just block the admin from their own action. See `ops/docs/reference/account_portal.md`'s Registration Handoff section for the patron-facing side.
  - Gatherings were originally exempt. They are not any more: a gathering is a sub-type, not a separate flow, and simply carries no offering data to fill in, so the admin action there is review-and-publish. Removing that exemption required the gathering completion path (route, path helper, button) to exist **first** — `checkout_ready?` demands `admin_completed_at` once completion is required, so removing it alone would have made every gathering registration permanently unpayable.
  - **Bulk completion** (`complete_many`) exists because free gatherings unlock nothing on completion — it is purely an attendance confirmation — yet still enter the queue. A 200-signup community event would otherwise be 200 individual clicks. Accepts an optional subset of registration ids.
- **Stage 9, fulfilment**, is recordable as of 2026-08-28: `#mark_fulfilled!` sets `fulfillment_status` and `fulfilled_at`, idempotently, audited as `temple.registration.fulfilled`. `fulfillment_status` had carried a `"fulfilled"` value since the table was created that nothing ever assigned, so lighting a lantern, arranging a ritual, or printing a certificate was unrecordable. The timestamp matters as much as the status: "how long has this been waiting on us" is the question the queue exists to answer.
- The dashboard's registration metric counts **awaiting completion**, not every open registration. It previously counted `fulfillment_status: open` — i.e. every non-cancelled registration at any stage — which told an admin nothing.

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

## Accounting & Archives Workflow

- `/admin/archives` supports patron-name-first lookup without a date range when the query resolves to exactly one temple patron. Ambiguous patron searches stay empty and require refinement instead of loading broad results.
- `/admin/archives` includes quick month presets plus a summary row so staff can review monthly totals without manually typing date windows.
- Archive exports for payments, registrations, and certificates now follow the active archive filters and resolved patron scope instead of falling back to a broader year-wide export.
- `/admin/payments` CSV export now follows the active filter state and uses accounting-oriented columns, including patron phone, offering type, and registration period key.

## Permission Model (Current Policy)

- Baseline policy direction: admins should have read access to core console surfaces, while permissions gate mutation actions (create/edit/delete/export/record cash).
- Navigation should mirror effective access (avoid showing links that always redirect to forbidden states).
- Current aligned gates:
  - `Payments` nav requires `view_financials`, matching `/admin/payments` index access.
  - `Temple Profile` nav requires `manage_profile`, matching `/admin/temple/profile` controller gate.
  - `Permissions` nav requires `manage_permissions`, matching permissions controller gate.
  - `Archives` nav requires `view_financials` or `export_financials`; `/admin/archives` index now enforces the same access rule.
  - `manage_offerings` gates *authoring* only. Gatherings and Offerings list/browse routes stay visible and reachable without it — `Admin::NavigationHelper#nav_item_read_only?` marks those two nav items read-only rather than hiding them.
  - `record_cash_payments` and `view_guest_lists` are action-only capabilities with no standalone nav item of their own.
- Mutation paths remain capability-gated server-side via `require_capability!` and should not rely on UI hiding alone.
- Ongoing refinement target: keep nav visibility, page-level read access, and action-level mutation permissions fully consistent for each admin capability.

## Public API Surface

- `/api/v1/temple` and its singular child paths expose the deployment's profile,
  news, archive, events, and services payloads. Serializers
  (`TempleEventSerializer`, `TempleServiceSerializer`) include the metadata
  Vue/Expo require. The server resolves this deployment's `PROJECT_SLUG`; the
  public URL does not carry a temple selector.
- These endpoints mirror what the cache payloads provide for admin/account flows,
  keeping mobile/web consumers in sync.

## Vue Frontend Integration

- The Vue app bootstraps `useTempleContent` and hydrates
  hero/news/archive/events/services views from same-origin tenant-local Rails
  APIs. Tenant layout/theme metadata may be loaded from the deployment
  environment, but it must not choose a public API tenant.
- Events and Services pages now consume the new feeds, while the home page highlights the first two upcoming events instead of hardcoded placeholders.

## Deployment & Onboarding

- Each temple uses per-slug credentials (local `.env.development`, production `/etc/default/<slug>-env`), alongside systemd units and `bin/load_temple_env` so scripts/deployments run with the right values.
- Deploy helpers (`bin/deploy_vue`, `bin/deploy_vue_all`) automatically source
  the deployment env. Smoke tests
  (`bin/run_smoke_tests`) hit each deployment's singular tenant-local API to
  verify it.
- `DEPLOYMENT_READINESS.md` outlines the droplet/nginx rollout plan once a temple graduates to production.

## Mobile Alignment

- Expo reuses the same APIs/cache payloads as Vue, keeping the slug-driven framework authoritative. Mobile remains a convenience client while heavy admin flows live on the web.

## Future Enhancements / Notes

- Patron → Admin promotions need a full UI plus owner-only filters for current admins.
- Rolling offerings Phase B (dependents) will introduce “Who is this for?” selectors, dependent metadata storage, and per-dependent duplicate enforcement.
- Consider scripts for advancing all services to the next `registration_period_key` and tooling for renewal reminders once temples request it.
