# Return: Admin Layout Width Regression

Handoff id: `shengfukung-2026-06-12-admin-layout-width-regression`

Created: 2026-06-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Objective

Fix the admin console width regression visible in manual browser screenshots, where admin cards and forms shrink-wrapped into narrow columns and left most of the desktop workspace empty.

## Completed Work

- Removed the `fit-content(...)` admin stack-item width rules that caused cards to shrink-wrap.
- Changed default admin stack items to fill the available admin main workspace up to a 960px cap.
- Changed hero and wide stack items to use the same 960px desktop cap.
- Changed fluid table cards back to full-width flex behavior.
- Preserved explicit narrow/form-card constraints for intentionally narrower surfaces.
- Rebuilt the served admin CSS asset at `rails/public/backend/assets/admin.css`.
- Added a focused regression test to prevent the admin stack-item shrink-wrap rule from returning.
- Preserved hero image status color rules in source SCSS so the rebuilt CSS did not drop existing behavior.

## Branch

- Branch role: continuing implementation branch.
- Branch name: `offering-setup-admin-workflow`.

## Latest Commit At Return Creation

- `522eb20 Record blocked offering setup browser review`

The layout fix was not committed at return creation time.

## State At Return Creation

- Staged: none.
- Unstaged:
  - `rails/app/stylesheets/admin/_components.scss`
  - `rails/app/stylesheets/admin/_layout.scss`
  - `rails/public/backend/assets/admin.css`
- Untracked:
  - `docs/operator/handoffs/2026-06-12-admin-layout-width-regression.md`
  - this return record
  - `rails/test/integration/admin/layout_css_test.rb`
- Committed: not yet.
- Pushed: not pushed.
- Ahead/behind against `origin/offering-setup-admin-workflow`: `0 behind, 3 ahead`.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-layout-width-regression.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-layout-width-regression-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/stylesheets/admin/_components.scss`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/stylesheets/admin/_layout.scss`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/public/backend/assets/admin.css`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/layout_css_test.rb`

## Verification

Command:

```bash
bin/build_rails_css
```

Result: pass.

Command:

```bash
bin/rails test test/integration/admin/layout_css_test.rb
```

Result:

```text
1 runs, 8 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
bin/rails test test/integration/admin/layout_css_test.rb test/integration/admin/offering_setup_drafts_test.rb
```

Result:

```text
9 runs, 206 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

## Browser Evidence

The defect was confirmed from user-provided authenticated local browser screenshots.

Post-fix browser verification was not performed by this thread because the approved in-app Browser surface still cannot see or control the authenticated external browser tab.

## Skipped Checks

- Full Rails suite was not run.
- Post-fix visual browser screenshot was not captured by this thread.

## Boundary Confirmation

- Rails app runtime code: not touched.
- Rails stylesheets and served CSS asset: touched.
- Vue: not touched.
- Expo: not touched.
- Admin product behavior: not touched.
- Temple data: local test database only.
- Payment/accounting: not touched.
- Public offering config/YAML: not touched.

## Deployment And Production Impact

- No deployment performed.
- No server config changed.
- No secrets accessed or changed.
- No payment provider config changed.
- No production data touched.
- No migration added.

## Residual Risk

- The layout fix is verified by CSS regression tests and targeted admin request tests, but not by an automated post-fix screenshot in this thread.
- If the approved droplet layout has additional visual differences beyond card width, those remain separate review items.

## Product Gaps Found

No product behavior gap found. This was a presentation/layout regression.

## Next Owner

Coordinator should accept the bounded layout fix if the evidence is sufficient, create the execution record, and commit the checkpoint.
