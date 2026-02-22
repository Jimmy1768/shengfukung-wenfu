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
- optional temple slug / tenant scope

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

- [ ] Inventory current `/api/*` and high-risk HTML POST endpoints.
- [ ] Define endpoint classes and default thresholds.
- [ ] Document override rules for especially sensitive endpoints.

### Phase B: Middleware/Service Expansion

- [ ] Confirm current middleware responsibilities and boundaries.
- [ ] Add support for selected non-API endpoints (or companion guard service for HTML controllers).
- [ ] Normalize request classification (route -> endpoint key/class).

### Phase C: Enforcement + Observability

- [ ] Enforce counters + throttling using `api_request_counters`.
- [ ] Enforce deny logic via `blacklist_entries`.
- [ ] Improve structured logs in `api_usage_logs` (result, policy key, reason).
- [ ] Add clear application logs for throttled/blocked requests.

### Phase D: Feature Adoption

- [ ] Migrate feature-local throttles into shared protection (e.g., Contact Temple).
- [ ] Add policy coverage for new high-risk POST endpoints.
- [ ] Document how new features declare/choose endpoint classes.

### Phase E: Hardening

- [ ] Add admin/ops tooling to inspect counters/blacklist state.
- [ ] Add safe reset/unblock workflows for support operations.
- [ ] Add alerting thresholds for repeated abuse spikes.

## Contact Temple Integration (Immediate Relevance)

- Phase 1 `Contact Temple` may ship with a small local throttle for speed.
- It should later migrate into this framework under an endpoint class such as:
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
