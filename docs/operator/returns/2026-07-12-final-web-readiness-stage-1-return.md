# Return: Final Web Readiness Stage 1

Handoff id: `shengfukung-2026-07-12-final-web-readiness-stage-1-retry`

Created: 2026-07-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `main`

## status

completed

## checkout_observed

- observed `HEAD`: `c4a5f38d3aa0bc1e0009fa02b8a0dd6ae4472f8e`
- retry authorization commit: `e1c12e8`
- preserved implementation base: `c4a5f38d3aa0bc1e0009fa02b8a0dd6ae4472f8e`
- expected existing diff SHA-256: `5afdf0c725e9e4834ff0ecdc43a2e06620d3903c9791eac5d9956fe327c4daa2`
- observed existing diff SHA-256 via `git diff | shasum -a 256` before retry edits: `f3b7c4ec8432296b12daf7ccd7c0af609b7fbf8b6ae141d53f9f3612b01527b8`
- branch: `main`
- preserved starting diff content matched the interrupted stage-one work despite the checksum mismatch

## requested_profile

- requested_model: `gpt-5.4`
- requested_reasoning: `high`
- execution_profile: `authority_security_readiness_retry`

## changed_paths

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/archives_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/dashboard_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/patrons_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/api/v1/account/base_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/admin_account.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/admin/patron_admin_manager.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/account/api/registrations_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/payment_methods_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/permissions_management_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/patron_picker_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-07-12-final-web-readiness-stage-1-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-final-web-readiness-stage-1-return.md`

## root_cause

- the interrupted stage-one repair fixed several temple-scoped `owner_role?` shortcuts but left `Admin::PatronAdminManager` deriving temple behavior from the global account role
- ordinary promotion used `admin_account.role` when creating a selected-temple membership, so an owner from temple A could be promoted into temple B as owner
- revocation blocked on `admin_account.owner_role?`, so an owner of temple A could not have an admin-only membership removed from temple B
- the bounded repair makes selected-temple membership authoritative for both cases without changing the schema or public APIs

## remaining_owner_role_call_sites

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/admin_account.rb`
  - `membership_for(temple)&.owner_role?` remains the correct temple-membership predicate inside `owner_for_temple?`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/base_controller.rb`
  - `allow_temple_switch?` remains acceptable because it returns false in production before the role check and only allows switching among already assigned temples in development/test
- no remaining application call site widens temple-scoped authority through global `AdminAccount.owner_role?`

## checks

- `bin/build_rails_css`
  - pass
- `cd rails && bin/rails db:migrate:status`
  - pass
  - no pending migrations
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

## blockers

- none

## recommended_control_action

- accept WR-1 through WR-3 as complete with the cross-temple promotion and revocation fix applied
- dispatch the next bounded packet for WR-4 and WR-5, then continue through the remaining readiness stages before issuing the binary final readiness decision
