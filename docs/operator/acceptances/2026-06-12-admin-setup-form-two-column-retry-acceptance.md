# Acceptance: Admin Setup Form Two-Column Retry

Acceptance id: `shengfukung-2026-06-12-admin-setup-form-two-column-retry-acceptance`

Created: 2026-06-12

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-setup-form-two-column-retry.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-setup-form-two-column-retry-return.md`

Related execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-admin-setup-form-two-column-retry-execution.md`

Supersedes incomplete acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-admin-layout-width-regression-acceptance.md`

## Decision

accepted_with_gaps

## Decision Reason

The retry fixes the actual failed layer from user review.

Accepted behavior:

- outer admin stack sizing is restored to the public droplet CSS pattern;
- setup draft forms render as a fluid admin stack item;
- setup draft forms use `.offering-form-stage` for two-column desktop section layout;
- basics, pricing, and structure are grouped in the primary column;
- registration intake is grouped in the secondary column;
- served admin CSS was rebuilt;
- tests now guard the setup draft form layout contract and rendered new-page classes;
- setup draft create/update/apply behavior still passes focused integration tests;
- no deployment, payment, secret, server-config, production-data, or YAML-write action occurred.

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
bin/rails test test/integration/admin/layout_css_test.rb test/integration/admin/offering_setup_drafts_test.rb
```

Result:

```text
10 runs, 221 assertions, 0 failures, 0 errors, 0 skips
```

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu`:

```bash
git diff --check
```

Result: pass.

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit before retry changes: `62bd799 Fix admin layout width regression`

Observed changed files before this acceptance record was added:

```text
 M rails/app/stylesheets/admin/_layout.scss
 M rails/app/views/admin/offering_setup_drafts/_form.html.erb
 M rails/public/backend/assets/admin.css
 M rails/test/integration/admin/layout_css_test.rb
 M rails/test/integration/admin/offering_setup_drafts_test.rb
?? docs/operator/handoffs/2026-06-12-admin-setup-form-two-column-retry.md
?? docs/operator/returns/2026-06-12-admin-setup-form-two-column-retry-return.md
```

## Boundary Reviewed

- Rails stylesheets/admin CSS asset: touched.
- Rails admin setup draft view: touched.
- Rails product behavior: not intentionally changed.
- Vue: not touched.
- Expo: not touched.
- Payment/accounting: not touched.
- YAML writes: avoided.
- Published/live offerings: not touched.
- Deployment/server/secrets/production data: not touched.

## Accepted Gaps

- Post-fix visual screenshot was not captured by this thread because the approved in-app Browser surface cannot control the authenticated external browser tab.
- Full Rails suite was not run.

These gaps are acceptable for this local prototype retry, pending manual browser refresh.

## Rejected Items

The prior acceptance for `62bd799` was incomplete and is superseded by this retry acceptance.

## Required Retry

None for this CSS/view retry unless manual refresh still shows mismatch.

## Friction To Record

No separate friction record required beyond the already-recorded browser-control limitation.

## Next Owner

Coordinator should create the execution record and commit the checkpoint. User should hard refresh the local admin page and confirm the visual result.

## Meeting Needed

No.

## Docs Update Needed

No product docs update needed.

## Promotion Allowed

No production promotion. Prototype/local branch acceptance only.
