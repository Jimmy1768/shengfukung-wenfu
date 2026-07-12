# Eval Record: Account/Admin Final Polish

Eval id: `shengfukung-2026-07-12-account-admin-final-polish-eval`

Created: 2026-07-12

Evaluator: Wenfu Handoff `019f5519-0f72-7273-b50e-65739e5a2a36`

Mode: bounded source review, compiled CSS verification, and Rails regression coverage

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `main`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-account-admin-final-polish.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-account-admin-final-polish-return.md`

## Objective

Evaluate the core account/admin layouts for narrow, high-confidence polish defects in responsive behavior and header readability without changing routes, persistence, authority, or business rules.

## Pages Reviewed

Account:

- layout shell in `rails/app/views/layouts/account.html.erb`;
- dashboard in `rails/app/views/account/dashboard/index.html.erb`;
- login and signup entry coverage through `rails/test/integration/account/sessions_test.rb`.

Admin:

- layout shell in `rails/app/views/layouts/admin.html.erb`;
- dashboard in `rails/app/views/admin/dashboard/index.html.erb`;
- login entry coverage through `rails/test/integration/admin/sessions_test.rb`.

## Defects Fixed

1. Both account and admin layouts omitted viewport metadata, which prevents the existing responsive CSS from rendering at intended mobile widths.
2. Admin flash badges were forced to `white-space: nowrap`, which can widen the header and cause overflow on smaller screens when notices are long.

## Evidence

Browser evidence:

- In-app browser tooling was requested but not exposed in this task environment, so no live browser walkthrough was performed.

Source and asset evidence:

- Added `<meta name="viewport" content="width=device-width, initial-scale=1" />` to both owned layouts.
- Updated admin flash tray CSS to allow long messages to wrap inside the header.
- Rebuilt checked-in Rails CSS with the repo-root `bin/build_rails_css` script; this checkout does not contain the packet's `rails/bin/build_rails_css` path.
- Verified the rebuilt `rails/public/backend/assets/admin.css` contains the new flash wrapping rules.

Regression evidence:

- `cd rails && bin/rails test test/integration/account test/integration/admin`
  - `141 runs, 1044 assertions, 0 failures, 0 errors, 0 skips`
- `cd rails && bin/rails test`
  - `313 runs, 1766 assertions, 0 failures, 0 errors, 0 skips`

## Decision

pass_with_gaps

## Remaining Gaps

- No browser-based visual confirmation was possible because no browser control tool was available in this handoff environment.
- The packet's build command path was stale for this checkout; the local equivalent succeeded from repo root.
- Existing Rack deprecation warnings for `:unprocessable_entity` remain in test output and were outside this polish scope.
