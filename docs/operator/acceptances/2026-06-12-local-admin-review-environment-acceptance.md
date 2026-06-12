# Acceptance: Local Admin Review Environment Isolation

Acceptance id: `shengfukung-2026-06-12-local-admin-review-environment-acceptance`

Created: 2026-06-12

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-local-admin-review-environment.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-local-admin-review-environment-return.md`

Related execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-local-admin-review-environment-execution.md`

## Decision

accepted_with_gaps

## Decision Reason

The implementation creates a repeatable local admin browser-review workflow that avoids the root issue: using `RAILS_ENV=test` as the browser server database.

Accepted behavior:

- `bin/review_admin_server` starts a local review server using `RAILS_ENV=development`;
- the review database defaults to `golden_template_review`;
- the review session cookie defaults to `_shengfukung_wenfu_review_session`;
- the reviewer account can be recreated through `admin_review:prepare`;
- normal Rails tests no longer delete the review DB reviewer account;
- production session cookie behavior is unchanged unless `RAILS_SESSION_COOKIE_KEY` is explicitly set;
- no deployment, production config, secrets, payment/accounting, production data, or product UI behavior changed.

## Verification Reviewed

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu`:

```bash
bin/review_admin_server --help
```

Result: pass.

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails db:create db:migrate
```

Result: pass.

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails admin_review:prepare
```

Result: pass; reviewer account had matching password and active owner admin role.

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu`:

```bash
curl -i -X POST http://127.0.0.1:3312/admin/login --data-urlencode 'session[email]=operator-ui-review@example.test' --data-urlencode 'session[password]=Password123!'
```

Result: pass; returned `302 Found` to `/admin/dashboard` and set `_shengfukung_wenfu_review_session`.

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/integration/admin/sessions_test.rb
```

Result:

```text
2 runs, 3 assertions, 0 failures, 0 errors, 0 skips
```

Ran after that test command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails runner '...reviewer account check...'
```

Result:

```json
{"exists":true,"user_id":7,"admin_active":true,"password_matches":true,"database":"golden_template_review"}
```

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu`:

```bash
bash -n bin/review_admin_server
```

Result: pass.

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu`:

```bash
git diff --check
```

Result: pass.

## Boundary Reviewed

- Local workflow only: touched.
- Rails session cookie override: touched with default-preserving env override.
- Product UI behavior: not intentionally changed.
- Payment/accounting: not touched.
- Deployment/server config: not touched.
- Secrets: not accessed.
- Production data: not touched.
- YAML writes: avoided.

## Accepted Gaps

- Full Rails suite was not run.
- In-app Browser text-entry submission was not completed because Browser automation reported its virtual clipboard was unavailable.
- Rails `db:create` in development mode still reports test database status, though this workflow does not run `RAILS_ENV=test` and no longer uses test DB for browser review.
- Existing development seed issue remains: `db:prepare` fails on unrelated invalid `staff` admin role.

These gaps are acceptable for this local workflow checkpoint.

## Required Retry

None for this checkpoint.

## Next Owner

Use `bin/review_admin_server` for future local browser QA. Treat the unrelated development seed `staff` role issue as a separate maintenance item if broad local `db:prepare` is needed.

## Promotion Allowed

No production promotion. Local workflow acceptance only.
