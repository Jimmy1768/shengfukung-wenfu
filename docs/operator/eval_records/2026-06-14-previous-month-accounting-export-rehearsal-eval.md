# Eval Record: Previous-Month Accounting Export Rehearsal

Eval id: `shengfukung-2026-06-14-previous-month-accounting-export-rehearsal-eval`

Created: 2026-06-14

Evaluator: Shengfukung Wenfu coordinator/implementation thread

Mode: local prototype implementation QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-14-previous-month-accounting-export-rehearsal.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-14-previous-month-accounting-export-rehearsal-return.md`

## Objective

Evaluate whether the V1 previous-month accounting export workflow is locally usable from the admin payments page and correctly backed by the CSV export endpoint.

## Code Evidence

Reviewed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/index.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/payments_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/reporting/payments_csv_exporter.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/reporting/payments_csv_exporter_test.rb`

Changed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/payments_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

## Evidence Added

- `Admin::PaymentsController#export` now applies `month_preset` before export filtering.
- Request coverage proves direct `filter[month_preset]=last_month` export resolves to the previous calendar month.
- Request coverage proves the CSV export includes the accounting handoff header:
  - processed timestamp;
  - reference;
  - patron;
  - patron phone;
  - offering type;
  - offering;
  - registration period key;
  - method;
  - status;
  - source;
  - provider;
  - provider reference;
  - amount;
  - currency;
  - recorded by.
- Request coverage proves current-month payments are excluded from the last-month export.

## Browser Evidence

Local review server:

`127.0.0.1:3312`

Observed:

```json
{
  "activeChip": ["上月"],
  "startDate": "2026-05-01",
  "endDate": "2026-05-31",
  "exportHref": "http://127.0.0.1:3312/admin/payments/export.csv?filter%5Bend_date%5D=2026-05-31&filter%5Bmonth_preset%5D=last_month&filter%5Bstart_date%5D=2026-05-01",
  "guidance": true,
  "headers": ["編號", "信眾", "供品", "金額", "狀態", "付款方式", "收款依據", "紀錄人員", "處理時間"],
  "rowCount": 168,
  "firstRowDate": "2026/05/31 21:29"
}
```

Direct browser CSV display/download was blocked by the in-app Browser download policy, but the local Rails server log showed the export request completed `200 OK` and sent `payments-2026-05-01-to-2026-05-31-20260614.csv`. Rails request tests covered the CSV response and body.

## Verification

Focused command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/services/reporting/payments_csv_exporter_test.rb
```

Final result:

```text
15 runs, 116 assertions, 0 failures, 0 errors, 0 skips
```

Static check:

```bash
git diff --check
```

Result: pass.

## Decision

pass_with_gaps

## Remaining Gaps

- Full Rails suite was not run.
- Browser display/download inspection was blocked by the browser tool, though the local server completed the export request and request-level CSV verification passed.
- This is not final V1 production acceptance.
- It does not add accounting close/lock state, settlement matching, or export history.
- One real temple admin/staff rehearsal remains pending.
- Help guide remains pending after V1 behavior settles.
