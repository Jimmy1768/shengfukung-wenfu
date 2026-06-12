# Return: Admin Setup Form Two-Column Retry

Handoff id: `shengfukung-2026-06-12-admin-setup-form-two-column-retry`

Created: 2026-06-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Objective

Correct the failed layout fix by matching the approved droplet pattern: restore outer admin stack sizing and make the setup draft form use the existing two-column offering form stage.

## What Was Wrong Before

The previous checkpoint fixed the wrong layer.

It removed `fit-content(...)` outer stack sizing, which widened the title/card containers, but the setup draft form itself still rendered as plain stacked sections. User review correctly found that each section container remained single-column instead of using the two-column offering form layout.

## Droplet Comparison

Read-only comparison was made against public deployed CSS:

```text
https://shengfukung.com.tw/backend/assets/admin.css
```

Findings:

- droplet CSS preserves `@supports (width: fit-content(560px))` for outer admin stack sizing;
- droplet CSS uses `.offering-form-stage` with two desktop columns at `min-width: 900px`;
- local setup draft form did not opt into `.offering-form-stage`.

## Completed Work

- Restored outer admin stack sizing to the droplet-style rules, including the `fit-content(...)` support block.
- Changed setup draft `form_with` to render as `form-stack stack-item stack-item--fluid`.
- Wrapped setup draft sections in `offering-form-grid` and `offering-form-stage`.
- Put basics, pricing, and structure sections in the primary column.
- Put registration intake in the secondary column list.
- Rebuilt the served admin CSS asset.
- Replaced the incorrect layout regression test with a test for the setup draft two-column contract.
- Added an integration assertion that `/admin/offering_setup_drafts/new` renders the fluid stage classes.

## Branch

- Branch role: continuing implementation branch.
- Branch name: `offering-setup-admin-workflow`.

## Latest Commit At Return Creation

- `62bd799 Fix admin layout width regression`

The retry work was not committed at return creation time.

## State At Return Creation

- Staged: none.
- Unstaged:
  - `rails/app/stylesheets/admin/_layout.scss`
  - `rails/app/views/admin/offering_setup_drafts/_form.html.erb`
  - `rails/public/backend/assets/admin.css`
  - `rails/test/integration/admin/layout_css_test.rb`
  - `rails/test/integration/admin/offering_setup_drafts_test.rb`
- Untracked:
  - `docs/operator/handoffs/2026-06-12-admin-setup-form-two-column-retry.md`
  - this return record
- Committed: not yet.
- Pushed: not pushed.
- Ahead/behind against `origin/offering-setup-admin-workflow`: `0 behind, 4 ahead`.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-setup-form-two-column-retry.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-setup-form-two-column-retry-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/stylesheets/admin/_layout.scss`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/_form.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/public/backend/assets/admin.css`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/layout_css_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/offering_setup_drafts_test.rb`

## Verification

Command:

```bash
bin/build_rails_css
```

Result: pass.

Command:

```bash
bin/rails test test/integration/admin/layout_css_test.rb test/integration/admin/offering_setup_drafts_test.rb
```

Result:

```text
10 runs, 221 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

## Browser Evidence

The retry was driven by user-provided authenticated local browser screenshots and user feedback.

Post-fix visual browser verification was not performed by this thread because the approved in-app Browser surface still cannot control the authenticated external browser tab. The local test server remained available for manual refresh.

## Skipped Checks

- Full Rails suite was not run.
- Automated post-fix screenshot was not captured by this thread.

## Boundary Confirmation

- Rails stylesheets/admin CSS asset: touched.
- Rails admin setup draft view: touched.
- Rails runtime/product behavior: not intentionally changed.
- Vue: not touched.
- Expo: not touched.
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

- Manual browser refresh is still needed to confirm the exact visual result.
- If there are additional differences from the droplet beyond setup form stage layout, those remain separate review items.

## Product Gaps Found

No product behavior gap found. This was a presentation/layout retry.

## Next Owner

Coordinator should accept this retry if the evidence is sufficient, create the execution record, and commit the checkpoint.
