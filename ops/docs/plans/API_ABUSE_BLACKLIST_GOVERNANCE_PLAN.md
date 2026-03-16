# API ABUSE BLACKLIST GOVERNANCE PLAN

## Purpose

- Define when and how blacklist entries should be created, reviewed, expired, and removed.
- Build on the existing `ApiProtection` subsystem instead of adding a separate abuse system.

## Current State

Already in place:
- shared request auditing via `ApiProtection::RequestAudit`
- threshold enforcement and telemetry via `ApiUsageLog` and `ApiRequestCounter`
- manual blacklist enforcement through `BlacklistEntry`
- ops tooling for report, unblock, counter reset, cleanup, and spike alerts

Not yet defined clearly:
- who is allowed to create blacklist entries
- what evidence is required before blacklisting
- when temporary vs permanent blacklist entries should be used
- how blacklist entries should be reviewed and expired
- whether admin UI or internal tooling is needed instead of console/task-only operations

## Goal

Keep blacklist behavior conservative, reviewable, and reversible.

This plan is about governance and operator workflow, not new schema work.

## Non-Goals

- replacing the existing `ApiProtection` middleware
- auto-blacklisting by default
- building a large moderation console in phase 1

## Decisions To Lock

1. Blacklist writes stay manual in the near term.
2. Every blacklist action should have an explicit reason and actor trail.
3. Temporary blacklist entries should be preferred over permanent ones unless abuse is persistent or severe.
4. Payment/webhook endpoints should be treated as high-sensitivity paths and reviewed more carefully before broad blocking.

## Scope

- blacklist governance rules
- operator runbook
- audit expectations for blacklist create/unblock/expire actions
- optional internal/admin tooling for safe management

## Out Of Scope

- WAF/CDN-level network blocking
- bot scoring or advanced reputation systems
- automated permanent bans

## Proposed Policy

### Entry Types

- temporary IP block
  - use for obvious bursts, scraping, or repeated form abuse
  - default expiry should be short and explicit
- temporary user-scope block
  - use for authenticated abuse tied to one account
- permanent block
  - use rarely, with owner approval or clear repeat abuse evidence

### Minimum Evidence

Before blacklisting, review:
- recent `ApiUsageLog` decisions
- relevant `ApiRequestCounter` spikes
- endpoint class involved
- whether the scope is an IP, a user, or both
- whether the traffic touched sensitive paths like payments, admin writes, or contact flows

### Required Metadata

Every blacklist action should record:
- actor
- scope type
- scope id
- reason code
- free-text note
- source evidence reference
- expires_at

## Delivery Phases

### Phase 1 — Policy + Audit Contract

- [ ] Define approved blacklist reason codes.
- [ ] Define temporary duration defaults by reason class.
- [ ] Define required metadata fields for every blacklist action.
- [ ] Define who can create and remove entries.

### Phase 2 — Safe Operator Surface

- [ ] Decide whether existing rake tasks are sufficient.
- [ ] If not, add a narrow internal/admin management surface for:
  - create blacklist entry
  - list active entries
  - expire/unblock entry
- [ ] Ensure every action writes `SystemAuditLog`.

### Phase 3 — Review + Expiry Workflow

- [ ] Add a recurring review workflow for active entries.
- [ ] Prefer expiring stale entries rather than letting them live indefinitely.
- [ ] Keep active blacklist records out of generic cleanup jobs unless explicitly expired/unblocked.

### Phase 4 — Higher-Risk Endpoint Rules

- [ ] Document stricter review expectations for:
  - `api.webhook.ingest`
  - payment-related paths
  - admin write paths
- [ ] Confirm that blocking decisions cannot silently break payment-provider callbacks.

## Done Criteria

- blacklist rules are written and operator-friendly
- blacklist create/remove actions are auditable
- expiry/review workflow exists
- payment/admin-sensitive paths have explicit blocking guidance
- the plan closes without requiring new schema work
