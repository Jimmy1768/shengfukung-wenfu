# Return: Accounting Large-Data Admin QA Sweep

Handoff id: `shengfukung-2026-06-12-accounting-large-data-admin-qa-sweep`

Created: 2026-06-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

## Objective

Run a bounded local QA sweep of the admin accounting, orders, payments, registrations, archives, and dashboard surfaces with realistic larger local data.

The purpose was to answer whether the accounting/admin reporting surfaces are usable beyond "the code works" and to preserve concrete evidence for the next product decision.

## Result

Completed.

The local large-data sweep passed after one bounded integration test-data fix. The accounting/admin surfaces are usable for local prototype review with the current table caps, filters, summaries, and CSV exports, but this does not claim production accounting readiness.

## Review Environment

- Rails environment: `development`
- Review database: `golden_template_review`
- Review cookie key: `_shengfukung_wenfu_review_session`
- Review server: `http://127.0.0.1:3312`
- Review admin: `operator-ui-review@example.test`
- Browser surface: Codex in-app Browser
- Data scope: disposable local review data only

## Seeded Data Volume

Temporary runner:

`/private/tmp/shengfukung_accounting_large_data_sweep.rb`

Seeded into local review database only:

- 240 users
- 8 offerings
- 720 registrations
- 630 payments
- 90 no-payment registrations
- 378 completed payments
- 126 pending payments
- 54 refunded payments
- 72 failed payments
- completed amount: `567000` cents
- 8 open assistance requests
- offering mix included event-like, service-like, and gathering-like records
- payment methods included cash, ecpay, line_pay, and stripe labels in local data only

Sweep id: `accounting-20260612142952-9bfd3a`

## Completed Coverage

- Dashboard route rendered current metrics and assistance queue.
- Registrations route rendered recent records.
- Orders route rendered recent and needs-payment tables.
- Orders query filter rendered without returning unrelated offering names in table rows.
- Orders gathering-kind filter isolated gathering records.
- Payments route rendered summary totals, breakdowns, filter controls, and ledger table.
- Payments query filter rendered a large filtered result.
- Payments completed-status filter rendered.
- Payments gathering-kind filter isolated gathering payment rows.
- Payments CSV export returned filtered data with header.
- Archives date-range route rendered.
- Archives payments CSV export returned filtered data with header.
- Browser captured dashboard, payments, and orders screenshots against authenticated local review session.
- Focused Rails admin/accounting tests passed after the timestamp fixture fix.

## Request-Stack Evidence

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails runner /private/tmp/shengfukung_accounting_large_data_sweep.rb
```

Result: pass.

Observed route timings:

```json
{
  "dashboard": { "status": 200, "bytes": 31381, "ms": 35.4 },
  "registrations": { "status": 200, "bytes": 59543, "ms": 66.7 },
  "orders_query": { "status": 200, "bytes": 136378, "ms": 76.2 },
  "orders_gatherings": { "status": 200, "bytes": 137110, "ms": 59.9 },
  "payments_query": { "status": 200, "bytes": 120574, "ms": 376.0 },
  "payments_completed": { "status": 200, "bytes": 120690, "ms": 351.6 },
  "payments_gatherings": { "status": 200, "bytes": 65924, "ms": 163.2 },
  "payments_export": { "status": 200, "bytes": 117687, "ms": 733.2 },
  "archives_range": { "status": 200, "bytes": 247669, "ms": 575.6 },
  "archive_payments_export": { "status": 200, "bytes": 114725, "ms": 730.5 }
}
```

All measured local request-stack routes completed under 1000 ms in this environment.

## Browser Evidence

Screenshots:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-dashboard.jpg`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-payments.jpg`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-orders.jpg`

Dashboard at `1280x720`:

- authenticated: true
- headings included dashboard welcome, key metrics, operating reminders, support requests, and next steps
- dashboard table rows observed: 5
- review temple text present
- QA seed text present in support data

Payments at `1280x720` with query filter:

- authenticated: true
- headings included payment report, breakdowns, filters, and recent payments
- metrics included completed amount/count, pending count, refunded count, and breakdown amounts
- ledger table columns: 7
- ledger table rows rendered: 200

Orders at `1280x720` with query filter:

- authenticated: true
- headings included registrations/orders, needs payment, and recent orders
- needs-payment table rows rendered: 50
- recent-orders table rows rendered: 50

## Usefulness Findings

- Payments and orders cap rendered table rows, so larger datasets remain scan-friendly at the page level.
- Payments summary and breakdown cards remain visible above the ledger table.
- Query, date, status, payment method, and offering-kind filters are essential at this data size.
- CSV exports preserve full filtered result access beyond visible table caps.
- The current unfiltered ledgers rely on caps and do not visibly show total matching record count, so operators may not know how much data is hidden beyond the visible rows.
- The accounting views appear useful as operational admin reporting, not as final accounting/reconciliation tooling.

## Defect Found And Fixed

The first focused test run found two failures in `AdminOrdersAndPaymentsAccessTest` month-preset cases.

Root cause: the setup payment was created before `travel_to`, so the test expected a March payment while the record timestamp was outside the frozen March window.

Fix:

- Updated `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`
- Set the setup payment `processed_at` inside the frozen March window for both month-preset tests.

No product/runtime accounting logic changed.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-accounting-large-data-admin-qa-sweep.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-accounting-large-data-admin-qa-sweep-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-admin-qa-sweep-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-dashboard.jpg`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-payments.jpg`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-accounting-large-data-orders.jpg`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-accounting-large-data-admin-qa-sweep-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-accounting-large-data-admin-qa-sweep-execution.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

## Verification

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails runner /private/tmp/shengfukung_accounting_large_data_sweep.rb
```

Result: pass.

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/accounting_reporting_gatherings_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb
```

Initial result: fail, 27 runs, 142 assertions, 2 failures, 0 errors, 0 skips.

Final result after bounded test-data fix:

```text
27 runs, 146 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

## Skipped Checks

- Full Rails suite was not run.
- Mobile/Expo was not checked because the Expo app has not been created yet.
- Production server checks were not run.
- Real payment provider data was not used.
- Accounting policy, reconciliation, payout matching, and audit accounting controls were not validated.

## Boundary Confirmation

- Rails runtime/product accounting code: not changed.
- Rails tests: changed only to make month-preset timestamp data explicit.
- Vue: not touched.
- Expo: not touched.
- Payment provider configuration: not touched.
- Real payment providers: not called.
- Production data: not touched.
- Deployment/server config: not changed.
- Secrets: not accessed.
- Existing `ops/docs/` history: not touched.

## Residual Risk

- This is local prototype evidence only.
- Local request timing is useful for relative QA only, not production performance.
- The accounting system still needs policy/reconciliation review before production accounting acceptance.
- Large real-world payment provider imports/webhooks were not validated.
- Operators may need clearer total-count/hidden-result cues when tables are capped.

## Next Owner

Coordinator/implementation thread should commit the checkpoint and use this accepted-with-gaps result to decide the next bounded accounting/reporting or temple onboarding task.
