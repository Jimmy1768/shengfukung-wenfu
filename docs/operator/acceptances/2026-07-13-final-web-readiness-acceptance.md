# Acceptance: Final Web Readiness

Acceptance id: `shengfukung-2026-07-13-final-web-readiness-acceptance`

Created: 2026-07-13

Reviewer: Wenfu Control

## Decision

ready

## Scope Accepted

WR-1 through WR-8 of the final web-readiness and Expo-gate plan are complete.
The Shengfukung Wenfu web product is technically ready for operator-assisted
temple onboarding.

This decision permits the owner to hire a marketing manager and begin Expo
implementation. The first approved temple may be onboarded jointly through the
documented human-verification, account-promotion, offering-intake, YAML
translation, audit, and apply workflow.

## Evidence Accepted

- WR-1 through WR-3 acceptance, including the repaired cross-temple owner
  authority defect: commit `a36cbd922fa86ca654aa6c21ade11dbb1dd51965`.
- WR-4 and WR-5 synthetic offering and local ECPay proof: commit
  `432b28bc695d45379306f470ffb5c6b77294ffbc`.
- WR-6 through WR-8 packet base: commit
  `00f9c4c559d2c69054ec82985e1f03cf92562f2b`.
- WR-6 through WR-8 evaluation and structured return, independently reviewed
  by Wenfu Control.
- Account/admin source, compiled CSS, and integration evidence showed no
  concrete operational UX blocker. Direct browser control was unavailable;
  the governing plan explicitly permits this evidence fallback.
- Current-source documentation consistently distinguishes local web readiness
  from production promotion and live provider verification.

## Independent Verification

Wenfu Control ran on the finished tree:

- `bin/build_rails_css` -> pass;
- `cd rails && bin/rails test test/integration/account test/integration/admin`
  -> `149 runs, 1093 assertions, 0 failures, 0 errors, 0 skips`;
- `cd rails && bin/rails test` ->
  `324 runs, 1846 assertions, 0 failures, 0 errors, 0 skips`;
- `cd vue && npm run build` -> pass;
- `ruby ops/scripts/audit_offering_configs.rb` -> pass after the expected
  sandbox-only local PostgreSQL restriction was lifted;
- required current-source documentation reconciliation scan -> pass;
- `git diff --check` -> pass.

Rack's `:unprocessable_entity` deprecation warning remains non-blocking output;
it produced no test failure or behavior defect.

## Accepted Gaps

- No real temple or real offering intake was required for this code-readiness
  proof.
- Live ECPay merchant configuration, callback reachability, settlement,
  payment, and refund verification remain first-approved-temple rollout work.
- The broader-rollout help guide and optional future Guide agent remain later
  work.
- Direct browser interaction was unavailable for WR-6; the accepted fallback
  evidence was sufficient and found no concrete blocker.

These are rollout boundaries, not bugs and not blockers to hiring or Expo work.

## Production Boundary

This acceptance does not authorize deployment, production promotion, DNS/TLS
or server changes, production migrations or data access, secret access, real
ECPay actions, external submissions, customer-state changes, or legal,
accounting, settlement, tax, or regulatory claims.

## Required Retry

None.

## Handoff Lifecycle

Wenfu Handoff `019f55bd-3447-74f3-8225-eabfdc511e64` remains healthy, bound,
and idle for the next bounded job.

## Promotion Allowed

Marketing-manager hiring and Expo implementation planning/development may
begin. Production and live-provider promotion remain separately gated.
