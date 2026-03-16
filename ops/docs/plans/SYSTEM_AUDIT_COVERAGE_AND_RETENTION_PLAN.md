# SYSTEM AUDIT COVERAGE AND RETENTION PLAN

## Purpose

- Define what actions must be written to `SystemAuditLog`.
- Separate routine user self-service activity from higher-value admin and money-related audit trails.
- Define retention, cleanup, and access policy for audit data.

## Current State

Schema already exists:
- `system_audit_logs`
- `SystemAuditLog`
- `SystemAuditLogger`

Current observed usage:
- several admin actions already write audit logs
- some account actions write audit logs
- many account portal actions do not yet write audit logs
- retention and cleanup policy for `SystemAuditLog` is not clearly defined

Important current gap:
- payment and money-adjacent actions should be treated as high-value audit events
- account self-service actions need a deliberate policy so the app does not log everything blindly

## Goal

Make audit logging intentional:
- broad enough to support support, ops, and financial review
- narrow enough to avoid noisy, low-value logs and unclear retention

## Locked V1 Decisions

- Use a conservative logging policy in v1 to avoid low-value noise.
- Keep Tier 1 coverage mandatory for admin, access, privacy, and money-related actions.
- Keep Tier 2 coverage selective and focused on meaningful account self-service actions.
- Skip Tier 3 logging by default.
- Audit payment creation, refund, cancel, reconcile, manual override, and provider/system-driven status changes.
- Use canonical dotted action names such as:
  - `account.profile.updated`
  - `account.password.added`
  - `account.oauth.unlinked`
  - `admin.payments.refunded`
  - `system.payments.reconciled`
- Retention windows for v1:
  - Tier 1: 2 years
  - Tier 2: 180 days
  - Tier 3: do not log unless explicitly justified
- Do not add a cleanup job until coverage and retention are both locked in code.
- When cleanup is added later, Tier 1 money/access/privacy logs must be excluded from broad deletion.

## Non-Goals

- event sourcing
- full historical diff capture for every model change
- logging every page view or every read action

## Current Coverage Snapshot

Already audited in code:
- some admin content and patron actions
- archive export actions
- assistance request close actions
- offering/service/event updates in some paths
- OAuth link/unlink actions
- some preference/theme updates
- cash payment recorder and registration builder flows

Clearly not comprehensive yet:
- account profile updates
- password added/changed flows
- dependent create/update/destroy
- account registration edits and checkout actions
- contact temple request creation
- account privacy actions
- admin payment checkout/refund/reconciliation actions
- admin session/login-sensitive actions, if desired

## Audit Tiers

### Tier 1 — Mandatory Retention

These should always be logged and retained longest:
- admin permission and role changes
- temple access grants/revokes
- payment creation, refund, cancel, reconcile, manual override
- registration state changes that affect money or entitlement
- exports of financial or privacy-sensitive data
- privacy request transitions and account closure decisions

### Tier 2 — Strongly Recommended

- account profile changes
- password add/change/reset completion
- OAuth identity link/unlink
- dependent create/update/destroy
- account registration create/update/cancel
- contact/support request submissions

### Tier 3 — Usually Skip

- ordinary reads
- routine page visits
- harmless preference tweaks unless support value is clear

## Required Audit Fields

Every meaningful audit event should include, when applicable:
- action
- occurred_at
- actor type and actor id
- temple id
- target type and target id
- metadata with the minimum useful support context

For money-related actions, metadata should also include:
- payment id or reference
- registration/order reference
- action source
  - user self-service
  - admin action
  - webhook/provider callback
  - system reconciliation
- before/after status where relevant

## Retention Proposal

### Tier 1

- retain for at least 2 years
- do not auto-delete casually

### Tier 2

- retain for 180 to 365 days unless support/legal needs require longer

### Tier 3

- usually do not write these logs

## Cleanup Policy

- do not add cleanup until retention classes are locked
- any cleanup job must be explicit, dry-run capable, and documented
- money-related and access-related audit events should be excluded from broad deletion

## Delivery Phases

### Phase 1 — Coverage Inventory

- [ ] Inventory all current `SystemAuditLogger.log!` call sites.
- [ ] Inventory high-value account and admin actions with no audit logging yet.
- [ ] Group actions into Tier 1, Tier 2, or skip.

### Phase 2 — Contract Tightening

- [ ] Define canonical audit action naming conventions.
- [ ] Define minimum metadata requirements per action family.
- [ ] Decide whether `SystemAuditLogger` should support explicit non-admin user actors more cleanly.

### Phase 3 — Coverage Expansion

- [ ] Add missing account audit logs for selected Tier 1 and Tier 2 actions.
- [ ] Add missing admin money-flow audit logs.
- [ ] Add tests for high-value audit events.

### Phase 4 — Retention + Access Policy

- [ ] Lock retention windows by audit tier.
- [ ] Decide who can view/export audit logs.
- [ ] Add cleanup tooling only after retention policy is approved.

## Done Criteria

- high-value admin and payment actions are auditable
- account portal logging policy is explicit instead of accidental
- retention windows are written down
- cleanup is defined or intentionally deferred
- tests cover the most important audit-producing flows
