# Handoff: V1 Admin Accounting Policy Readiness

Handoff id: `shengfukung-2026-06-13-v1-admin-accounting-policy-readiness`

Created: 2026-06-13

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: local prototype implementation/QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Implement the next bounded Rails/admin pass from the accepted V1 product decisions:

- accounting is useful enough when admins can identify payment owner, purpose, amount, method, status, next action, and audit trail without developer help;
- ECPay is the default online payment method for Taiwan temples;
- cash is allowed as an admin-attested receipt event;
- current V1 payment statuses remain `pending`, `completed`, `failed`, and `refunded`;
- cancelled or failed payment attempts should not count as received;
- V1 monthly accounting export is manual/external, supported by filters and CSV export;
- previous-month export should happen on the 1st day of each month for the previous calendar month in the temple local timezone;
- no in-app close/lock state is required for V1.

The implementation should make the existing admin accounting surfaces express these decisions clearly, without broad accounting redesign.

## Required Context

Read before implementation:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-help-guide-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-accounting-reconciliation-readiness-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-payment-status-locale-cleanup-return.md`

## Required Review

Review the current Rails admin/payment surfaces for small V1 policy gaps:

- admin payments ledger;
- admin payments filter/month presets;
- admin payments CSV export fields;
- admin orders payment/status cues;
- cash payment `Received` flow and audit fields;
- ECPay/provider status display at the local code level only;
- refund/cancel admin-facing status copy;
- localized admin copy around monthly export and payment truth.

## Implementation Scope

If small gaps are found, implement them narrowly.

Likely acceptable changes:

- add or clarify admin copy explaining ECPay-confirmed vs cash/admin-attested payment truth;
- add or clarify copy around using the `last month` preset/export for the 1st-day previous-month accounting process;
- ensure payment method/source, status, recorded-by/admin, processed timestamp, and provider/manual reference are visible or exported where already structurally available;
- keep status labels consistent with the existing four-state model;
- add focused tests for any changed admin copy, ledger fields, or CSV fields.

If a gap requires a larger model, provider, settlement, month-close, or status-history design, record it as residual risk/follow-up instead of implementing it in this pass.

## Non-Goals

- Do not add a full reconciliation subsystem.
- Do not add a formal accounting close/lock state.
- Do not add provider settlement batch matching.
- Do not add a general ledger.
- Do not add a new payment status unless a hard local bug forces it and it stays fully scoped.
- Do not change payment provider configuration.
- Do not call real payment providers.
- Do not touch real ECPay merchant configuration.
- Do not deploy.
- Do not change server configuration.
- Do not access or rotate secrets.
- Do not touch production data.
- Do not work on mobile or Expo.
- Do not build the comprehensive help guide yet.
- Do not add public/admin help-guide links yet.
- Do not move existing `ops/docs/` history.

## Acceptance Criteria

- Admin accounting/payment surfaces communicate the accepted V1 source-of-truth policy clearly:
  - ECPay online payment is provider-confirmed when completed;
  - cash is admin-attested when marked received;
  - failed/cancelled attempts are not received;
  - refunds are clearly not completed revenue.
- Previous-month export workflow is understandable from the admin payments surface or CSV/export affordance.
- Existing payment CSV export remains intact and, if changed, includes enough fields for owner, purpose, amount, method, status, timestamp, and reference/audit trail.
- Focused tests pass for changed admin payments/orders/export behavior.
- Browser or request-stack evidence confirms any user-facing admin copy change.
- No production-readiness, deployment, provider-configuration, or legal/accounting-finality claim is made.

## Verification

Run focused tests based on touched files. At minimum, if admin payments/export behavior changes, run:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb
```

Also run:

```bash
git diff --check
```

Use local browser review if rendered admin copy/layout changes.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- reviewed decision records;
- implementation summary;
- files changed;
- verification commands and results;
- browser/request evidence if applicable;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation;
- payment/provider/production-data boundary confirmation;
- residual risk;
- follow-up gaps;
- next owner.

Also create matching acceptance, execution, and eval records if the workflow completes.

Do not paste full records in chat when files exist.
