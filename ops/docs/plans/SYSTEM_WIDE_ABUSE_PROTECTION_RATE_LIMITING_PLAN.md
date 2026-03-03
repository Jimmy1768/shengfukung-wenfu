# SYSTEM-WIDE ABUSE PROTECTION + RATE LIMITING PLAN

## Purpose

- Build a generalized, reusable abuse-protection layer for the project.
- Use the existing protection infrastructure (`api_usage_logs`, `api_request_counters`, `blacklist_entries`) as the foundation.
- Avoid per-controller ad hoc throttling logic for every new feature.

## Why This Exists

- Current/future features need protection against:
  - accidental repeated submissions (double click, refresh)
  - scripted abuse/spam
  - endpoint hot spots
  - noisy clients consuming shared resources
- The project already includes open-ended protection tables + middleware placeholders by design.

## Existing Foundation (Confirmed)

- `api_usage_logs`
- `api_request_counters`
- `blacklist_entries`
- `ApiProtection::AuditMiddleware` (currently focused on `/api` requests)

## Product Direction

- Keep one generalized protection framework.
- Support endpoint-level policies (not only global limits).
- Expand coverage beyond `/api/*` to selected HTML POST endpoints where appropriate (for example account contact forms).

## Scope

- Shared request throttling + blacklist checks
- API endpoints (`/api/v1/*`)
- Selected HTML POST endpoints (`/account/*`, later `/admin/*`) with abuse risk
- Structured observability (logs + counters)

## Reference Docs

- `ops/docs/reference/platform_abuse_protection.md`

## Out of Scope (Phase 1)

- Full WAF/bot detection
- CAPTCHA everywhere
- Third-party anti-fraud integrations
- Geo/IP intelligence feeds

## Design Goals

- Consistent policy enforcement across features
- Configurable thresholds by endpoint class
- Clear operational visibility (why request was throttled/blocked)
- Safe defaults with project-wide extensibility

## Policy Model (Target)

### Dimensions

- IP address
- user id (when authenticated)
- endpoint key / route class
- request method
- optional temple slug / tenant scope (not used in current phase)

### Outcomes

- allow
- throttle (temporary block / retry later)
- blacklist deny (hard block according to policy)
- audit-only (log + count without blocking)

## Endpoint Classes (Suggested)

- `api.public.read`
- `api.account.read`
- `api.account.write`
- `api.admin.read`
- `api.admin.write`
- `web.account.form_submit`
- `web.admin.form_submit` (future)

## Initial Rollout Strategy

### Phase A: Inventory + Policy Map

- [x] Inventory current `/api/*` and high-risk HTML POST endpoints.
- [x] Define endpoint classes and default thresholds.
- [x] Document override rules for especially sensitive endpoints.

#### Phase A Inventory Snapshot (2026-03-02)

Current API write endpoints:
- `POST /api/v1/demo_contacts`
- `POST /api/v1/temples/:slug/contact_temple_requests`
- `POST /api/v1/payments/webhooks/:provider`
- `PATCH /api/v1/account/preferences`

Current high-risk HTML write endpoints:
- `POST /account/contact_temple_requests`
- `POST /account/register`
- `POST /account/login`
- `POST|DELETE /account/logout`
- `POST /account/registrations/:id/start_fake_checkout`
- `POST|PATCH /account/registrations`
- `POST|PATCH|DELETE /account/dependents`
- `PATCH|POST /account/profile`
- `POST /admin/login`
- `POST|DELETE /admin/logout`
- `POST|PATCH /admin/temple/profile`
- `POST /admin/payments`
- `POST /admin/payments/fake_checkout`
- `POST|PATCH /admin/events|services|gatherings/*`
- `POST|PATCH /admin/news_posts|gallery_entries`
- `POST /admin/media_uploads`
- `POST /admin/patrons`
- `POST /admin/patrons/:id/promote`
- `DELETE /admin/patrons/:id/revoke`
- `POST|DELETE /admin/patrons/:patron_id/metadata_values`

#### Phase A Policy Map (Proposed Defaults)

| Endpoint class | Initial mode | Suggested limit | Window | Primary key |
| --- | --- | --- | --- | --- |
| `api.public.read` | audit-only | 300 | 60s | ip |
| `api.account.read` | audit-only | 240 | 60s | user_id -> ip |
| `api.account.write` | enforce | 60 | 60s | user_id -> ip |
| `api.admin.read` | audit-only | 180 | 60s | user_id -> ip |
| `api.admin.write` | enforce | 45 | 60s | user_id -> ip |
| `web.account.form_submit` | audit-only | 20 | 60s | user_id -> ip |
| `web.account.form_submit.contact_temple` | enforce | 5 | 300s | user_id -> ip |
| `web.admin.form_submit` | audit-only | 30 | 60s | user_id -> ip |
| `api.webhook.ingest` | enforce | 120 | 60s | provider+ip |

Notes:
- `user_id -> ip` means authenticated requests key by `user_id`; anonymous fallback keys by IP.
- Limiter scope is system-wide for this phase; `temple_slug` is intentionally excluded from key dimensions.
- `api.webhook.ingest` should map specifically to `POST /api/v1/payments/webhooks/:provider`.

#### Phase A Override Rules (Sensitive Endpoints)

- Contact Temple:
  - class: `web.account.form_submit.contact_temple`
  - enforce immediately (not audit-only).
  - throttle response should be user-safe and non-technical.
- Auth/session routes (`/account/login`, `/admin/login`, `/account/register`):
  - class: `web.account.form_submit` or `web.admin.form_submit` with stricter subkey overrides.
  - recommendation: lower threshold than generic form submissions.
- Payment mutation routes (`start_fake_checkout`, `admin/payments`, future live checkout endpoints):
  - class: `api.account.write` or `web.*.form_submit` depending on surface.
  - enforce from day 1 to reduce duplicate-intent bursts.
- Webhook ingest:
  - class: `api.webhook.ingest`
  - do not share thresholds with user traffic classes.

#### Decisions To Confirm Before Phase B

- [x] Confirm initial enforcement matrix:
  - enforce: `api.account.write`, `api.admin.write`, `web.account.form_submit.contact_temple`, `api.webhook.ingest`
  - audit-only: remaining classes
- [x] Confirm identity precedence: `user_id` first, fallback `ip`.
- [x] Confirm whether auth endpoints get dedicated classes (`web.account.auth`, `web.admin.auth`) now or as Phase B follow-up.
  - decision: keep under existing web form classes for Phase B; revisit dedicated auth classes after initial telemetry.
- [x] Confirm API throttle response contract (`429` JSON + retry hint).
- [x] Confirm HTML throttle response contract (redirect back + flash message).
- [x] Confirm blacklist policy for Phase 1:
  - manual-only deny entries
  - no automatic blacklist writes until after threshold tuning data is collected.

#### Phase B Design Decisions (Locked)

- Configuration/constants live under `rails/app/lib/api_protection/` (dedicated subsystem folder, no broad utils merge).
- Counter granularity for enforcement is per-minute buckets.
- Limiter scope is system-wide:
  - key precedence: authenticated `user_id`, fallback `ip`
  - do not include `temple_slug` in key dimensions for Phase B
- Middleware/guard must support surface-aware responses:
  - API: `429` JSON with `Retry-After`
  - HTML form submissions: redirect back with flash error
- Fail-open behavior remains for internal logging/counter errors (request is not blocked due to telemetry write failure).

### Phase B: Middleware/Service Expansion

- [x] Confirm current middleware responsibilities and boundaries.
- [x] Add support for selected non-API endpoints (or companion guard service for HTML controllers).
- [x] Normalize request classification (route -> endpoint key/class).

Phase B implementation notes:
- Added dedicated subsystem config/constants under `rails/app/lib/api_protection/`:
  - `policy.rb` for class policy defaults and modes
  - `request_classifier.rb` for route/method -> endpoint class mapping
- Clarified boundary:
  - Rack middleware handles `/api/*` requests only
  - controller guard concern handles selected HTML write routes (`/account/*`, `/admin/*`)
- Added `ApiProtection::ControllerGuard` concern and wired it via `prepend_before_action` in:
  - `Account::BaseController`
  - `Admin::BaseController`
- Updated `ApiProtection::RequestAudit` to:
  - classify requests via endpoint class map
  - use per-minute buckets (`YYYYMMDDHHMM`) scoped by identity + endpoint class + method
  - enforce user-first scope (`User` when present, otherwise `IpAddress`)
  - emit structured `ApiUsageLog.metadata` fields (`endpoint_class`, `decision`, `reason`, `mode`, `limit`, `window_seconds`, scope keys)
  - preserve fail-open behavior for logging/counter write errors

Phase B test execution log:
- Command:
  - `cd rails && bin/rails test test/services/api_protection_request_audit_test.rb test/integration/api_protection_middleware_test.rb test/integration/account/request_throttling_test.rb`
- Result:
  - `6 runs, 15 assertions, 0 failures, 0 errors, 0 skips`

Progress status after Phase B:
- Delivered:
  - route/method endpoint classification
  - per-minute class-aware counters
  - user-first scope with IP fallback
  - API JSON 429 + HTML redirect/flash throttling behavior
  - blacklist deny checks on both API and protected HTML paths
- Remaining (next phases):
  - explicit threshold tuning from production-like telemetry
  - retention cleanup job (daily prune) implementation
  - ops/admin inspection + unblock tooling
  - alerting thresholds for abuse spikes

### Phase C: Enforcement + Observability

- [x] Enforce counters + throttling using `api_request_counters`.
- [x] Enforce deny logic via `blacklist_entries`.
- [x] Improve structured logs in `api_usage_logs` (result, policy key, reason).
- [x] Add clear application logs for throttled/blocked requests.

Phase C implementation notes:
- `RequestAudit` now computes dynamic `Retry-After` aligned to window rollover (instead of fixed static seconds).
- Structured metadata now includes counter context:
  - `counter_value`
  - `bucket`
- App-level warning logs now emit on throttle and blacklist-deny decisions with request path/method, scope, and retry hints.
- Added daily cleanup task:
  - `cd rails && bin/rails api_protection:cleanup`
  - defaults: `LOW_SIGNAL_HOURS=48`, `HIGH_SIGNAL_DAYS=60`, optional `DRY_RUN=true`

Phase C tuning notes (for later threshold changes):
- Class limits/windows are centralized in:
  - `rails/app/lib/api_protection/policy.rb`
- Tuning workflow:
  1. inspect `ApiUsageLog` decisions + counter distribution
  2. adjust class-specific `limit`/`window_seconds`
  3. deploy and monitor throttle false-positive rate
  4. repeat until steady-state

Phase C test execution log:
- Command:
  - `cd rails && bin/rails test test/services/api_protection_request_audit_test.rb test/integration/api_protection_middleware_test.rb test/integration/account/request_throttling_test.rb`
- Result:
  - `6 runs, 15 assertions, 0 failures, 0 errors, 0 skips`

#### Data Retention Policy (Protection-First)

- Primary goal is active protection; retention is secondary.
- Keep high-frequency low-signal data short-lived:
  - allow/audit-only counter rows: short TTL (target 24-72 hours)
  - routine allow logs: short TTL (target 24-72 hours)
- Keep high-signal security data longer:
  - throttled/blocked log events
  - blacklist entries + related decision traces
  - repeated violation patterns
- Add scheduled cleanup (daily) to prune low-signal rows automatically.
- Do not auto-delete active blacklist records; expire/review through ops workflow.

### Phase D: Feature Adoption

- [x] Migrate feature-local throttles into shared protection (e.g., Contact Temple).
- [x] Add policy coverage for new high-risk POST endpoints.
- [x] Document how new features declare/choose endpoint classes.

#### Phase D Decisions (Locked)

- Source of truth:
  - shared `ApiProtection` subsystem is the only place for new throttling policy.
  - do not add new feature-local throttles.
- Contact Temple migration:
  - run dual protection for one release (shared enforce + existing local fallback), then remove local limiter.
  - status: local limiter has already been removed after rollout confidence.
- Endpoint class scope:
  - keep current class set (no new fine-grained class types in this phase).
  - if future split is required, add class constants in `rails/app/lib/api_protection/policy.rb` and document mapping in `ops/docs/reference/platform_abuse_protection.md`.
- Feature onboarding checklist (required for new high-risk endpoints):
  1. endpoint class assignment
  2. mode decision (`audit_only` vs `enforce`)
  3. limit/window selection
  4. tests updated
  5. reference/plan docs updated
- Migration priority:
  1. auth/session writes
  2. registration/payment writes
  3. admin mutation forms
- Audit-to-enforce gate:
  - minimum 7 days telemetry in audit mode
  - no confirmed false-positive incidents
  - owner approval
  - docs updated in plan/reference before switching to enforce
- Policy ownership:
  - single owner approval for policy/class threshold changes.

Phase D execution status:
- Contact Temple now relies on shared `ApiProtection` only:
  - local `Contact::TempleInquiryRateLimiter` removed
  - account + public contact submit paths depend on endpoint-class policy enforcement
- Added class-coverage tests for high-risk write surfaces:
  - account login write
  - admin login write
  - account contact temple form submit
  - API webhook ingest
  - API contact temple submit

### Phase E: Hardening

- [x] Add admin/ops tooling to inspect counters/blacklist state.
- [x] Add safe reset/unblock workflows for support operations.
- [x] Add alerting thresholds for repeated abuse spikes.

Phase E implementation notes:
- Added ops/admin tooling rake tasks:
  - `api_protection:report` (counter/decision/blacklist visibility)
  - `api_protection:unblock_ip` (safe unblock with `APPLY=true`)
  - `api_protection:unblock_scope` (safe unblock with `APPLY=true`)
  - `api_protection:reset_counters` (filtered counter reset with `APPLY=true`)
- Added spike alerting threshold task:
  - `api_protection:alert_spikes`
  - uses `ApiProtection::SpikeAlertChecker`
  - alerts via `Notifications::Alerts::AlertSender` when threshold conditions are met
- Safety controls:
  - destructive unblock/reset actions require `APPLY=true`
  - spike alert task supports `DRY_RUN=true`

Phase E test execution log:
- Command:
  - `cd rails && bin/rails test test/services/api_protection/spike_alert_checker_test.rb test/services/api_protection/request_classifier_test.rb test/services/api_protection_request_audit_test.rb test/integration/api_protection_middleware_test.rb test/integration/account/request_throttling_test.rb test/integration/account/contact_temple_requests_test.rb test/integration/api/v1/contact_temple_requests_test.rb`
- Result:
  - `21 runs, 55 assertions, 0 failures, 0 errors, 0 skips`

## Contact Temple Integration (Immediate Relevance)

- Contact Temple is now migrated into the shared framework under endpoint classes such as:
  - `web.account.form_submit.contact_temple`
- This keeps email abuse protections consistent with the broader system.

## Risks + Mitigations

- Risk: applying API-only logic to HTML endpoints breaks UX unexpectedly.
  - Mitigation: introduce endpoint-class rollout and start in audit-only mode where needed.
- Risk: thresholds are too aggressive for real users.
  - Mitigation: per-endpoint tuning + logs/counters before strict enforcement.
- Risk: duplicated throttling logic across features.
  - Mitigation: move feature-local throttles into shared framework after initial rollout.

## Acceptance Criteria

- Shared protection framework handles throttling for API and selected HTML POST endpoints.
- Requests are classified and logged with consistent endpoint keys/classes.
- Contact Temple (and similar forms) can rely on the shared framework instead of bespoke guards.
- Support/ops can inspect and act on throttle/blacklist state.
