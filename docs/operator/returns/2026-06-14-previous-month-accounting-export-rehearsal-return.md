# Return: Previous-Month Accounting Export Rehearsal

Handoff id: `shengfukung-2026-06-14-previous-month-accounting-export-rehearsal`

Created: 2026-06-14

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

## Objective

Rehearse and verify the V1 previous-month accounting export process:

- admin selects the previous month/last month payment preset;
- admin exports the filtered payments CSV;
- CSV contains the V1 accounting handoff fields;
- V1 remains a manual external accounting handoff without an in-app month close/lock.

## Reviewed Context Records

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-v1-admin-accounting-policy-readiness-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-ecpay-default-path-local-verification-return.md`

## Result

Completed with accepted gaps.

The admin payments export endpoint now applies the same `month_preset` semantics as the payments page. A focused request test proves that `month_preset: last_month` exports the previous calendar month and excludes current-month payments.

## Implementation Summary

- Updated `Admin::PaymentsController#export` to call `apply_month_preset!` before building the export scope.
- Added a focused integration test for the previous-month accounting handoff:
  - travel date: 2026-03-01;
  - `last_month` resolves to 2026-02-01 through 2026-02-28;
  - CSV filename/disposition includes that previous-month range;
  - CSV includes the expected accounting handoff header;
  - last-month ECPay payment appears;
  - current-month ECPay payment is excluded.
- Rehearsed the visible admin browser workflow against the isolated local review server.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-14-previous-month-accounting-export-rehearsal.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-14-previous-month-accounting-export-rehearsal-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-14-previous-month-accounting-export-rehearsal-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-14-previous-month-accounting-export-rehearsal-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-14-previous-month-accounting-export-rehearsal-execution.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/payments_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

## Verification

Initial command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/services/reporting/payments_csv_exporter_test.rb
```

Sandbox result:

```text
blocked by local PostgreSQL sandbox restriction: Operation not permitted.
```

Escalated local database result:

```text
15 runs, 116 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

## Browser/Admin Evidence

Browser surface: Codex in-app Browser against local isolated review server/database.

Review server:

`127.0.0.1:3312`

Admin login:

`operator-ui-review@example.test`

Payments page checked:

`/admin/payments`

Workflow rehearsed:

1. Signed in to the local admin review server.
2. Opened the admin payments page from the sidebar.
3. Confirmed previous-month guidance was visible.
4. Clicked `上月`.
5. Confirmed the last-month preset was active.
6. Confirmed start/end inputs were `2026-05-01` and `2026-05-31`.
7. Confirmed the export link carried the same date range.
8. Confirmed the ledger showed accounting handoff columns and May rows.

Observed browser state:

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

The in-app Browser blocked direct CSV display/download with `ERR_BLOCKED_BY_CLIENT`, but the local Rails server log showed the export request completed `200 OK` and sent `payments-2026-05-01-to-2026-05-31-20260614.csv`. This was treated as a browser-tool limitation, not a product failure. CSV response/body behavior is covered by the focused Rails request test above.

## Skipped Checks

- Full Rails suite was not run.
- Direct browser display/download inspection of the CSV was blocked by the browser tool, though the local server completed the export request.
- Production accounting data was not tested.
- Real ECPay/provider calls were not made.
- Mobile/Expo was not checked because the Expo app has not been created.
- Help guide implementation and links were not added by design.

## Boundary Confirmation

- Rails admin controller and focused tests changed.
- Payment status semantics were not changed.
- Payment provider configuration was not changed.
- Real payment providers were not called.
- Accounting close/lock state was not added.
- Provider settlement matching was not added.
- Export history tracking was not added.
- Vue: not touched.
- Expo/mobile: not touched.
- Deployment/server config: not changed.
- Secrets: not accessed.
- Production data: not touched.
- Existing `ops/docs/`: not touched.

## Residual Risk

- This verifies the V1 previous-month export mechanics and browser workflow, but it is still not full accounting close/reconciliation.
- The browser rehearsal used local seeded review data, not real temple accounting data.
- There is no export-history record or month lock in V1 by accepted decision.
- Production promotion remains blocked by the production-boundary decision.

## Follow-Up Gaps

- One real temple admin/staff rehearsal is still required for V1 acceptance.
- Comprehensive help guide remains pending after V1 behavior settles.
- Public/admin help-guide links remain pending after the guide exists.
- Production promotion remains blocked until the production-boundary decision is satisfied.

## Next Owner

Coordinator/implementation thread should create matching eval, acceptance, and execution records, commit and push this checkpoint, then continue to the real temple admin/staff rehearsal gap.
