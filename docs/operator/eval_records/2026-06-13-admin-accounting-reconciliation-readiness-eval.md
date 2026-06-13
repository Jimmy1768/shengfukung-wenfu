# Eval Record: Admin Accounting Reconciliation Readiness

Eval id: `shengfukung-2026-06-13-admin-accounting-reconciliation-readiness-eval`

Created: 2026-06-13

Evaluator: Shengfukung Wenfu coordinator/implementation thread

Mode: local prototype implementation QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-13-admin-accounting-reconciliation-readiness.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-accounting-reconciliation-readiness-return.md`

## Objective

Verify that the admin accounting flow exposes enough local payment status information for a bounded reconciliation-readiness pass without changing accounting calculations, provider configuration, or production data.

## Code Evidence

Reviewed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/_ledger_table.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/reporting/payments_csv_exporter.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/cash_payment_recorder.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/checkout_return_service.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/refund_service.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/orders/_table.html.erb`

Findings:

- Admin orders already expose registration payment status.
- Payments CSV export already includes status.
- Local payment services already preserve completed/pending/failed/refunded transitions for the reviewed paths.
- Admin payments visible ledger was missing a per-row status column.

Implemented:

- The admin payments ledger now renders a status column with status pills.
- Focused integration coverage confirms completed, pending, failed, and refunded labels render in the admin payments ledger.

## Browser Evidence

Browser surface: Codex in-app Browser.

Review database: `golden_template_review`.

Review server: local `127.0.0.1:3312`.

Payments check:

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
  "statuses": [
    {
      "className": "status-pill status-completed",
      "text": "已完成"
    }
  ]
}
```

## Focused Tests

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/accounting_reporting_gatherings_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb
```

Final result:

```text
30 runs, 165 assertions, 0 failures, 0 errors, 0 skips
```

Coverage added:

- payments index shows payment status for reconciliation;
- confirms status pills for `completed`, `pending`, `failed`, and `refunded` payment rows.

## Static Check

Command:

```bash
git diff --check
```

Result: pass.

## Decision

pass_with_gaps

## Remaining Gaps

- The local review browser data showed the new column with completed rows; non-completed statuses were verified by integration test.
- Duplicate Traditional Chinese payment status locale blocks remain and should be cleaned up in a separate copy/localization sweep.
- No pagination, status history, provider settlement matching, or accounting close workflow was added.
- Full Rails suite was not run.
- This eval does not accept production accounting readiness.
