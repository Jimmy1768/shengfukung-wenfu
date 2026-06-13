# Return: Admin Ledger Count Cues

Handoff id: `shengfukung-2026-06-13-admin-ledger-count-cues`

Created: 2026-06-13

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

## Objective

Add small admin UI cues so capped orders and payments ledgers tell operators how many matching records exist and when more records are hidden beyond the visible cap.

## Result

Completed.

The orders and payments admin pages now show visible-count and total-matching-count notes next to the existing ledger/table headings. When the visible list is capped, the note tells the operator how to get the full result or narrow the list.

## Implementation Summary

Payments:

- Preserved the existing 200-row visible ledger cap.
- Added `@payments_total_count` from the filtered payment scope before applying the limit.
- Materialized the capped visible payments with `to_a` so visible count uses loaded rows.
- Updated the payment ledger title from "latest 100" to "latest 200" to match the actual cap.
- Added localized count copy:
  - zh-TW: `目前顯示 %{visible} 筆，共 %{total} 筆符合條件的付款紀錄。`
  - en: `Showing %{visible} of %{total} matching payment records.`
- Added localized cap/export copy:
  - zh-TW: `表格先顯示最新 %{limit} 筆；CSV 匯出會包含完整篩選結果。`
  - en: `Showing the latest %{limit} first; CSV export includes the full filtered result.`

Orders:

- Preserved the existing 50-row visible cap for each orders section.
- Added separate total matching counts for unpaid/needs-payment and paid/recent sections.
- Materialized each capped visible list with `to_a` so visible count uses loaded rows.
- Localized the previously hard-coded section headings and body copy.
- Added localized count copy:
  - zh-TW unpaid: `目前顯示 %{visible} 筆，共 %{total} 筆符合條件的待付款報名。`
  - zh-TW paid: `目前顯示 %{visible} 筆，共 %{total} 筆符合條件的已付款報名。`
  - en unpaid: `Showing %{visible} of %{total} matching unpaid registrations.`
  - en paid: `Showing %{visible} of %{total} matching paid registrations.`
- Added localized cap/filter copy:
  - zh-TW: `表格先顯示最新 %{limit} 筆；請使用篩選條件縮小清單。`
  - en: `Showing the latest %{limit} first; use filters to narrow the list.`

## Browser Evidence

Browser surface: Codex in-app Browser against local review server/database.

Payments URL checked:

`http://127.0.0.1:3312/admin/payments?filter%5Bquery%5D=qa-accounting-accounting-20260612142952-9bfd3a`

Observed:

- authenticated: true
- heading: `最近 200 筆付款`
- table rows: 200
- copy present: `目前顯示 200 筆，共 525 筆符合條件的付款紀錄。`
- copy present: `CSV 匯出會包含完整篩選結果。`

Orders URL checked:

`http://127.0.0.1:3312/admin/orders?filter%5Bquery%5D=qa-accounting-accounting-20260612142952-9bfd3a`

Observed:

- authenticated: true
- headings: `待付款`, `最新訂單`
- table rows: 50 and 50
- copy present: `目前顯示 50 筆，共 342 筆符合條件的待付款報名。`
- copy present: `目前顯示 50 筆，共 378 筆符合條件的已付款報名。`
- copy present: `請使用篩選條件縮小清單。`

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-13-admin-ledger-count-cues.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-ledger-count-cues-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-13-admin-ledger-count-cues-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-13-admin-ledger-count-cues-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-13-admin-ledger-count-cues-execution.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/orders_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/payments_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/orders/index.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/index.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

## Verification

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/accounting_reporting_gatherings_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb
```

Result:

```text
29 runs, 158 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

Browser check:

```text
Open local review payments and orders pages filtered by qa-accounting-accounting-20260612142952-9bfd3a.
```

Result: pass.

## Skipped Checks

- Full Rails suite was not run.
- Production performance testing was not run.
- Mobile/Expo was not checked because the Expo app has not been created.
- Real payment provider data was not used.

## Boundary Confirmation

- Rails admin UI/controller/test/locales changed.
- Accounting totals, payment summary calculations, CSV export scope, and payment provider behavior were not changed.
- Vue: not touched.
- Expo/mobile: not touched.
- Deployment/server config: not changed.
- Secrets: not accessed.
- Payment provider configuration: not changed.
- Real payment providers: not called.
- Production data: not touched.
- Existing `ops/docs/`: not touched.

## Residual Risk

- This adds count/cap disclosure but not pagination.
- Local browser verification used seeded review data, not production-scale data.
- Operators may still want richer pagination/export affordances later.

## Next Owner

Coordinator/implementation thread should create the matching acceptance and execution records, commit the checkpoint, then choose the next bounded workflow.
