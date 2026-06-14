# Eval Record: Local Admin Agent QA Sweep

Eval id: `shengfukung-2026-06-14-local-admin-agent-qa-sweep-eval`

Created: 2026-06-14

Evaluator: Shengfukung Wenfu coordinator/implementation thread

Mode: local browser QA plus focused regression test

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-14-local-admin-agent-qa-sweep.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-14-local-admin-agent-qa-sweep-return.md`

## Objective

Evaluate whether the local admin rehearsal path is usable enough for agent QA and whether any obvious UI/localization defects remain in the checked path.

## Browser Evidence

Pass:

- admin login reached dashboard;
- dashboard, temple profile, offering setup, registrations, orders, payments, and payment methods loaded without error-like text;
- offering setup draft was saved;
- draft was submitted for review;
- draft was marked reviewed;
- draft was applied;
- applied service appeared in offering management and service detail;
- payments `上月` preset resolved to `2026-05-01` through `2026-05-31`;
- payments export link preserved previous-month filters;
- payments table showed accounting evidence columns: `收款依據`, `紀錄人員`, `處理時間`;
- payment methods page exposed ECPay setup fields;
- external ECPay link was not opened.

Fixed during eval:

- hardcoded `Mark as paid` on the Chinese orders page was replaced with localized `標記已收款`.

## Code Evidence

Changed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/orders/_table.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/orders_and_payments_access_test.rb`

## Verification

Focused command:

```bash
bin/rails test test/integration/admin/orders_and_payments_access_test.rb
```

Result:

```text
14 runs, 98 assertions, 0 failures, 0 errors, 0 skips
```

Static check:

```bash
git diff --check
```

Result: pass.

Browser check:

```text
Reloaded `/admin/orders`; `標記已收款` present and `Mark as paid` absent.
```

Result: pass.

## Decision

pass_with_gaps

## Remaining Gaps

- This is not the real temple staff rehearsal.
- This is not final V1 acceptance.
- Full Rails suite was not run.
- Staff comprehension, hesitation, and support burden remain unproven.
