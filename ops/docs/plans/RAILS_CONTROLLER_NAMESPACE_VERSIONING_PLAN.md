# RAILS CONTROLLER NAMESPACE + VERSIONING PLAN

## Purpose

- Establish one clear rule-set for controller namespaces in `rails/app/controllers`.
- Decide where API versioning (`v1`) is required vs unnecessary.
- Prepare a safe, phased cleanup plan before any code movement.

## Questions Answered

- `v1` should be used for externally consumed API contracts, not for every namespace.
- HTML/session namespaces (`admin`, `account`, `marketing_admin`) should remain unversioned.
- JSON endpoints intended as internal, same-release surfaces can remain unversioned unless they become external contracts.

## Current Snapshot (Observed)

- Public API is versioned: routes under `/api/v1/*` map to `Api::V1::*`.
- Account has JSON endpoints under `/account/api/*` with no version segment (`Account::Api::*`).
- Admin and Account portal controllers are HTML/session oriented and unversioned.
- Potential drift/orphans to verify during implementation:
  - `app/controllers/api/v1/theme_controller.rb` exists but route is not present in `config/routes.rb`.
  - `app/controllers/web/base_controller.rb` exists without an active route namespace.
  - `app/controllers/expo/base_controller.rb` exists without an active route namespace.

## Namespace Policy (Target)

- `Api::V1::*`
  - External/public/mobile API contract.
  - Version required in URL and module (`/api/v1`).
- `Api::V1::Account::*` / `Api::V1::Admin::*` (optional sub-namespaces)
  - Use when programmatic endpoints are scoped to account/admin capabilities.
  - Still live under the single top-level API surface (`/api/v1/...`).
- `Account::*`, `Admin::*`, `MarketingAdmin::*`
  - Server-rendered web controllers.
  - No version segment.

## Architecture Decision (Chosen)

- Use one programmatic API surface: `api/v1/*` (top-level `Api` namespace).
- Keep HTML/session controllers in domain namespaces (`account`, `admin`, `marketing_admin`).
- Migrate account-scoped JSON endpoints out of `Account::Api::*` into `Api::V1::*` sub-namespaces.
- Treat client platforms (Expo/mobile/web frontend) as API consumers, not namespace owners.

### Practical Examples

- HTML:
  - `Account::RegistrationsController` -> `/account/registrations`
  - `Admin::RegistrationsController` -> `/admin/registrations`
- Programmatic JSON:
  - `Api::V1::Account::RegistrationsController` -> `/api/v1/account/registrations`
  - `Api::V1::Admin::PaymentsController` -> `/api/v1/admin/payments` (if/when needed)
  - `Api::V1::TemplesController` -> `/api/v1/temples/:slug`

## Versioning Trigger Rules

- Introduce `vN` when any endpoint is consumed by:
  - native mobile clients,
  - third-party integrators,
  - separate frontend deployment cadence.
- Keep unversioned only when:
  - producer and consumer deploy together in same Rails release,
  - breaking changes are controlled in one codebase rollout.

## Proposed Controller Organization

- Keep feature/domain grouping inside namespace:
  - `admin/registrations_controller.rb`
  - `account/registrations_controller.rb`
  - `api/v1/temple_events_controller.rb`
  - `api/v1/account/registrations_controller.rb` (preferred over giant controller names)
- Keep dedicated base controllers per surface:
  - `Api::BaseController` for JSON-only external API behavior.
  - `Account::BaseController` and `Admin::BaseController` for web/session behavior.
  - Optional `Api::V1::Account::BaseController` / `Api::V1::Admin::BaseController` only if API auth/authorization diverges by audience.
- Avoid mixed concerns:
  - external API auth/serialization should not leak into HTML controllers.
  - account/admin theme + layout concerns should not leak into public API controllers.

## Current Namespace Keep / Prune Classification

### Keep

- `application_controller.rb`
  - Rails foundation for HTML/session controller stack.
- `ui_gateway_controller.rb`
  - Valid HTML/Turbo-oriented base layer (cross-platform browser/webview concerns).
- `auth/*`
  - Dedicated integration callback surface (OmniAuth), not an API-versioning concern.
- `concerns/*`
  - Shared controller modules/mixins (standard Rails location).
- `utils/*` (with stricter rule)
  - Keep only for infrastructure/task-style endpoints (uploads, password flows, utility tasks), not business-domain CRUD.

### Prune / Consolidate

- `web/*`
  - Remove; current HTML surfaces are already represented by `account/*` and `admin/*`.
- `expo/*`
  - Remove as a namespace owner; Expo should consume `Api::V1::*` endpoints instead.
- `dev/*`
  - Remove as a long-term namespace surface (local testing should use normal controllers/APIs).
  - Do not use `dev/*` for production troubleshooting or data correction tooling.
  - Exception: migrate showcase/demo controllers to a dedicated `demo/*` namespace (feature-oriented, not environment-oriented).
- `account/api/*` (after migration)
  - Consolidate into top-level versioned API (`api/v1/account/*` or `api/v1/me/*`).

### Orphan Review Candidates (Route Mismatch / Scaffolding Drift)

- `app/controllers/api/v1/theme_controller.rb`
  - File exists with `/api/v1/theme` comments, but route is not currently defined.
- `app/controllers/web/base_controller.rb`
  - Base surface exists without active route namespace.
- `app/controllers/expo/base_controller.rb`
  - Base surface exists without active route namespace.

### Dedicated Demo Surface (Intentional)

- `marketing_admin` showcase may remain as a hidden promotional/demo feature.
- Internally, demo controllers should live under `Demo::*` (for example `app/controllers/demo/*`), not under `Dev::*`.
- Keep `/marketing/admin` route path unchanged; only internal module organization changes.

## Implementation Plan (No Refactor Yet)

### Phase A: Inventory + Decision Lock

- [ ] Generate and review full route-to-controller map (`bin/rails routes`).
- [ ] Mark each JSON endpoint as `external contract` or `internal account ajax`.
- [ ] Confirm whether `/account/api/*` is consumed outside Rails-rendered account pages.

### Phase B: Contract Boundaries

- [ ] Freeze policy: only `/api/vN/*` is externally supported.
- [ ] Define deprecation policy for future `v2` (support window + sunset notice).
- [ ] Document ownership of each namespace (Admin, Account, Public API).

### Phase C: Drift Cleanup

- [ ] Resolve orphan candidates:
  - [ ] add missing route for `Api::V1::ThemeController` if needed, or remove controller if not needed.
  - [ ] remove/archive unused `Web::BaseController` surface if unused.
  - [ ] remove/archive unused `Expo::BaseController` surface if unused.
- [ ] Normalize comments/docs to match actual routing and ownership.

### Phase D: Account API Consolidation Into Top-Level API (Chosen Direction)

- [ ] Introduce `Api::V1::Account::*`
- [ ] Migrate routes from `/account/api/*` to `/api/v1/account/*` (or `/api/v1/me/*`).
- [ ] Keep temporary compatibility aliases only if active clients require a transition window.
- [ ] Remove `Account::Api::*` controllers and routes after migration verification.

### Phase E: Guardrails

- [ ] Add a routing spec that asserts:
  - [ ] public API routes are under `/api/v1/*`.
  - [ ] HTML namespaces (`admin`, `account`) do not include version segments.
  - [ ] account/admin JSON endpoints do not live outside `api/v1/*`.
- [ ] Add a lightweight architecture doc link from `README` or `ops/docs`.

## Future Operations Surface (Out of Scope for Phase 1)

- Create a dedicated production support namespace: `ops/*` (or `support/*`).
- Do not reuse `dev/*` for production issue handling.

### Intended Responsibilities

- Admin issue intake / ticketing (structured reports from admins, not email).
- Operator impersonation / "god mode" for reproducible debugging.
- Audited corrective tools for data fixes (orders, payments, refunds, registrations).
- Investigation dashboards and runbooks for production support.

### Design Constraints (Future-Proofing)

- All ops mutations must be explicit domain actions/services (not generic raw CRUD editors).
- Every ops mutation must require:
  - actor identity
  - reason / note
  - ticket reference
  - before/after change logging
- Impersonation must be time-bounded, visible in UI, and fully audited.
- Permission levels must separate read-only support, mutation support, and high-risk financial operations.

## Risks + Mitigations

- Risk: accidental client breakage if unversioned endpoints are externally used.
  - Mitigation: classify consumers before any renaming/moves.
- Risk: dead scaffolding causes confusion and duplicate patterns.
  - Mitigation: explicitly delete or wire every orphaned controller surface.
- Risk: over-versioning increases maintenance burden.
  - Mitigation: apply versioning only where contract stability is required.

## Acceptance Criteria

- Team can answer, for any endpoint, whether it is external vs internal.
- Public API contract is consistently versioned in both routes and modules.
- Non-API web namespaces remain unversioned and cleanly scoped.
- No orphan controller namespaces remain undocumented.
