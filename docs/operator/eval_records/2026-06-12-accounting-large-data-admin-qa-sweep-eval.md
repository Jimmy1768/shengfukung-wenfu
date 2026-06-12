# Eval Record: Accounting Large-Data Admin QA Sweep

Eval id: `shengfukung-2026-06-12-accounting-large-data-admin-qa-sweep-eval`

Created: 2026-06-12

Evaluator: Shengfukung Wenfu coordinator/implementation thread

Mode: local prototype QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-accounting-large-data-admin-qa-sweep.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-accounting-large-data-admin-qa-sweep-return.md`

## Objective

Preserve concrete route, database, browser, and test evidence for the accounting large-data admin QA sweep.

## Data Shape

```json
{
  "sweep_id": "accounting-20260612142952-9bfd3a",
  "rails_env": "development",
  "database": "golden_template_review",
  "admin_email": "operator-ui-review@example.test",
  "temple_slug": "operator-ui-review-temple",
  "seeded": {
    "users": 240,
    "offerings": 8,
    "registrations": 720,
    "payments": 630,
    "no_payment_registrations": 90,
    "completed_payments": 378,
    "pending_payments": 126,
    "refunded_payments": 54,
    "failed_payments": 72,
    "completed_amount_cents": 567000
  }
}
```

## Route Evidence

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails runner /private/tmp/shengfukung_accounting_large_data_sweep.rb
```

Result: pass.

```json
{
  "dashboard": { "path": "/admin/dashboard", "status": 200, "bytes": 31381, "ms": 35.4 },
  "registrations": { "path": "/admin/registrations", "status": 200, "bytes": 59543, "ms": 66.7 },
  "orders_query": { "path": "/admin/orders", "status": 200, "bytes": 136378, "ms": 76.2 },
  "orders_gatherings": { "path": "/admin/orders", "status": 200, "bytes": 137110, "ms": 59.9 },
  "payments_query": { "path": "/admin/payments", "status": 200, "bytes": 120574, "ms": 376.0 },
  "payments_completed": { "path": "/admin/payments", "status": 200, "bytes": 120690, "ms": 351.6 },
  "payments_gatherings": { "path": "/admin/payments", "status": 200, "bytes": 65924, "ms": 163.2 },
  "payments_export": { "path": "/admin/payments/export.csv", "status": 200, "bytes": 117687, "ms": 733.2 },
  "archives_range": { "path": "/admin/archives", "status": 200, "bytes": 247669, "ms": 575.6 },
  "archive_payments_export": { "path": "/admin/archives/payments.csv", "status": 200, "bytes": 114725, "ms": 730.5 }
}
```

Observed runner assertions:

```json
{
  "orders_row_cap_ok": true,
  "payments_row_cap_ok": true,
  "dashboard_has_currency_metric": true,
  "dashboard_has_assistance_queue": true,
  "gathering_orders_isolated": true,
  "gathering_payments_isolated": true,
  "payments_export_has_header": true,
  "archive_export_has_header": true,
  "slow_pages_over_1000ms": {}
}
```

Interpretation:

- Admin accounting routes rendered under seeded larger local load.
- Orders and payments table caps worked.
- Gathering-kind filters isolated gathering rows in request-stack checks.
- CSV exports remained available for full filtered access.
- No route in the sweep exceeded 1000 ms locally.

## Browser Evidence

Browser surface: Codex in-app Browser.

Viewport:

```json
{ "width": 1280, "height": 720 }
```

Dashboard screenshot:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-dashboard.jpg`

Dashboard summary:

```json
{
  "authenticated": true,
  "headings": [
    "Operator UI Reviewer，歡迎回來",
    "關鍵指標",
    "營運提醒",
    "信眾支援請求",
    "下一步",
    "請再次確認"
  ],
  "tables": [
    { "columns": 5, "rows": 5 }
  ],
  "has_operator_temple": true,
  "has_qa_seed_text": true
}
```

Payments screenshot:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-payments.jpg`

Payments summary:

```json
{
  "authenticated": true,
  "headings": [
    "付款報表",
    "依付款方式／供品／日期",
    "篩選付款",
    "最近 100 筆付款",
    "請再次確認"
  ],
  "tables": [
    { "columns": 7, "rows": 200 }
  ],
  "sample_metrics": [
    "NT$4,725",
    "315",
    "105",
    "45"
  ]
}
```

Orders screenshot:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-orders.jpg`

Orders summary:

```json
{
  "authenticated": true,
  "headings": [
    "報名與現場訂單",
    "Needs payment",
    "Recent orders",
    "請再次確認"
  ],
  "tables": [
    { "columns": 7, "rows": 50 },
    { "columns": 7, "rows": 50 }
  ]
}
```

Interpretation:

- Dashboard remained readable and surfaced support/admin work.
- Payments summary/breakdowns/filters sat above the large ledger.
- Payments ledger rendered many rows and horizontally exceeded the viewport, which is acceptable for dense admin data but may need operator review for repeated daily use.
- Orders kept separate needs-payment and recent tables.

## Focused Tests

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/accounting_reporting_gatherings_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb
```

Initial result:

```text
27 runs, 142 assertions, 2 failures, 0 errors, 0 skips
```

Failure reason:

- Existing month-preset tests expected setup payment records to belong to the frozen March window, but those records were created before `travel_to`.

Bounded fix:

- Set `processed_at: Time.zone.now` for the setup payment inside the frozen March window in the two affected tests.

Final result:

```text
27 runs, 146 assertions, 0 failures, 0 errors, 0 skips
```

## Decision

pass_for_local_prototype_with_gaps

## Remaining Gaps

- Full Rails suite was not run.
- Production performance was not tested.
- Real provider data, webhooks, reconciliation, payouts, and accounting policy were not validated.
- Mobile/Expo was not tested because the Expo app has not been created.
- Visible ledgers still need product review for total-count and hidden-result affordances.
