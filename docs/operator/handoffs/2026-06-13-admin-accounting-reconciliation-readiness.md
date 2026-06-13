# Handoff: Admin Accounting Reconciliation Readiness

Handoff id: `shengfukung-2026-06-13-admin-accounting-reconciliation-readiness`

Created: 2026-06-13

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: local prototype implementation/QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Run a bounded reconciliation-readiness pass on the admin accounting flow.

The previous large-data QA proved that admin payments/orders pages render and remain usable with large local data. The remaining accounting risk is whether an admin can understand and reconcile the status of individual payments/orders, including cash, provider, pending, failed, refunded, and cancelled cases.

## Required Review

Review the local code and focused tests for:

- admin payments ledger visibility;
- payment status visibility;
- cash payment records;
- provider checkout returns/webhooks at the local code level only;
- refund/cancel service behavior;
- CSV export fields;
- order/payment traceability from admin surfaces.

If a small bounded reconciliation gap is found, implement it and add focused tests.

## Non-Goals

- Do not add a full reconciliation subsystem.
- Do not integrate or call real payment providers.
- Do not change payment provider configuration.
- Do not change production data.
- Do not deploy.
- Do not change server configuration.
- Do not rotate or access secrets.
- Do not work on mobile or Expo.
- Do not redesign accounting.
- Do not move existing `ops/docs/` history.

## Likely Acceptance Criteria

- Admin-visible payment rows expose enough status information to distinguish completed, pending, failed, and refunded payment records.
- Existing CSV export remains intact.
- Focused tests cover the bounded reconciliation behavior.
- Browser or request-stack evidence confirms the admin-visible result.
- No production-readiness claim is made.

## Verification

Run focused tests covering admin orders/payments, payment flow, refunds if touched, exports, and gathering accounting behavior.

Also run:

```bash
git diff --check
```

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- review findings;
- implementation summary if code changed;
- files changed;
- verification commands and results;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation;
- payment/accounting/provider boundary confirmation;
- deployment/server/secrets/production-data impact;
- residual risk;
- next owner.

Also create matching acceptance, execution, and eval records if the workflow completes.

Do not paste full records in chat when files exist.
