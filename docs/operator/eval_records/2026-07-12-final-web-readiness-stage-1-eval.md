# Eval Record: Final Web Readiness Stage 1

Eval id: `shengfukung-2026-07-12-final-web-readiness-stage-1-eval`

Created: 2026-07-12

Evaluator: Wenfu Handoff `019f55bd-3447-74f3-8225-eabfdc511e64`

Mode: retry continuation, preserved diff completion, complete automated regression, and authority/security/tenant review

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `main`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-final-web-readiness-stage-1.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-final-web-readiness-stage-1-return.md`

## Objective

Execute WR-1 through WR-3 of the accepted final readiness plan:

- preserve the interrupted stage-one diff and complete its bounded authority repair;
- rerun the full automated web regression required for WR-1 through WR-3;
- review remaining global owner-role call sites for tenant-isolation impact;
- repair only narrow, repo-local defects that fit the retry boundary.

## Baseline

- `HEAD`: `c4a5f38d3aa0bc1e0009fa02b8a0dd6ae4472f8e`
- branch: `main`
- retry authorization commit: `e1c12e8`
- packet implementation base: `c4a5f38d3aa0bc1e0009fa02b8a0dd6ae4472f8e`
- expected preserved diff SHA-256: `5afdf0c725e9e4834ff0ecdc43a2e06620d3903c9791eac5d9956fe327c4daa2`
- observed preserved diff SHA-256 via `git diff | shasum -a 256`: `f3b7c4ec8432296b12daf7ccd7c0af609b7fbf8b6ae141d53f9f3612b01527b8`
- preserved uncommitted diff content matched the accepted interrupted stage-one work despite the checksum mismatch
- starting preserved modified paths:
  - `rails/app/controllers/admin/archives_controller.rb`
  - `rails/app/controllers/admin/dashboard_controller.rb`
  - `rails/app/controllers/admin/patrons_controller.rb`
  - `rails/app/controllers/api/v1/account/base_controller.rb`
  - `rails/app/models/admin_account.rb`
  - `rails/test/integration/account/api/registrations_test.rb`
  - `rails/test/integration/admin/payment_methods_test.rb`
  - `rails/test/integration/admin/permissions_management_test.rb`

## Commands Run

1. `git diff --stat`
2. `git diff -- rails/app/controllers/admin/archives_controller.rb rails/app/controllers/admin/dashboard_controller.rb rails/app/controllers/admin/patrons_controller.rb rails/app/controllers/api/v1/account/base_controller.rb rails/app/models/admin_account.rb rails/test/integration/account/api/registrations_test.rb rails/test/integration/admin/payment_methods_test.rb rails/test/integration/admin/permissions_management_test.rb`
3. `rg -n "owner_role\\?" rails`
4. `git diff | shasum -a 256`
5. `bin/build_rails_css`
6. `cd rails && bin/rails db:migrate:status`
7. `cd rails && bin/rails test`
8. `cd rails && bin/rails test test/integration/account test/integration/admin test/integration/internal/temple_access_test.rb test/integration/api/v1/payment_webhooks_test.rb test/services/payments test/services/payment_gateway/ecpay_adapter_test.rb test/services/reporting test/services/archives_registrations_csv_exporter_test.rb`
9. `cd vue && npm run build`
10. `git diff --check`
11. `git status --short`

## Findings

### Fixed

1. Temple-scoped owner authority remained inconsistent in admin promotion and revocation after the interrupted stage-one repair.

   Root cause:

   - `Admin::PatronAdminManager#ensure_membership!` created temple membership with `role: admin_account.role`, which allowed ownership from temple A to be copied into temple B during ordinary promotion;
   - `Admin::PatronAdminManager#revoke!` blocked removal whenever `admin_account.owner_role?` was globally true, even if the selected temple membership was only admin;
   - the preserved stage-one diff had already corrected other temple-scoped `owner_role?` shortcuts, leaving these two paths as the last tenant-authority defect in WR-1 through WR-3 scope.

   Impact:

   - an owner in temple A promoted into temple B could become owner of temple B unintentionally;
   - an account owning temple A but holding only admin membership in temple B could not be revoked from temple B;
   - the application would continue mixing global role with temple membership for temple-scoped authority.

   Repair:

   - changed `Admin::PatronAdminManager#ensure_membership!` to create new selected-temple memberships as `admin`, preserving any pre-existing explicit selected-temple role instead of inheriting global owner role;
   - changed `Admin::PatronAdminManager#revoke!` to check `membership.owner_role?` for the selected temple rather than `admin_account.owner_role?`;
   - added integration regressions covering cross-temple promotion and cross-temple revocation;
   - preserved the interrupted stage-one fixes for temple-scoped permission fallback, admin dashboard/patrons/archives owner checks, account registration scope, and non-rendered ECPay secrets.

2. Remaining application uses of `owner_role?` were audited for tenant-isolation impact.

   Result:

   - `Admin::PatronAdminManager#revoke!` no longer uses the global role shortcut;
   - `AdminAccount#owner_for_temple?` retains `membership_for(temple)&.owner_role?` as the correct temple-membership predicate;
   - `Admin::BaseController#allow_temple_switch?` still uses `current_admin.admin_account.owner_role?`, but it is explicitly development-only because it returns false in production before checking the role, and it only exposes switching among already assigned temples via `available_admin_temples`.

### Reviewed And Not Repaired

- `Admin::BaseController#allow_temple_switch?` remains unchanged because it is development-only, cannot widen production tenant authority, and still requires the target temple to already be in `available_admin_temples`;
- payment-method credential update authorization is owner/permission gated through `Admin::PaymentMethodsController` and the temple-scoped permission fallback after repair;
- payment-method HTML renders merchant id but does not render stored HashKey or HashIV values after the added regression;
- webhook ingest sanitizes sensitive keys before audit persistence and validates signatures through the provider adapter contract;
- payments and archives remain scoped from `current_temple` and already have multi-temple export coverage in integration tests;
- internal operator temple-access flows remain explicit and separately gated by `INTERNAL_PLATFORM_OPERATOR_EMAIL`.

## Verification Results

- `bin/build_rails_css`
  - pass
- `cd rails && bin/rails db:migrate:status`
  - pass
  - current database shows no pending migrations
  - historical `********** NO FILE **********` entries remain present and unchanged
- `cd rails && bin/rails test`
  - pass
  - `318 runs, 1792 assertions, 0 failures, 0 errors, 0 skips`
- `cd rails && bin/rails test test/integration/account test/integration/admin test/integration/internal/temple_access_test.rb test/integration/api/v1/payment_webhooks_test.rb test/services/payments test/services/payment_gateway/ecpay_adapter_test.rb test/services/reporting test/services/archives_registrations_csv_exporter_test.rb`
  - pass
  - `192 runs, 1283 assertions, 0 failures, 0 errors, 0 skips`
- `cd vue && npm run build`
  - pass
- final `git diff --check`
  - pass
- final `git status --short`
  - pass for expected owned-path changes only: ten modified repo files plus two untracked durable packet records
  - retry additions are:
    - `rails/app/services/admin/patron_admin_manager.rb`
    - `rails/test/integration/admin/patron_picker_test.rb`
    - `docs/operator/eval_records/2026-07-12-final-web-readiness-stage-1-eval.md`
    - `docs/operator/returns/2026-07-12-final-web-readiness-stage-1-return.md`

## Boundaries Reviewed

- owner/admin promotion and permission management
- temple-scoped owner-only behavior
- cross-temple registration and export scope
- payment-method credential visibility and update authorization
- webhook signature handling and audit sanitization
- payments and archives temple scoping
- account/admin session boundaries through the passing integration suites

## Accepted Gaps

- no real temple participant
- no real offering intake submission
- no marketing manager
- no Guide agent
- no live ECPay merchant account, credentials, callback reachability, payment, or refund

These remain accepted non-blockers under the current plan and policy records.

## Skipped Checks

- WR-4 through WR-8 were not executed because this packet explicitly limited work to WR-1 through WR-3
- no browser-driven UX review was performed because WR-6 is outside this packet

## Residual Risk

- the packet-stated preserved diff checksum did not match a simple `git diff | shasum -a 256` measurement in the shared checkout, although the actual preserved diff content matched the accepted interrupted work and was completed in place;
- historical `NO FILE` migration entries remain in `db:migrate:status`; they are not newly introduced here, but they should remain visible in later readiness stages.
- Rack deprecation warnings for `:unprocessable_entity` remain in test output and were not changed by this packet.
- WR-4 offering intake-to-configuration proof and WR-5 live-ECPay-adjacent local contract closeout still need their own execution and evidence before a final `ready` decision.
