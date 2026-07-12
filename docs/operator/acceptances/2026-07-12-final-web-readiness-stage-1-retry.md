# Retry Required: Final Web Readiness Stage 1

Decision id: `shengfukung-2026-07-12-final-web-readiness-stage-1-retry`

Created: 2026-07-12

Reviewer: Wenfu Control

## Decision

retry_required

## Accepted Work

The interrupted Handoff found and repaired a real cross-temple authority defect:

- global `AdminAccount.owner_role?` could grant owner fallback permissions in
  a temple where the account held only an admin membership;
- account API registration scope could expose temple-wide registrations in an
  admin-only temple;
- the repair adds temple-scoped ownership helpers and regression coverage;
- stored ECPay HashKey and HashIV values are now explicitly covered by a
  non-rendering integration regression.

Independent Control verification passed:

- repo-root `bin/build_rails_css`;
- `cd rails && bin/rails db:migrate:status` with no pending migrations;
- full Rails suite: `316 runs, 1780 assertions, 0 failures, 0 errors, 0 skips`;
- focused Rails suite: `190 runs, 1271 assertions, 0 failures, 0 errors, 0 skips`;
- `cd vue && npm run build`;
- `git diff --check`.

## Retry Reason

The authority model is not yet internally consistent. Two temple-scoped
promotion/revocation paths still derive behavior from the global account role:

1. `Admin::PatronAdminManager#ensure_membership!` creates a new temple
   membership with `role: admin_account.role`. An owner of temple A promoted
   into temple B can therefore become owner of temple B automatically.
2. `Admin::PatronAdminManager#revoke!` refuses removal whenever
   `admin_account.owner_role?` is true. An owner of temple A therefore cannot
   have an admin-only membership removed from temple B.

This is a bounded continuation of the same root cause. Accepting the current
diff without resolving it would leave a split global-versus-tenant authority
model.

## Required Retry

- Treat `AdminTempleMembership.role` as authoritative for temple-scoped owner
  behavior.
- Promotion through `PatronAdminManager` must create an admin membership for
  the selected temple unless a separate explicit owner-promotion workflow is
  invoked.
- Revocation must block removal of an owner membership in the selected temple,
  but permit removal of an admin membership there even if the account owns a
  different temple.
- Audit the remaining application uses of `owner_role?`; either convert
  temple-scoped authorization to membership ownership or document why a use is
  global/development-only and cannot widen tenant authority.
- Add focused regressions for cross-temple promotion and revocation.
- Rerun the complete stage-one check set on the final tree.

## Handoff Lifecycle

Handoff `019f5519-0f72-7273-b50e-65739e5a2a36` became interrupted and
unavailable before its terminal wake/return and was archived. Replacement
Handoff `019f55bd-3447-74f3-8225-eabfdc511e64` is exclusively bound to Wenfu
Control.

## Promotion Allowed

None. No production, deployment, or live provider action is authorized.
