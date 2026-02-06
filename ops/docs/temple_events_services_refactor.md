# Temple Events & Services Refactor Plan

This document tracks the scope and sequencing for migrating from the legacy `TempleOffering` model to the new `TempleEvent` + `TempleService` architecture with polymorphic registrations and payments.

## Goals
- Represent in-person events (`法會/活動`) separately from temple services (`供燈/供桌/疏文`).
- Preserve a clean admin UX that automatically reflects each temple’s YAML configuration.
- Expose dedicated API feeds so the Vue site can show Events and Services as distinct surfaces.
- Ensure registrations/payments remain auditable via a shared `TempleRegistration` + `TemplePayment` stack.

## Backend Tasks
1. **Models** ✅
   - `TempleEvent`, `TempleService`, `TempleRegistration`, and `PaymentWebhookLog` now exist; `TempleOffering` aliases to `TempleEvent` for legacy code.
   - Associations on `Temple`, `User`, `TemplePayment`, etc., point at the new polymorphic registrations.
2. **YAML Config Loader** ✅
   - Loader reads `events:` and `services:` sections (falling back to legacy `offerings:`) and hydrates metadata defaults.
3. **Admin Console** 🚧
   - Restore a single `/admin/offerings` controller/view that lists both events and services so operators pick from one screen. Visibility is now governed purely by `status` (`draft` vs `published`)—removing the separate “active” toggle keeps the workflow simple. Use “Archive” to flip `status` to `archived` when needed; the default index filters to `draft`/`published`, with an archived view for history.
   - Keep `/admin/events` + `/admin/services` routes for now (used by deep links/metrics), but treat them as thin delegates to the shared helpers. All “Create offering” flows must go through the unified modal, which still lists every YAML template.
   - Orders/payments controllers already speak polymorphic `TempleRegistration`; ensure their filters accept the `offering_reference` scope so navigating from the new offerings page keeps working.
4. **API + Services** ✅
   - `TempleEventsController` / `TempleServicesController` replace the old offerings endpoint; reporting/archives now join through `temple_registrations`.

## Frontend Tasks
1. **API Hooks** ✅
   - `fetchTempleServices`, `useTempleServices`, and `loadTempleService/Event` are wired up; Vue consumes separate feeds.
2. **Vue Components** ✅
   - Events/Services pages render their respective feeds; router + home sections highlight the correct records.
3. **Admin UI (rails erb)** 🚧
   - Final design: operators land on `/admin/offerings`, click “Create offering,” pick a template (event or service), and see the appropriate form partial auto-selected. Event/service-specific ERB partials remain, but a wrapper view chooses which one to render based on the template metadata (`kind`).
   - Patron-facing Vue still shows Events vs Services separately; the merged admin page is purely operational.

## Migration Strategy
- Migrations `20250101000012` + `20260115000013` provisioned the new tables; rolled-back edits preserved the original file, so no follow-up migrations are needed beyond the restored `external_reference`.
- Seeds (`auth_core`, `admin_controls`, `temple_financials`) now seed events/services + sample accounts.

- Public Vue surfaces must only render offerings with `status: "published"`. Admin views show both draft + published offerings, and provide an “archive” control (set `status: "archived"`) that hides records from the default list without deleting data.
- Remaining work: reinstate `/admin/offerings` as the primary admin surface, wire the template modal to instantiate either `TempleEvent` or `TempleService`, and make sure orders/payments filters can scope to either type via the new encoded reference.
- Patron APIs and Vue remain split; do **not** remove `/admin/events` or `/admin/services` until the combined page is fully validated, and even then keep the routes as redirects for bookmarked deep-links.
