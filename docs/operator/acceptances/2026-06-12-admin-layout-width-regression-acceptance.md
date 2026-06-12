# Acceptance: Admin Layout Width Regression

Acceptance id: `shengfukung-2026-06-12-admin-layout-width-regression-acceptance`

Created: 2026-06-12

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-layout-width-regression.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-layout-width-regression-return.md`

Related execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-admin-layout-width-regression-execution.md`

## Decision

accepted_with_gaps

## Decision Reason

The bounded layout regression is fixed at the CSS source and served asset level.

Accepted behavior:

- admin stack items no longer use `fit-content(...)` shrink-wrap rules;
- normal admin cards fill available admin main width up to the desktop cap;
- wide and hero cards use the wider desktop cap;
- fluid table cards keep full-width behavior;
- intentionally narrow/form-card variants remain constrained;
- the served admin CSS asset was rebuilt;
- a regression test now guards against reintroducing shrink-wrap admin stack-item rules;
- no product behavior, deployment, payment, secret, server-config, production-data, or YAML-write action occurred.

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
bin/rails test test/integration/admin/layout_css_test.rb
```

Result:

```text
1 runs, 8 assertions, 0 failures, 0 errors, 0 skips
```

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/integration/admin/layout_css_test.rb test/integration/admin/offering_setup_drafts_test.rb
```

Result:

```text
9 runs, 206 assertions, 0 failures, 0 errors, 0 skips
```

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu`:

```bash
git diff --check
```

Result: pass.

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit before layout changes: `522eb20 Record blocked offering setup browser review`

Observed changed files before this acceptance record was added:

```text
 M rails/app/stylesheets/admin/_components.scss
 M rails/app/stylesheets/admin/_layout.scss
 M rails/public/backend/assets/admin.css
?? docs/operator/handoffs/2026-06-12-admin-layout-width-regression.md
?? docs/operator/returns/2026-06-12-admin-layout-width-regression-return.md
?? rails/test/integration/admin/layout_css_test.rb
```

## Boundary Reviewed

- Rails stylesheets/admin CSS asset: touched.
- Rails runtime behavior: not touched.
- Vue: not touched.
- Expo: not touched.
- Payment/accounting: not touched.
- YAML writes: avoided.
- Published/live offerings: not touched.
- Deployment/server/secrets/production data: not touched.

## Accepted Gaps

- Post-fix visual screenshot was not captured by this thread because the approved in-app Browser surface cannot control the authenticated external browser tab.
- Full Rails suite was not run.

These gaps are acceptable for this bounded layout regression fix.

## Rejected Items

None.

## Required Retry

None for the CSS regression fix.

## Friction To Record

No separate friction record required beyond the already-recorded browser-control limitation.

## Next Owner

Coordinator should create the execution record and commit the checkpoint.

## Meeting Needed

No.

## Docs Update Needed

No product docs update needed.

## Promotion Allowed

No production promotion. Prototype/local branch acceptance only.
