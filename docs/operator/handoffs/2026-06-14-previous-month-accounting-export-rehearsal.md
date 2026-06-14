# Handoff: Previous-Month Accounting Export Rehearsal

Handoff id: `shengfukung-2026-06-14-previous-month-accounting-export-rehearsal`

Created: 2026-06-14

Coordinator: Shengfukung Wenfu coordinator/implementation thread

Target: Shengfukung Wenfu implementation thread

Mode: local prototype implementation/QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Rehearse and verify the V1 previous-month accounting export process:

- on the 1st day of each month, admin selects the previous month/last month payment preset;
- admin exports the filtered payments CSV;
- CSV contains enough owner, purpose, amount, method, status, source, provider, reference, timestamp, and recorded-by information for external accounting handoff;
- no in-app accounting close/lock state is required for V1.

This pass should produce durable evidence that the admin/browser workflow and request-level export behavior match the accepted V1 accounting decisions.

## Required Context

Read before implementation:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-v1-admin-accounting-policy-readiness-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-ecpay-default-path-local-verification-return.md`

## Required Review

Review the current Rails admin payment export flow:

- admin payments index;
- month preset links;
- export link;
- payment filter normalization;
- admin payments export controller action;
- payment CSV exporter;
- existing admin payments/export tests.

## Implementation Scope

If a small gap is found, implement it narrowly.

Likely acceptable changes:

- make CSV export honor the same `month_preset` semantics as the payments page;
- add a focused request test proving `month_preset: last_month` exports the previous calendar month;
- add or verify CSV field coverage for owner, purpose, amount, method, status, source, provider/reference, timestamp, and recorded-by;
- run local browser/admin rehearsal against the isolated review server.

## Non-Goals

- Do not add a formal month close/lock state.
- Do not add settlement reconciliation.
- Do not add export-history tracking.
- Do not change payment status semantics.
- Do not call real payment providers.
- Do not change payment provider configuration.
- Do not deploy.
- Do not change server configuration.
- Do not access or rotate secrets.
- Do not touch production data.
- Do not work on mobile or Expo.
- Do not build the help guide yet.
- Do not move existing `ops/docs/` history.

## Acceptance Criteria

- Admin payments page exposes the previous-month guidance and last-month preset.
- Export endpoint produces previous-calendar-month CSV when using the last-month preset.
- CSV includes V1 handoff fields for accounting review.
- Browser/admin rehearsal confirms the visible workflow locally.
- Focused Rails tests pass.
- No production-readiness, deployment, provider-configuration, or legal/accounting-finality claim is made.

## Verification

Run focused tests based on touched files. At minimum, run:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/services/reporting/payments_csv_exporter_test.rb
```

Also run:

```bash
git diff --check
```

Use local browser review because this is an admin/browser workflow rehearsal.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- reviewed decision/context records;
- implementation summary;
- files changed;
- verification commands and results;
- browser/admin evidence;
- skipped checks and reasons;
- production/provider/secret/data boundary confirmation;
- residual risk;
- follow-up gaps;
- next owner.

Also create matching eval, acceptance, and execution records if the workflow completes.

Do not paste full records in chat when files exist.
