# Return: V1 Admin Accounting Policy Readiness

Handoff id: `shengfukung-2026-06-13-v1-admin-accounting-policy-readiness`

Created: 2026-06-13

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

## Objective

Implement the next bounded Rails/admin pass from the accepted V1 accounting decisions:

- ECPay/provider-backed payments are trusted when confirmed locally from provider status;
- cash payments are admin-attested when staff marks cash received;
- failed/cancelled attempts do not count as received;
- refunds are not completed revenue;
- the previous-month export process is manual/external and should happen on the 1st day of each month.

## Reviewed Decision Records

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-help-guide-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-accounting-reconciliation-readiness-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-admin-payment-status-locale-cleanup-return.md`

## Result

Completed with accepted gaps.

The admin payments surface now explicitly states the V1 source-of-truth policy and previous-month export workflow. The visible payments ledger now includes a source column, and the CSV export now includes source/provider/reference fields for audit handoff.

## Implementation Summary

- Added admin payment source labels:
  - admin-attested cash;
  - provider confirmed;
  - provider pending;
  - provider failed/cancelled;
  - provider refunded.
- Added a `收款依據` / `Source` column to the admin payments ledger.
- Added admin payments page copy explaining:
  - ECPay/provider-backed online payments count as received after provider confirmation;
  - cash is admin-attested when marked received;
  - failed/cancelled attempts are not received;
  - refunds are not completed revenue.
- Added payments filter/month copy explaining:
  - on the 1st of each month, choose Last month and export CSV for external accounting;
  - V1 does not lock the month.
- Added CSV export columns:
  - `Source`;
  - `Provider`;
  - `Provider Reference`.
- Added focused integration assertions for the new admin copy, source column, source label, and CSV fields.

## Browser Evidence

Browser surface: Codex in-app Browser against local isolated review server/database.

Review server:

`127.0.0.1:3312`

Payments page checked:

`/admin/payments`

Observed:

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
  "sampleSourceLabels": [
    "Stripe 已確認",
    "LINE Pay 已確認"
  ]
}
```

The first browser pass exposed that provider `demo` was not a helpful visible source label when the payment method was Stripe/LINE Pay. The visible source label was corrected to use the payment method; CSV still exports raw provider separately.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-v1-admin-accounting-policy-readiness-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-13-v1-admin-accounting-policy-readiness-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-13-v1-admin-accounting-policy-readiness-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-13-v1-admin-accounting-policy-readiness-execution.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/helpers/admin/filters_helper.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/reporting/payments_csv_exporter.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/_ledger_table.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payments/index.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

## Verification

Command:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb
```

Initial result:

```text
28 runs, 162 assertions, 0 failures, 0 errors, 0 skips
```

Final result after the visible source-label correction:

```text
28 runs, 162 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

Browser verification:

```text
Open local review payments page and inspect policy note, month-close hint, source column, and source labels.
```

Result: pass.

## Skipped Checks

- Full Rails suite was not run.
- Production accounting reconciliation was not tested.
- Real ECPay or payment provider calls were not made.
- Production payment data was not touched.
- Mobile/Expo was not checked because the Expo app has not been created.
- Help guide implementation and links were not added by design.

## Boundary Confirmation

- Rails admin UI/helper/export/locales/tests changed.
- Payment status state machine behavior was not changed.
- Payment provider configuration was not changed.
- Real payment providers were not called.
- Accounting close/lock state was not added.
- Provider settlement matching was not added.
- General ledger behavior was not changed.
- Vue: not touched.
- Expo/mobile: not touched.
- Deployment/server config: not changed.
- Secrets: not accessed.
- Production data: not touched.
- Existing `ops/docs/`: not touched.

## Residual Risk

- This makes V1 policy visible in admin screens and CSV, but it is not full provider settlement reconciliation.
- CSV export is still the V1 handoff to external accounting; no export-history or close marker exists.
- Browser evidence used local seeded review data, not real provider data.
- Production promotion remains blocked by the production-boundary decision.

## Follow-Up Gaps

- Real ECPay default path still needs local/sandbox verification before V1 acceptance.
- Previous-month export needs explicit browser/admin rehearsal in a V1 acceptance pass.
- Comprehensive help guide must be created after V1 behavior settles.
- One real temple admin/staff rehearsal is still required for V1 acceptance.

## Next Owner

Coordinator/implementation thread should create matching acceptance and execution records, commit, push, then continue with the next V1 acceptance gap.
