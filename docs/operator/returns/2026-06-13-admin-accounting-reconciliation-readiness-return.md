# Return: Admin Accounting Reconciliation Readiness

Handoff id: `shengfukung-2026-06-13-admin-accounting-reconciliation-readiness`

Created: 2026-06-13

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

## Objective

Run a bounded reconciliation-readiness pass on the admin accounting flow after the large-data admin QA sweep.

The specific goal was to confirm whether admin-visible payment/order surfaces expose enough local status and traceability for operators to understand completed, pending, failed, refunded, cash, and provider-backed payments without adding a full reconciliation subsystem.

## Result

Completed.

A bounded gap was found and fixed: the admin payments ledger had CSV status data and status filters, but individual visible payment rows did not show the payment status. The ledger now includes a `狀態`/status column with status pills for each payment row.

## Review Findings

- Admin orders already showed payment status pills on order rows.
- Admin payments CSV export already included a `Status` column from `payment.status`.
- Cash payment recording creates completed manual cash payment records and ledger entries.
- Checkout return handling updates local payment status, syncs registration payment state, and logs reconciliation locally.
- Refund/cancel behavior maps refunds to `refunded`, cancellations to `failed`, syncs registration payment state, and logs audit events.
- The admin payments ledger did not show per-row payment status before this pass, which made local reconciliation harder from the visible UI.

## Implementation Summary

- Added a status column to `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/_ledger_table.html.erb`.
- Rendered each payment status using the existing `status-pill status-<status>` pattern and existing `admin.payments.statuses.*` locale keys.
- Added an integration test that confirms the admin payments ledger shows completed, pending, failed, and refunded status pills.

## Browser Evidence

Browser surface: Codex in-app Browser against local review server/database.

Payments URL checked:

`http://127.0.0.1:3312/admin/payments`

Observed:

```json
{
  "table": true,
  "headers": [
    "編號",
    "信眾",
    "供品",
    "金額",
    "狀態",
    "付款方式",
    "紀錄人員",
    "處理時間"
  ],
  "rowCount": 200,
  "firstObservedStatus": {
    "className": "status-pill status-completed",
    "text": "已完成"
  }
}
```

Browser review data only exposed completed rows in the visible latest 200 rows. Focused request-stack tests covered completed, pending, failed, and refunded rows.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-13-admin-accounting-reconciliation-readiness.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-accounting-reconciliation-readiness-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-13-admin-accounting-reconciliation-readiness-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-13-admin-accounting-reconciliation-readiness-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-13-admin-accounting-reconciliation-readiness-execution.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/_ledger_table.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

## Verification

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/accounting_reporting_gatherings_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb
```

Initial result:

```text
30 runs, 163 assertions, 1 failures, 0 errors, 0 skips
```

Failure reason:

- Test initially expected pending table copy `待付款`.
- Live locale resolution returns `待處理` because `admin.payments.statuses` is duplicated in `rails/config/locales/admin.zh-TW.yml` and the later block wins.

Final result after aligning the test to current app behavior:

```text
30 runs, 165 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

Browser check:

```text
Open local review admin payments page and inspect the rendered ledger headers/status pills.
```

Result: pass.

## Skipped Checks

- Full Rails suite was not run.
- Production accounting reconciliation was not tested.
- Real payment providers were not called.
- Production payment data was not touched.
- Mobile/Expo was not checked because the Expo app has not been created.

## Boundary Confirmation

- Rails admin UI and focused integration tests changed.
- CSV export behavior was reviewed but not changed.
- Cash payment, checkout return, webhook/provider, refund, and cancel service behavior was reviewed but not changed.
- Accounting totals and summaries were not changed.
- Vue: not touched.
- Expo/mobile: not touched.
- Deployment/server config: not changed.
- Secrets: not accessed.
- Payment provider configuration: not changed.
- Real payment providers: not called.
- Production data: not touched.
- Existing `ops/docs/`: not touched.

## Friction

- `rails/config/locales/admin.zh-TW.yml` has duplicate `admin.payments.statuses` blocks. The later block currently determines table status copy, so pending renders as `待處理`. This was left unchanged to avoid expanding the sweep into locale cleanup.
- Browser review data visible in the latest 200 payment rows only showed completed statuses; request-stack tests provide the all-status evidence.

## Residual Risk

- This improves visible status reconciliation but does not add pagination, status history, settlement matching, provider reconciliation reports, or accounting close workflow.
- No production-readiness claim is made.

## Next Owner

Coordinator/implementation thread should create matching acceptance and execution records, commit this checkpoint, then choose the next bounded admin/accounting workflow.
