# Execution Record: Admin Layout Width Regression

Execution id: `shengfukung-2026-06-12-admin-layout-width-regression-execution`

Record created: 2026-06-12

Execution date: 2026-06-12

Execution type: `agent_assisted`

Executor: Shengfukung Wenfu implementation thread

Executor type: `implementation_thread`

Authority level: repo-local implementation authority for Rails/admin prototype code, tests, and OperatorKit docs only. No authority to deploy, change server config, rotate/access secrets, change payments, or touch production data.

Mode: prototype

Trigger/input: user-provided local browser screenshots showing broken admin layout width.

Handoff packet: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-layout-width-regression.md`

Execution return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-layout-width-regression-return.md`

Acceptance record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-admin-layout-width-regression-acceptance.md`

Repo/path: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch/worktree state: branch `offering-setup-admin-workflow`; latest commit before local changes was `522eb20 Record blocked offering setup browser review`; branch was `0 behind, 3 ahead` of `origin/offering-setup-admin-workflow`.

## Actions Taken

- Reviewed the user-provided screenshots.
- Inspected admin layout and component SCSS.
- Identified `fit-content(...)` stack-item rules as the shrink-wrap cause.
- Removed the shrink-wrap support block.
- Made default, hero, wide, metrics, and fluid stack items use available admin main width with a 960px desktop cap where appropriate.
- Preserved intentionally narrow/form-card constraints.
- Added missing source SCSS for existing compiled hero image status color rules.
- Rebuilt the committed admin CSS asset.
- Added a focused CSS regression test.
- Ran focused verification.
- Created return and acceptance records.

## Files Read

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/stylesheets/admin/_layout.scss`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/stylesheets/admin/_components.scss`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/public/backend/assets/admin.css`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/layouts/admin.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/dashboard/index.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offerings/index.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/new.html.erb`

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-layout-width-regression.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-layout-width-regression-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-admin-layout-width-regression-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-admin-layout-width-regression-execution.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/stylesheets/admin/_components.scss`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/stylesheets/admin/_layout.scss`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/public/backend/assets/admin.css`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/layout_css_test.rb`

## Commands Run

```bash
bin/build_rails_css
```

Result: pass.

```bash
bin/rails test test/integration/admin/layout_css_test.rb
```

Result:

```text
1 runs, 8 assertions, 0 failures, 0 errors, 0 skips
```

```bash
bin/rails test test/integration/admin/layout_css_test.rb test/integration/admin/offering_setup_drafts_test.rb
```

Result:

```text
9 runs, 206 assertions, 0 failures, 0 errors, 0 skips
```

```bash
git diff --check
```

Result: pass.

## External Services Called

None.

## Secrets Accessed

None.

## Verification Evidence

CSS source and served admin CSS no longer contain the shrink-wrap `fit-content(...)` stack-item rules. Focused tests passed, including the offering setup draft integration coverage.

## Skipped/Refused Actions

- No post-fix authenticated browser takeover was performed because the approved in-app Browser surface cannot control the authenticated external browser tab.
- Full Rails suite was not run.
- No deployment was performed.
- No server, secret, payment, or production-data action was performed.
- No YAML files were changed.

## Freeze Conditions Hit

None.

## Risk/Residual Gaps

This was `accepted_with_gaps` for prototype/local branch mode only.

Residual gaps:

- post-fix visual browser screenshot remains manual;
- additional visual differences from the approved droplet layout, if any, remain separate review items.

## Accepted By

Shengfukung Wenfu coordinator thread.

## Result

`accepted_with_gaps`

This record preserves the admin layout width regression acceptance decision. It should not be treated as production acceptance or promotion approval.

## Next Owner

Coordinator/product owner should continue browser/manual review after refreshing the local test browser.

## Rollback/Disable Path

Prototype branch only. Revert this checkpoint commit if the layout fix needs to be removed. No production deployment occurred.

## Reputation/Payment Eligibility

`not_applicable`
