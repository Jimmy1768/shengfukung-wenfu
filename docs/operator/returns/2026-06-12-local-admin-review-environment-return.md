# Return: Local Admin Review Environment Isolation

Handoff id: `shengfukung-2026-06-12-local-admin-review-environment`

Created: 2026-06-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Objective

Stabilize local browser QA for the admin console so Rails test runs no longer log out the browser session or delete the disposable reviewer account.

## Completed Work

- Added `bin/review_admin_server` as the local browser-review entrypoint.
- The wrapper runs Rails in `RAILS_ENV=development`, not `RAILS_ENV=test`.
- The wrapper defaults to isolated database `golden_template_review`.
- The wrapper defaults to isolated cookie key `_shengfukung_wenfu_review_session`.
- Added `RAILS_SESSION_COOKIE_KEY` support so local workflows can override the default session cookie name without changing production defaults.
- Added `admin_review:prepare` rake task to create/reset the disposable owner reviewer account and all admin permissions.
- Avoided `db:prepare` in the wrapper because this repo's current development seed path fails on an unrelated invalid `staff` admin role.
- The wrapper instead uses `db:create db:migrate` and then runs only `admin_review:prepare`.

## Local Usage

Command:

```bash
bin/review_admin_server
```

Default login:

```text
http://127.0.0.1:3312/admin/login

operator-ui-review@example.test
Password123!
```

Default local review settings:

```text
RAILS_ENV=development
PGDATABASE=golden_template_review
RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session
```

Supported overrides:

```text
ADMIN_REVIEW_HOST
ADMIN_REVIEW_PORT
ADMIN_REVIEW_DATABASE
ADMIN_REVIEW_SESSION_COOKIE
ADMIN_REVIEW_EMAIL
ADMIN_REVIEW_PASSWORD
ADMIN_REVIEW_TEMPLE_SLUG
ADMIN_REVIEW_TEMPLE_NAME
ADMIN_REVIEW_NAME
```

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-local-admin-review-environment.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-local-admin-review-environment-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/bin/review_admin_server`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/application.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/lib/tasks/admin_review.rake`

## Verification

Command:

```bash
bin/review_admin_server --help
```

Result: pass.

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails db:create db:migrate
```

Result: pass.

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails admin_review:prepare
```

Result:

```text
Admin review account ready:
  email: operator-ui-review@example.test
  password_matches: true
  admin_active: true
  admin_role: owner
  temple: operator-ui-review-temple
```

Command:

```bash
curl -i -X POST http://127.0.0.1:3312/admin/login --data-urlencode 'session[email]=operator-ui-review@example.test' --data-urlencode 'session[password]=Password123!'
```

Result: pass.

Evidence:

- returned `302 Found`;
- redirected to `http://127.0.0.1:3312/admin/dashboard`;
- set cookie key `_shengfukung_wenfu_review_session`.

Command:

```bash
bin/rails test test/integration/admin/sessions_test.rb
```

Result:

```text
2 runs, 3 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails runner '...reviewer account check...'
```

Result:

```json
{"exists":true,"user_id":7,"admin_active":true,"password_matches":true,"database":"golden_template_review"}
```

This was run after the Rails test command above, proving the test run did not delete the isolated review reviewer account.

Command:

```bash
bash -n bin/review_admin_server
```

Result: pass.

Command:

```bash
git diff --check
```

Result: pass.

## Exploratory Finding

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails db:prepare
```

Result: fail due unrelated development seed issue:

```text
ArgumentError: 'staff' is not a valid role
```

The wrapper avoids this by not running full development seeds.

## Browser Note

The in-app Browser reached the new review login page. Text entry through the Browser automation surface failed because the Browser virtual clipboard was unavailable in that tab. Login was therefore verified by HTTP POST and database checks for this workflow checkpoint.

## Boundary

- Local Rails workflow script touched.
- Local Rails rake task touched.
- Session cookie default behavior remains unchanged unless `RAILS_SESSION_COOKIE_KEY` is set.
- No deployment.
- No production server config change.
- No secret access or rotation.
- No payment/accounting behavior change.
- No production data.
- No product UI behavior change.
- No YAML writes.

## Skipped Checks

- Full Rails suite was not run.
- Full in-app Browser login submission was not completed because of the Browser virtual clipboard limitation.

## Residual Risk

- `db:create` in Rails development mode still announces the test database status; this workflow does not run the test suite or use `RAILS_ENV=test`, but Rails' built-in task output may mention `golden_template_test`.
- Existing development seeds still contain an unrelated invalid `staff` admin role and should be handled separately if broad `db:prepare` is needed.

## Next Owner

Coordinator should create the acceptance and execution records, commit this checkpoint, and use `bin/review_admin_server` for future local browser QA.
