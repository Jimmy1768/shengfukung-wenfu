# REGISTRATION LIFECYCLE EDIT POLICY PLAN

## Purpose

- Define one shared edit policy for registrations across both Admin and Account portals.
- Replace portal-specific lock behavior with lifecycle-based rules.

## Scope

- Applies to all registrable types: `TempleEvent`, `TempleService`, `TempleGathering`.
- Applies to both entry channels:
  - admin-created registrations
  - patron-created registrations

## Canonical Rule

- `Pending` registrations are editable.
- Once any payment is recorded (cash/online/bank transfer), core registration fields become immutable.
- For gathering attendance:
  - no metadata sections to edit
  - keep view-only after creation.

## Field Policy

### Core Immutable Fields (after payment exists)

- `user_id` (patron)
- `metadata.registrant_scope`
- `metadata.dependent_id`
- `metadata.registrant_name`
- `quantity`
- `unit_price_cents`
- `currency`

### Mutable While Pending

- All core fields above.
- Offering-specific metadata fields (`contact_payload`, `logistics_payload`, `metadata` ritual keys), subject to schema.

### Mutable After Payment

- Non-financial metadata only (if needed by workflow).
- Never mutate identity/order totals after payment.

## Workflow Implications

- Staff can correct pending registrations before payment collection.
- After payment:
  - do not edit identity/order fields
  - correction path is refund/void + create replacement registration.

## Current Status

- Admin: gathering edit actions/routes are now hidden/blocked (view-only after creation).
- Admin: `Primary contact` section is editable while pending and read-only after payment exists.
- Shared/core lifecycle service is now extracted (`Registrations::LifecyclePolicy`) and used by Admin + Account flows.

## Implementation Phases

### Phase A: Shared Policy Gate (Backend)

- [x] Add shared policy helper/service:
  - `editable_core_fields?(registration)` / `core_fields_editable?(registration)`
  - `editable_metadata_fields?(registration)` / `metadata_fields_editable?(registration)`
- [x] Centralize payment lock check (`registration.temple_payments.exists?` or equivalent).
- [x] Enforce strong server-side filtering for immutable fields after payment.

### Phase B: Admin UX Alignment

- [x] In admin edit forms:
  - pending: show editable core fields
  - paid: show core fields as read-only (or hidden), metadata-only edit
- [x] Keep gathering edit action hidden/view-only.
- [x] Add inline helper text when lock is active.

### Phase C: Account UX Alignment

- [x] Mirror same pending vs paid behavior in account edit flow.
- [x] Ensure patron cannot mutate core fields after payment.
- [x] Keep duplicate-guard behavior consistent with registrant scope identity.

### Phase D: Regression Coverage

- [x] Add integration tests for both portals:
  - [x] pending allows core field edits
  - [x] paid blocks core field edits
  - [x] metadata edits remain allowed where intended
  - [x] gathering edit remains view-only

## Related Future Work (Deferred)

- Pending registration expiry / hold release policy for capacity protection:
  - [x] define hold duration (`expires_at`)
  - [x] auto-cancel stale unpaid registrations
  - [x] release capacity on expiration
  - [ ] optional reminder notifications before expiration
    - [ ] Add notification events:
      - `registration.expiring_soon` (for example, 24 hours before `expires_at`)
      - `registration.expired` (when hold is released)
    - [ ] Notify both audiences:
      - patron (`registration.user_id`)
      - temple admins for the same `temple_id`
    - [ ] Channel behavior:
      - Expo/mobile push (when device-token linkage is finalized)
      - email
      - web in-app alert/badge state
    - [ ] Respect notification preferences/rules:
      - user-level channel preference (`push`, `email`, `both`, or disabled)
      - event-level enable/disable via `notification_rules`
    - [ ] Add safe fallback:
      - when push is unavailable, attempt email if enabled
      - log notification delivery outcomes for auditing
    - [ ] Add tests:
      - expiring-soon event fan-out to patron + admins
      - expired event fan-out to patron + admins
      - preference opt-out respected per channel
