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
- account profile update
- account password add from settings
- account dependent create/update/delete
- account registration create/update
- account checkout start/return
- account privacy request create and account closure
- account contact temple request create
- account assistance request create
- admin payment create and hosted checkout start/return
- system payment reconciliation during checkout return
- system refund/cancel lifecycle events

Clearly not comprehensive yet:
- password changed/reset completion beyond the current add-password path
- admin refund/cancel/reconciliation/manual payment actions beyond checkout start/return
- registration status changes tied to payment outcomes outside the current checkout-return reconciliation path
- admin session/login-sensitive actions, if desired

### Phase 1 Inventory Findings

Current `SystemAuditLogger.log!` call sites observed:

- account:
  - `account.oauth.link_started`
  - `account.oauth.unlinked`
  - `preferences.theme_updated`
- admin:
  - offerings create/update
  - services create/update
  - events create/update
  - patrons create
  - assistance request close
  - archive export
- internal/high-trust:
  - privacy request transitions
  - temple access grant/promote/revoke
- money/supporting flows:
  - cash payment recorder
  - registration builder
- media/supporting flows:
  - managed uploader
  - hero image uploader
- auth/system:
  - central OAuth flow writes at least one audit event already

High-value actions currently missing or not clearly covered:

- Tier 1 gaps:
  - admin refund/cancel/reconcile/manual payment actions
  - registration status changes tied to payment outcomes outside checkout-return reconciliation
  - admin permission updates are not yet confirmed here
  - temple profile/content edits outside existing audited forms are not yet confirmed here
- Tier 2 gaps:
  - account password change/reset completion outside the add-password path

Current skip candidates unless later justified:

- account/admin locale changes
- theme/display preference changes beyond the current targeted preference audit
- session login/logout events
- ordinary reads and page visits

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

## Phase 2 Contract Decisions

### Canonical Action Naming

Use dotted names with actor surface first, then domain, then verb:

- account:
  - `account.profile.updated`
  - `account.password.added`
  - `account.password.changed`
  - `account.registration.created`
  - `account.registration.updated`
  - `account.payment.checkout_started`
- admin:
  - `admin.payments.created`
  - `admin.payments.refunded`
  - `admin.payments.reconciled`
  - `admin.permissions.updated`
  - `admin.temple_profile.updated`
- system:
  - `system.payments.reconciled`
  - `system.payments.webhook_applied`
  - `system.payments.status_corrected`
- internal:
  - `internal.privacy_requests.transitioned`
  - `internal.temple_access.revoked`

Rules:
- prefer past-tense result names for completed actions
- use `started` only for intentionally logged start events such as checkout initiation
- avoid inconsistent mixes like `create`, `created`, `update`, `updated` in the same action family

### Minimum Metadata By Action Family

Profile/account self-service:
- changed field list only
- avoid storing raw sensitive values

Password actions:
- action source
- whether this was add vs change vs reset completion
- never store password material

OAuth identity actions:
- provider
- identity id when available

Registration actions:
- registration reference/id
- offering/service/event reference if applicable
- before/after status when status changed

Payment actions:
- payment id/reference
- registration/order reference
- provider
- action source
- before/after status
- idempotency or provider reference only when useful for reconciliation
- never store secrets, tokens, or raw sensitive provider payloads in `SystemAuditLog`

Privacy/access/admin permission actions:
- target actor or target resource
- before/after role or status when changed
- reason/note when manually triggered

Export actions:
- export type
- scope summary
- actor

### User Actor Handling (V1)

- Keep using `SystemAuditLogger` in v1.
- Continue passing `current_user` where account-side actions need an actor recorded.
- Do not redesign the schema/logger yet.
- If account-side coverage becomes awkward or ambiguous during implementation, add a small logger API refinement in a later focused pass instead of blocking Phase 3.

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

- [x] Inventory all current `SystemAuditLogger.log!` call sites.
- [x] Inventory high-value account and admin actions with no audit logging yet.
- [x] Group actions into Tier 1, Tier 2, or skip.

### Phase 2 — Contract Tightening

- [x] Define canonical audit action naming conventions.
- [x] Define minimum metadata requirements per action family.
- [x] Decide whether `SystemAuditLogger` should support explicit non-admin user actors more cleanly.

### Phase 3 — Coverage Expansion

- [~] Add missing account audit logs for selected Tier 1 and Tier 2 actions.
- [~] Add missing admin money-flow audit logs.
- [~] Add tests for high-value audit events.

Phase 3 progress:
- added account audit logs for:
  - profile update
  - password add from settings
  - dependent create/update/delete
  - registration create/update
  - payment checkout start/return
- added admin payment audit logs for:
  - cash payment create
  - hosted checkout start
  - hosted checkout return
- added system payment reconciliation audit log for checkout return processing
- added account audit logs for:
  - privacy request create
  - account closure
  - contact temple request create
  - assistance request create
- added system payment audit logs for:
  - refund
  - cancel
- added integration coverage for the new account/admin audit-producing flows

Remaining in Phase 3:
- admin refund/cancel/reconcile/manual override flows
- broader payment lifecycle audit coverage beyond checkout return

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
