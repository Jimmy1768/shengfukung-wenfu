# Eval Record: V1 Admin Accounting Policy Readiness

Eval id: `shengfukung-2026-06-13-v1-admin-accounting-policy-readiness-eval`

Created: 2026-06-13

Evaluator: Shengfukung Wenfu coordinator/implementation thread

Mode: local prototype implementation QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-13-v1-admin-accounting-policy-readiness.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-v1-admin-accounting-policy-readiness-return.md`

## Objective

Verify that the admin payments surface and CSV export now express the accepted V1 source-of-truth and monthly export policy without changing payment behavior or production/provider state.

## Code Evidence

Reviewed and changed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/helpers/admin/filters_helper.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/reporting/payments_csv_exporter.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/_ledger_table.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/index.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

Reviewed but not changed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/cash_payment_recorder.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/checkout_return_service.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/refund_service.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/orders/_table.html.erb`

## Browser Evidence

Browser surface: Codex in-app Browser.

Review database: `golden_template_review`.

Review server: local `127.0.0.1:3312`.

Payments check:

```json
{
  "policyNote": true,
  "monthCloseHint": true,
  "headers": [
    "編號",
    "信眾",
    "供品",
    "金額",
    "狀態",
    "付款方式",
    "收款依據",
    "紀錄人員",
    "處理時間"
  ],
  "rowCount": 200,
  "sampleRows": [
    [
      "QA-PAY-accounting-20260612142952-9bfd3a-719",
      "QA Accounting Patron 064",
      "法會項目 · QA Accounting Event 1",
      "NT$15",
      "已完成",
      "Stripe",
      "Stripe 已確認",
      "Operator UI Reviewer",
      "2026/06/12 21:29"
    ],
    [
      "QA-PAY-accounting-20260612142952-9bfd3a-702",
      "QA Accounting Patron 190",
      "祈福服務 · QA Accounting Service 2",
      "NT$12",
      "已完成",
      "LINE Pay",
      "LINE Pay 已確認",
      "Operator UI Reviewer",
      "2026/06/12 20:29"
    ]
  ]
}
```

## Focused Tests

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb
```

Final result:

```text
28 runs, 162 assertions, 0 failures, 0 errors, 0 skips
```

Coverage added:

- admin payments index shows V1 source-of-truth copy;
- admin payments index shows previous-month export guidance;
- admin payments ledger shows source column and admin-attested cash source label;
- payment CSV includes source/provider/provider reference fields.

## Static Check

Command:

```bash
git diff --check
```

Result: pass.

## Decision

pass_with_gaps

## Remaining Gaps

- Full Rails suite was not run.
- Real ECPay/sandbox flow was not verified in this pass.
- No production/provider config work was performed.
- No formal close/lock state or settlement matching was added.
- Help guide implementation remains pending until V1 behavior settles.
