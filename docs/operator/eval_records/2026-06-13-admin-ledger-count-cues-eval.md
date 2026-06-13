# Eval Record: Admin Ledger Count Cues

Eval id: `shengfukung-2026-06-13-admin-ledger-count-cues-eval`

Created: 2026-06-13

Evaluator: Shengfukung Wenfu coordinator/implementation thread

Mode: local prototype implementation QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-13-admin-ledger-count-cues.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-ledger-count-cues-return.md`

## Objective

Verify that capped admin orders and payments ledgers expose visible counts, total matching counts, and cap hints without changing accounting calculations or exports.

## Code Evidence

Payments:

- `Admin::PaymentsController#index` now computes `@payments_total_count` before applying the `@payments_visible_limit` of 200.
- The payments page displays visible/total count copy and cap/export copy.
- The localized title now says latest 200 payments, matching the actual cap.

Orders:

- `Admin::OrdersController#index` now computes `@unpaid_orders_total_count` and `@recent_orders_total_count` before applying the 50-row section cap.
- The orders page displays visible/total count copy and cap/filter copy for each section.
- Previously hard-coded English section headings were localized.

## Browser Evidence

Browser surface: Codex in-app Browser.

Review database: `golden_template_review`.

Review server: local `127.0.0.1:3312`.

Payments check:

```json
{
  "loggedIn": true,
  "headings": [
    "付款報表",
    "依付款方式／供品／日期",
    "篩選付款",
    "最近 200 筆付款",
    "請再次確認"
  ],
  "tables": [
    { "columns": 7, "rows": 200 }
  ],
  "hasPaymentCount": true,
  "hasCsvHint": true,
  "observedCopy": "目前顯示 200 筆，共 525 筆符合條件的付款紀錄。 表格先顯示最新 200 筆；CSV 匯出會包含完整篩選結果。"
}
```

Orders check:

```json
{
  "loggedIn": true,
  "headings": [
    "報名與現場訂單",
    "待付款",
    "最新訂單",
    "請再次確認"
  ],
  "tables": [
    { "columns": 7, "rows": 50 },
    { "columns": 7, "rows": 50 }
  ],
  "hasOrderCount": true,
  "hasFilterHint": true,
  "observedCopy": [
    "目前顯示 50 筆，共 342 筆符合條件的待付款報名。 表格先顯示最新 50 筆；請使用篩選條件縮小清單。",
    "目前顯示 50 筆，共 378 筆符合條件的已付款報名。 表格先顯示最新 50 筆；請使用篩選條件縮小清單。"
  ]
}
```

## Focused Tests

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/accounting_reporting_gatherings_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb
```

Result:

```text
29 runs, 158 assertions, 0 failures, 0 errors, 0 skips
```

Coverage added:

- orders index shows matching totals when both visible tables are capped;
- payments index shows matching total when visible ledger is capped.

## Static Check

Command:

```bash
git diff --check
```

Result: pass.

## Decision

pass

## Remaining Gaps

- No pagination was added.
- Full Rails suite was not run.
- Browser check did not capture screenshots because text/DOM evidence was sufficient for this copy-level UI change.
- Production accounting readiness is not accepted by this eval.
