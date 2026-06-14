# Execution Record: Previous-Month Accounting Export Rehearsal

Execution id: `shengfukung-2026-06-14-previous-month-accounting-export-rehearsal-execution`

Record created: 2026-06-14

Execution date: 2026-06-14

Execution type: `agent_assisted`

Executor: Shengfukung Wenfu coordinator/implementation thread

Executor type: `coordinator_implementation_thread`

Authority level: repo-local code, docs, local review, test, and evidence authority only. No authority to deploy, change production server config, rotate/access secrets, change payment provider configuration, call real payment providers, change real ECPay merchant state, or touch production data.

Mode: local prototype implementation

Trigger/input: user instructed the coordinator/implementation thread to proceed with the next OperatorKit step.

Handoff packet: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-14-previous-month-accounting-export-rehearsal.md`

Execution return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-14-previous-month-accounting-export-rehearsal-return.md`

Acceptance record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-14-previous-month-accounting-export-rehearsal-acceptance.md`

Eval record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-14-previous-month-accounting-export-rehearsal-eval.md`

Repo/path: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch/worktree state before commit: branch `offering-setup-admin-workflow`; branch was clean and synced with origin before implementation began.

## Actions Taken

- Created the previous-month accounting export rehearsal handoff.
- Reviewed prior V1 accounting policy and ECPay default-path returns.
- Reviewed payments page, month preset links, payments export controller action, CSV exporter, and existing tests.
- Identified that the payments page applied month presets but the export action did not apply `month_preset` directly.
- Updated the export action to apply the selected month preset before filtering.
- Added focused request coverage for direct `last_month` CSV export.
- Ran focused Rails tests.
- Started local isolated admin review server against `golden_template_review`.
- Signed in through the in-app Browser.
- Opened the admin payments page.
- Clicked `上月`.
- Verified active preset, previous-month date inputs, export href, ledger columns, row count, and May row dates.
- Confirmed browser direct CSV display/download was blocked by the browser tool download policy, while the local server completed the export request.
- Restored generated `rails/db/schema.rb` index-ordering noise from test/database preparation.
- Ran `git diff --check`.
- Created return, eval, acceptance, and execution records.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-14-previous-month-accounting-export-rehearsal.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-14-previous-month-accounting-export-rehearsal-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-14-previous-month-accounting-export-rehearsal-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-14-previous-month-accounting-export-rehearsal-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-14-previous-month-accounting-export-rehearsal-execution.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/payments_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

## Commands Run

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

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/review_admin_server
```

Result: pass. Started local Puma on `127.0.0.1:3312`; stopped after browser verification.

Browser check:

```text
Log in, open admin payments, click 上月, inspect date range, export href, and ledger columns.
```

Result: pass.

Browser direct CSV navigation:

```text
Open /admin/payments/export.csv with previous-month filters.
```

Result: browser display/download blocked by browser tool download policy (`ERR_BLOCKED_BY_CLIENT`). Local server log showed `200 OK` and sent `payments-2026-05-01-to-2026-05-31-20260614.csv`; request tests covered CSV response/body.

```bash
git diff --check
```

Result: pass.

## External Services Called

None.

## Secrets Accessed

None.

## Production Data

Not touched.

## Boundary

- Rails admin controller and focused tests changed.
- Payment provider behavior/configuration: not changed.
- Real ECPay/provider network calls: none.
- Accounting close/lock state: not added.
- Provider settlement matching: not added.
- Export history tracking: not added.
- Payment status set: not changed.
- Vue: not touched.
- Expo/mobile: not touched.
- Deployment/server config: not changed.
- Existing `ops/docs/`: not touched.

## Skipped/Refused Actions

- Full Rails suite was not run.
- No production, deployment, server, secret, payment-provider, or provider API action was performed.
- No mobile or Expo work was performed.
- Help guide implementation and links were not added.

## Outcome

Previous-month accounting export rehearsal accepted with gaps for the bounded local prototype scope. Commit and push checkpoint.
