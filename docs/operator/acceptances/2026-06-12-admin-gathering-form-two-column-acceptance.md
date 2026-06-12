# Acceptance: Admin Gathering Form Two-Column Layout

Acceptance id: `shengfukung-2026-06-12-admin-gathering-form-two-column-acceptance`

Created: 2026-06-12

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-gathering-form-two-column.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-gathering-form-two-column-return.md`

Related execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-admin-gathering-form-two-column-execution.md`

Related eval record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-gathering-form-browser-eval.md`

## Decision

accepted_with_gaps

## Decision Reason

The implementation addresses the reported gathering layout defect within the local prototype branch.

Accepted behavior:

- gathering new/edit forms are no longer nested inside the narrow intro card;
- the gathering form is a fluid admin stack item;
- the form uses the same desktop two-column `offering-form-stage` convention as the repaired setup form;
- existing gathering params and create behavior are covered by focused integration tests;
- adjacent gathering order/accounting tests still pass;
- authenticated in-app Browser review confirms the gathering form renders in two columns at desktop width;
- authenticated in-app Browser create-submit flow succeeded for a disposable local gathering;
- admin CSS was rebuilt;
- no deployment, server config, secret, payment, accounting behavior, production data, or YAML-write action occurred.

## Mode Reviewed

prototype

## Verification Reviewed

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu`:

```bash
bin/build_rails_css
```

Result: pass.

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/integration/admin/layout_css_test.rb test/integration/admin/gatherings_layout_test.rb
```

Result:

```text
3 runs, 50 assertions, 0 failures, 0 errors, 0 skips
```

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/integration/admin/offering_orders_registrant_flow_test.rb test/integration/admin/accounting_reporting_gatherings_test.rb
```

Result:

```text
9 runs, 62 assertions, 0 failures, 0 errors, 0 skips
```

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu`:

```bash
git diff --check
```

Result: pass.

Browser eval:

```text
/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-gathering-form-browser-eval.md
```

Result: pass for local prototype.

Evidence summary:

- login reached `/admin/dashboard`;
- `/admin/gatherings/new` rendered the gathering form as a two-column desktop stage;
- primary column sections rendered at `x=292`;
- secondary column sections rendered at `x=844`;
- disposable gathering `Browser Test Gathering 1781259954731` submitted and appeared on `/admin/gatherings`.

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit before gathering layout changes: `20e060a Restore setup form two-column layout`

Observed changed files before acceptance/execution records were added:

```text
 M rails/app/stylesheets/admin/_components.scss
 M rails/app/views/admin/gatherings/_form.html.erb
 M rails/app/views/admin/gatherings/edit.html.erb
 M rails/app/views/admin/gatherings/new.html.erb
 M rails/config/locales/admin.en.yml
 M rails/config/locales/admin.zh-TW.yml
 M rails/public/backend/assets/admin.css
 M rails/test/integration/admin/layout_css_test.rb
?? docs/operator/handoffs/2026-06-12-admin-gathering-form-two-column.md
?? rails/test/integration/admin/gatherings_layout_test.rb
```

## Boundary Reviewed

- Rails admin gathering layout: touched.
- Locale labels: touched.
- Rails product behavior: not intentionally changed.
- Vue: not touched.
- Expo: not touched.
- Payment/accounting behavior: not touched.
- YAML writes: avoided.
- Published/live offerings: not touched.
- Deployment/server/secrets/production data: not touched.

## Accepted Gaps

- Full Rails suite was not run.
- Browser server still used `RAILS_ENV=test`, so future Rails test runs can wipe the disposable browser data/session.

These gaps are acceptable for this local prototype layout fix.

## Required Retry

None.

## Friction To Record

No new friction record required beyond the existing browser-control limitation.

## Next Owner

Coordinator should commit the docs-only browser evidence update. Next implementation work should start by stabilizing the local review environment so browser sessions are not backed by the Rails test database.

## Meeting Needed

No.

## Promotion Allowed

No production promotion. Prototype/local branch acceptance only.
