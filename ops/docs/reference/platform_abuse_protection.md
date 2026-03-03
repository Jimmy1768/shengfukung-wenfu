# Platform Abuse Protection Reference
Last updated: 2026-03-02

## Purpose
- Document the current system-wide abuse protection architecture.
- Define endpoint classes, policy defaults, and response behavior.
- Provide operator runbook steps for investigating throttles/blocks.

## Architecture (Current)
```text
HTTP request
   |
   +--> /api/* requests
   |      -> ApiProtection::AuditMiddleware
   |      -> ApiProtection::RequestAudit
   |
   +--> selected HTML writes (/account/*, /admin/*)
          -> ApiProtection::ControllerGuard (prepend_before_action)
          -> ApiProtection::RequestAudit

RequestAudit
  - classify route/method -> endpoint_class
  - resolve identity key (user_id, fallback ip)
  - enforce blacklist deny
  - increment per-minute counters
  - enforce threshold by policy mode
  - write structured ApiUsageLog metadata
```

## Core Components
- `rails/app/lib/api_protection/policy.rb`
  - Default class policy definitions (`mode`, `limit`, `window_seconds`).
- `rails/app/lib/api_protection/request_classifier.rb`
  - Route/method classification for API + HTML write surfaces.
- `rails/app/services/api_protection/request_audit.rb`
  - Central audit + throttle/blacklist decision engine.
- `rails/app/middleware/api_protection/audit_middleware.rb`
  - API-only rack entrypoint.
- `rails/app/controllers/concerns/api_protection/controller_guard.rb`
  - HTML write guard for account/admin controller trees.

## Endpoint Classes + Defaults

| Endpoint class | Mode | Limit | Window |
| --- | --- | --- | --- |
| `api.public.read` | audit-only | 300 | 60s |
| `api.account.read` | audit-only | 240 | 60s |
| `api.account.write` | enforce | 60 | 60s |
| `api.admin.read` | audit-only | 180 | 60s |
| `api.admin.write` | enforce | 45 | 60s |
| `web.account.form_submit` | audit-only | 20 | 60s |
| `web.account.form_submit.contact_temple` | enforce | 5 | 300s |
| `web.admin.form_submit` | audit-only | 30 | 60s |
| `api.webhook.ingest` | enforce | 120 | 60s |

## Identity and Counter Scope
- Identity precedence:
  1. authenticated `user_id`
  2. fallback `ip`
- Counter bucket format:
  - per-minute UTC bucket: `YYYYMMDDHHMM`
  - bucket key includes endpoint class + request method
- Scope intent:
  - system-wide protection
  - no `temple_slug` key dimension in current phase

## Response Contract
- API blocked/throttled:
  - HTTP `429`
  - JSON body `{ error: "rate_limited", reason: "..." }`
  - `Retry-After` header present
- HTML blocked/throttled:
  - redirect back (fallback `/`)
  - flash alert: `"Too many requests. Please try again shortly."`

## Blacklist Behavior (Current)
- Manual blacklist entries are enforced.
- Active blacklist check supports:
  - resolved identity scope
  - IP fallback scope
- Auto-blacklist writes are intentionally disabled in this phase.

## Structured Audit Metadata
`ApiUsageLog.metadata` now records:
- `endpoint_class`
- `decision` (`audit_only`, `throttle`, `blacklist_deny`, etc.)
- `reason`
- `mode`
- `limit`
- `window_seconds`
- `scope_type`
- `scope_id`
- `counter_value`
- `bucket`

## Threshold Tuning Notes
- Policy defaults are centralized in:
  - `rails/app/lib/api_protection/policy.rb`
- You can tune per endpoint class by editing:
  - `limit`
  - `window_seconds`
  - `mode` (`audit_only` or `enforce`)
- Recommended change cycle:
  1. collect several days of telemetry
  2. review throttle/deny distribution and false positives
  3. adjust one class at a time
  4. redeploy and re-check before widening enforcement

## Operator Runbook (Quick Checks)

Inspect recent throttle/blacklist decisions:
```bash
cd rails && bin/rails runner "puts ApiUsageLog.where(\"occurred_at > ?\", 1.hour.ago).where(\"metadata ->> 'decision' IN (?)\", ['throttle','blacklist_deny']).order(occurred_at: :desc).limit(50).pluck(:occurred_at, :request_path, :http_method, :ip_address, :metadata)"
```

Inspect hottest per-minute counters:
```bash
cd rails && bin/rails runner "puts ApiRequestCounter.where(\"created_at > ?\", 1.hour.ago).order(count: :desc).limit(50).pluck(:scope_type, :scope_id, :bucket, :count, :metadata)"
```

Inspect active blacklist entries:
```bash
cd rails && bin/rails runner "puts BlacklistEntry.where(active: true).where(\"expires_at IS NULL OR expires_at > ?\", Time.current).order(created_at: :desc).pluck(:scope_type, :scope_id, :reason, :expires_at)"
```

## Retention Policy (Planned)
- Protection-first, storage-second:
  - short TTL for routine allow/audit rows (48 hours)
  - longer retention for throttled/blocked signal rows (60 days)
- Implemented cleanup task:
  - `cd rails && bin/rails api_protection:cleanup`
  - optional env vars:
    - `LOW_SIGNAL_HOURS` (default `48`)
    - `HIGH_SIGNAL_DAYS` (default `60`)
    - `DRY_RUN=true` for no-delete preview
- Active blacklist records are not auto-removed by cleanup.

## Current Status Snapshot
- Completed:
  - Phase A inventory/policy map
  - Phase B middleware/controller boundary + classification
- Pending:
  - Phase C tuning and cleanup automation
  - Phase D feature-local throttle migration
  - Phase E ops tooling and alerting
