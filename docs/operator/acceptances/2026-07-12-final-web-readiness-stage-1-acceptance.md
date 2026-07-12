# Acceptance: Final Web Readiness Stage 1

Acceptance id: `shengfukung-2026-07-12-final-web-readiness-stage-1-acceptance`

Created: 2026-07-12

Reviewer: Wenfu Control

## Decision

accepted

## Scope Accepted

WR-1 through WR-3 of the final web-readiness plan are complete:

- repository and dependency baseline;
- complete automated regression;
- security, authority, tenant-isolation, and secret-handling review;
- bounded repair of the cross-temple owner-authority defect.

## Root Cause And Repair

Global `AdminAccount.owner_role?` was incorrectly used for selected-temple
authorization. An owner in temple A could inherit owner behavior in temple B
where the same account held only an admin membership.

The accepted repair makes `AdminTempleMembership.role` authoritative for
temple-scoped behavior:

- default permissions are owner-wide only for a membership that owns the
  selected temple;
- dashboard, patron management, archives, and account registration scope use
  selected-temple ownership;
- ordinary promotion into another temple creates an admin membership rather
  than copying a global owner role;
- revocation protects an owner membership in the selected temple while
  allowing removal of an admin-only membership there;
- stored ECPay HashKey and HashIV values have explicit non-rendering coverage.

The remaining global role check controls only non-production temple switching
among temples already assigned to the account. It does not widen production or
cross-temple authority.

## Independent Verification

Wenfu Control reviewed the complete diff and ran on the final tree:

- `bin/build_rails_css` -> pass;
- `cd rails && bin/rails db:migrate:status` -> pass, no pending migrations;
- full Rails suite -> `318 runs, 1792 assertions, 0 failures, 0 errors, 0 skips`;
- focused authority/tenant/payment/export suite -> `192 runs, 1283 assertions,
  0 failures, 0 errors, 0 skips`;
- `cd vue && npm run build` -> pass;
- `git diff --check` -> pass.

Historical `NO FILE` migration rows and Rack `:unprocessable_entity`
deprecation warnings are unchanged and remain documented non-blockers.

## Checksum Clarification

The retry packet checksum was produced from `git status --porcelain=v1`, while
the Handoff compared it with `git diff`. Control verified the expected
pre-dispatch status checksum before dispatch. The differing digests reflect
different inputs, not an unattributed worktree change.

## Remaining Readiness Work

- WR-4: synthetic offering intake-to-configuration proof;
- WR-5: local ECPay contract and setup closeout;
- WR-6 through WR-8: operational UX review, documentation reconciliation, and
  final binary readiness decision.

Real temple participation, a marketing manager, a Guide agent, and live ECPay
remain accepted non-blockers.

## Required Retry

None.

## Handoff Lifecycle

Replacement Wenfu Handoff `019f55bd-3447-74f3-8225-eabfdc511e64` remains
healthy, bound, and idle for the next bounded job.

## Promotion Allowed

No production promotion, deployment, secret access, or live payment-provider
action. Repository implementation acceptance only.
