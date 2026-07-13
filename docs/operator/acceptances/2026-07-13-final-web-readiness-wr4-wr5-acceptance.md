# Acceptance: Final Web Readiness WR-4 And WR-5

Acceptance id: `shengfukung-2026-07-13-final-web-readiness-wr4-wr5-acceptance`

Created: 2026-07-13

Reviewer: Wenfu Control

## Decision

accepted

## Scope Accepted

WR-4 and WR-5 of the final web-readiness plan are complete.

WR-4 now has a replayable proof that:

- a human-facing, non-secret synthetic intake can be translated by an operator
  into the supported temple profile and offering YAML contracts;
- temple staff do not edit YAML;
- the synthetic temple bootstraps and the service offering is ensured as draft;
- rerunning ensure is idempotent;
- template sync repairs stale metadata without duplicate creation;
- the configured offering reaches the real admin order and account
  payment-status contracts;
- transactional tests clean up all synthetic database state automatically.

WR-5 now has a complete local/stubbed evidence matrix for:

- ECPay as the intended non-test Taiwan provider and fake as the test default;
- hosted checkout payload and environment selection;
- owner-gated Merchant ID, HashKey, and HashIV setup;
- non-rendering and non-logging of stored secret values;
- pending, completed, failed/cancelled, duplicate webhook, refund, accounting,
  and export application semantics.

## Operational Guard Retry

The initial review found that the new `SLUG=<slug>` audit/sync option silently
succeeded for an unknown temple. The accepted retry makes both scripts fail
closed with `Unknown SLUG: <slug>` and non-zero exit status while preserving
global no-`SLUG` behavior.

## Independent Verification

Wenfu Control reviewed the complete implementation and ran:

- global offering-config audit -> pass;
- unknown-slug audit -> exit `1` with concise expected error;
- unknown-slug sync -> exit `1` with concise expected error;
- focused WR-4 suite -> `40 runs, 439 assertions, 0 failures, 0 errors, 0 skips`;
- focused WR-5 suite -> `79 runs, 434 assertions, 0 failures, 0 errors, 0 skips`;
- full Rails suite -> `324 runs, 1846 assertions, 0 failures, 0 errors, 0 skips`;
- `git diff --check` -> pass.

## Accepted Gaps

- no real temple or intake submitter;
- one synthetic service path rather than every future offering shape;
- event apply remains outside this proof because scheduling intake is a
  separate future capability;
- no real ECPay merchant account, credentials, callback reachability, payment,
  settlement, or refund;
- the synthetic offering remains draft/non-live.

These are rollout or future-capability boundaries, not blockers or bugs for the
current web-readiness checkpoint.

## Remaining Readiness Work

- WR-6: account/admin and operational UX review;
- WR-7: current-source documentation reconciliation;
- WR-8: final Git/evidence closeout and binary `ready` or `not_ready` decision.

## Required Retry

None.

## Handoff Lifecycle

Wenfu Handoff `019f55bd-3447-74f3-8225-eabfdc511e64` remains healthy, bound,
and idle for the next bounded job.

## Promotion Allowed

No production promotion, deployment, secret access, published offering
activation, or live payment-provider action. Repository readiness acceptance
only.
