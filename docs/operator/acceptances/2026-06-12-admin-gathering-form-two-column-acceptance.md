# Acceptance: Admin Gathering Form Two-Column Layout

Acceptance id: `shengfukung-2026-06-12-admin-gathering-form-two-column-acceptance`

Created: 2026-06-12

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-gathering-form-two-column.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-gathering-form-two-column-return.md`

Related execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-admin-gathering-form-two-column-execution.md`

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

- Post-fix visual screenshot was not captured by this thread because the approved in-app Browser surface cannot control the authenticated external browser tab.
- Full Rails suite was not run.

These gaps are acceptable for this local prototype layout fix, pending manual browser refresh.

## Required Retry

None unless manual browser refresh still shows the gathering form as a narrow single-column surface.

## Friction To Record

No new friction record required beyond the existing browser-control limitation.

## Next Owner

Coordinator should create the execution record and commit the checkpoint. User should hard refresh the local admin gathering form and confirm the visual result.

## Meeting Needed

No.

## Promotion Allowed

No production promotion. Prototype/local branch acceptance only.
