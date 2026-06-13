# Return: Admin Payment Status Locale Cleanup

Handoff id: `shengfukung-2026-06-13-admin-payment-status-locale-cleanup`

Created: 2026-06-13

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

## Objective

Clean up duplicate admin payment status locale definitions so the admin payments ledger and status filter resolve payment statuses consistently.

## Result

Completed.

The duplicate `admin.payments.statuses` blocks in both admin locale files were removed. Traditional Chinese pending payment status now intentionally resolves to `待付款`, matching the payment metrics copy and unpaid/payment terminology already used in the admin orders flow.

## Implementation Summary

- Removed the later duplicate `admin.payments.statuses` block from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`.
- Removed the later duplicate `admin.payments.statuses` block from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`.
- Updated the focused admin payments ledger test to assert:
  - pending payment status pill renders `待付款`;
  - the admin payments status filter pending option also renders `待付款`.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-13-admin-payment-status-locale-cleanup.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-payment-status-locale-cleanup-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-13-admin-payment-status-locale-cleanup-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-13-admin-payment-status-locale-cleanup-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-13-admin-payment-status-locale-cleanup-execution.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

## Verification

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/payments_flow_test.rb
```

Result:

```text
19 runs, 107 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

Command:

```bash
bin/rails runner 'puts I18n.t("admin.payments.statuses.pending", locale: :"zh-TW"); puts I18n.t("admin.payments.statuses.pending", locale: :en)'
```

Result:

```text
待付款
Pending
```

## Skipped Checks

- Full Rails suite was not run.
- Browser verification was not run because this was a locale-key cleanup covered by integration tests and direct Rails i18n resolution.
- Production accounting reconciliation was not tested.
- Real payment providers were not called.
- Mobile/Expo was not checked because the Expo app has not been created.

## Boundary Confirmation

- Rails locale files and focused integration test changed.
- Payment status state machine behavior was not changed.
- Payment filters and query semantics were not changed.
- Accounting totals, CSV fields, provider flows, refunds, and cash-payment behavior were not changed.
- Vue: not touched.
- Expo/mobile: not touched.
- Deployment/server config: not changed.
- Secrets: not accessed.
- Payment provider configuration: not changed.
- Real payment providers: not called.
- Production data: not touched.
- Existing `ops/docs/`: not touched.

## Residual Risk

- This normalizes status copy only; it does not address broader accounting reconciliation UX.
- Some non-payment admin statuses elsewhere still use `待處理` appropriately for workflow queues.

## Next Owner

Coordinator/implementation thread should create the matching acceptance and execution records, commit this checkpoint, then choose the next bounded admin/accounting workflow.
