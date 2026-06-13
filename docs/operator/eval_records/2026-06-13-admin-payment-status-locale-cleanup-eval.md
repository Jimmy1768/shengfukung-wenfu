# Eval Record: Admin Payment Status Locale Cleanup

Eval id: `shengfukung-2026-06-13-admin-payment-status-locale-cleanup-eval`

Created: 2026-06-13

Evaluator: Shengfukung Wenfu coordinator/implementation thread

Mode: local prototype implementation QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-13-admin-payment-status-locale-cleanup.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-payment-status-locale-cleanup-return.md`

## Objective

Verify that admin payment status locale keys are no longer duplicated and that pending payment status resolves consistently for ledger and filter rendering.

## Code Evidence

Reviewed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/_ledger_table.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/index.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/shared/_filters.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

Findings:

- Both ledger status pills and the payments filter use `admin.payments.statuses`.
- `admin.zh-TW.yml` had two sibling `admin.payments.statuses` blocks with conflicting pending labels.
- `admin.en.yml` had two sibling `admin.payments.statuses` blocks with identical labels.

Implemented:

- Removed the duplicate later blocks.
- Kept the payment-specific pending zh-TW label as `待付款`.
- Updated focused test coverage for the ledger and filter pending label.

## Focused Tests

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/payments_flow_test.rb
```

Result:

```text
19 runs, 107 assertions, 0 failures, 0 errors, 0 skips
```

## I18n Resolution Check

Command:

```bash
bin/rails runner 'puts I18n.t("admin.payments.statuses.pending", locale: :"zh-TW"); puts I18n.t("admin.payments.statuses.pending", locale: :en)'
```

Result:

```text
待付款
Pending
```

## Static Check

Command:

```bash
git diff --check
```

Result: pass.

## Decision

pass

## Remaining Gaps

- Full Rails suite was not run.
- No browser check was run for this copy/key cleanup.
- This does not address broader reconciliation policy or provider settlement UX.
