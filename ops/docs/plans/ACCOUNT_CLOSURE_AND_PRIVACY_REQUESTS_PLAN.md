# Account Closure And Privacy Requests Plan

## Goal

Define a compliant, operationally safe account-closure flow that:

- removes a user's future access,
- preserves registrations, payments, certificates, and audit history,
- exposes visible self-service privacy actions required for app-store review,
- works on web now and remains valid for future Expo/mobile clients.

## Current State

- Account closure exists and is implemented as soft closure, not hard delete.
- Users can reach `/account/privacy` and submit:
  - `Close account`
  - `Request deletion of personal data`
  - `Request data export`
- Internal operators can review requests in `/internal/privacy_requests`.
- Data export requests can now be fulfilled into a downloadable JSON export.
- Full anonymization/deletion execution is still not built.

## Product Decision

Use `Close account`, not hard `Delete account`.

Behavior:

- account access is disabled,
- historical registrations/payments remain,
- linked login methods are revoked,
- profile becomes inactive and hidden from normal active-account flows,
- later anonymization can happen under an explicit retention policy.

## Why Soft Delete

Temple systems are not pure social apps. They hold:

- ritual/service registrations,
- payment history,
- certificates/receipts,
- audit logs,
- possible legal/accounting records.

Deleting the user row outright would weaken data integrity and create reporting/audit gaps.

So the correct model is:

- access closure now,
- retention-preserving archival,
- optional delayed anonymization later.

## Target Data Model

Add account lifecycle fields to `users`, for example:

- `account_status`
  - `active`
  - `closed`
- `closed_at`
- `closure_reason`
  - `self_service`
  - `operator_action`
  - `privacy_request`
- `anonymized_at` (future)

Do not physically delete the user row during normal account closure.

## Closure Effects

When a user closes their account:

1. disable future authentication
   - revoke password login
   - revoke refresh tokens / push tokens / active sessions
   - unlink or revoke OAuth identities

2. preserve history
   - keep registrations
   - keep payments
   - keep certificates
   - keep audit logs

3. remove active operational presence where appropriate
   - hide from active account lists
   - prevent new registrations/payments while closed

4. record an audit event
   - who initiated closure
   - when
   - why

## Privacy Request Surface

The product should expose a dedicated privacy page, not hide this inside support copy.

Recommended web entry:

- `/account/privacy`

Recommended actions on that page:

1. `Close account`
   - visible and explicit
   - requires confirmation

2. `Request deletion of personal data`
   - visible and explicit
   - explains what can and cannot be deleted immediately

3. `Request data export`
   - optional but useful
   - now fulfilled through an internal review + generated JSON export flow

## Important Wording

Be precise. App stores care that deletion/privacy actions are discoverable, but the product still needs to be truthful.

Use copy like:

- `Close account`
- `Request deletion of personal data`
- `Some records such as registrations, payments, receipts, and audit logs may be retained where operational or legal obligations apply.`

Avoid misleading copy like:

- `Delete everything forever`

if the system is actually retaining operational/financial records.

## Expo / App Store Requirement

For future Expo/mobile clients, this must be overt and easy to find.

Required mobile product rule:

- include an in-app account closure path,
- include an in-app privacy/data deletion page or entry point,
- do not force users to leave the app and email support just to satisfy the review requirement.

Recommended Expo placement:

1. `Account`
2. `Privacy & account`
3. actions:
   - `Close account`
   - `Request deletion of personal data`
   - `Request data export`

This is important for Apple/Google review even if the backend implementation remains retention-aware and non-destructive.

## Reviewer Scope For V1

Minimal compliant interpretation for this product:

- Apple: the app must provide an in-app path to initiate account deletion.
- Google: deactivation alone is not enough; the deletion path must lead to actual removal or anonymization of personal account data.

So v1 should not stop at:

- `Close account`
- or a pending deletion request with no fulfillment

V1 should include:

- visible in-app privacy actions
- internal operator handling for deletion requests
- real anonymization of the account identity when a deletion request is completed
- explicit disclosure that registrations, payments, receipts, and audit records may be retained for operational or legal reasons

## Backend Enforcement Rules

Closed accounts should:

- be unable to sign in,
- be unable to start new registrations,
- be unable to create new payments,
- remain resolvable for historical records and admin reporting.

Admins/operators should still be able to:

- view historical records tied to the closed user,
- see that the account is closed,
- inspect closure audit metadata.

## Phase Plan

### Phase 1: Runtime model + web controls

- [x] Add lifecycle fields to `users`
- [x] Add model helpers:
  - `active_account?`
  - `closed_account?`
- [x] Block sign-in for closed accounts
- [x] Add `/account/privacy`
- [x] Add self-service `Close account`
- [x] Add audit logging for closure

### Phase 2: Privacy request workflow

- [x] Add `Request deletion of personal data` flow
- [x] Add `Request data export` flow
- [x] Record request rows / audit metadata
- [x] Add operator/admin visibility for privacy requests
- [x] Add operator review transitions:
  - `approve`
  - `reject`
  - `complete`
- [x] Fulfill completed data export requests into downloadable JSON
- [x] Define v1 anonymization scope for completed deletion requests:
  - anonymize core account identity
  - revoke/remove login methods
  - preserve registrations/payments/audit history

### Phase 3: Retention/anonymization policy

- [ ] Decide retention windows for profile/contact data
- [x] Implement minimal v1 anonymization on deletion completion
- [ ] Preserve registration/payment/audit integrity while minimizing stored PII
- [ ] Expand anonymization review to historical registration/contact payloads if required

### Phase 4: Expo/mobile parity

- [ ] Add `Privacy & account` screen in Expo
- [ ] Expose visible `Close account` action
- [ ] Expose visible privacy deletion request action
- [ ] Verify Apple/Google reviewer discoverability

## Open Questions

1. Which data must be retained for finance/compliance, and for how long?
2. Should closed users be allowed to reopen the same account later?
3. Should OAuth-linked closure revoke identities immediately or retain them in a revoked state for audit?
4. Do we want self-service export before full deletion workflow, or can export remain operator-assisted initially?

## Recommendation

Build this as:

- `account closure + privacy requests`,
- not `hard delete account`.

That gives:

- correct operational behavior,
- clear privacy posture,
- app-store-compliant UX,
- minimal damage to temple reporting and financial history.

## Reviewer Compliance Note

Current web status:

- users can clearly find `Privacy & account` from the account surface,
- users can clearly find:
  - `Close account`
  - `Request deletion of personal data`
  - `Request data export`

This satisfies the important discoverability part of Apple/Google reviewer expectations on web.

For Expo/mobile, the equivalent entry points must be visible in-app, not hidden behind support-only instructions.

## Built And Tested

Built now:

- lifecycle fields on `users` for account closure state
- `privacy_requests` workflow model
- closed-account auth guards across account/admin/OAuth sign-in paths
- `/account/privacy` self-service page
- self-service `Close account`
- self-service `Request deletion of personal data`
- self-service `Request data export`
- internal privacy request review queue at `/internal/privacy_requests`
- operator transitions:
  - `approved`
  - `rejected`
  - `completed`
- export fulfillment for `data_export` requests
- downloadable JSON export for completed export requests
- deletion fulfillment for `data_deletion` requests:
  - close account if still active
  - anonymize core account identity
  - remove linked OAuth identities
  - scrub basic preference/privacy metadata

Focused tests verified during build:

```bash
cd rails && bin/rails test test/integration/account/privacy_flow_test.rb test/integration/internal/privacy_requests_test.rb
```

Result:

- `8 runs, 49 assertions, 0 failures, 0 errors`

Also previously verified in focused suites:

- account closure runtime/model behavior
- closed-account auth blocking
- admin closed-account guard

Not built yet:

- actual anonymization execution for approved/completed deletion requests
- export artifact delivery beyond internal operator download
- request detail page with operator notes
