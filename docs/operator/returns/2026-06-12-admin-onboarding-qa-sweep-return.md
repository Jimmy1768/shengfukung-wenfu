# Return: Admin Onboarding QA Sweep

Handoff id: `shengfukung-2026-06-12-admin-onboarding-qa-sweep`

Created: 2026-06-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

## Objective

Run a bounded local QA sweep of the admin onboarding surfaces after the offering setup, registration intake, local review environment, and layout fixes.

## Result

Completed.

The local prototype sweep passed with residual production gaps. This return does not claim production readiness.

## Review Environment

- Rails environment: `development`
- Review database: `golden_template_review`
- Review cookie key: `_shengfukung_wenfu_review_session`
- Review server: `http://127.0.0.1:3312`
- Review admin: `operator-ui-review@example.test`
- Browser surface: Codex in-app Browser
- Data scope: disposable local review data only

## Completed Coverage

- Confirmed review database exists and migrations apply.
- Recreated the disposable review admin account.
- Verified local login endpoint rendered.
- Exercised Rails request stack with an in-process integration session against `golden_template_review`.
- Verified admin login and dashboard redirect.
- Verified dashboard, offerings, offering setup index/new, gatherings index/new routes render.
- Verified offering setup new form includes two-column layout markers.
- Created a realistic bright-lamp service setup draft with five option rows.
- Verified selected setup fields, options, and registration intake fields persisted.
- Edited the draft and verified updated registration fields persisted.
- Submitted and reviewed the draft.
- Verified reviewed draft edit and update attempts are locked.
- Applied the draft and verified the applied target is a `TempleService` with `status: draft`.
- Verified applied service metadata includes setup draft id, four lamp options, and registration form sections.
- Verified re-applying the same draft is idempotent and does not create a duplicate service.
- Verified event apply remains blocked with HTTP `422` and leaves the event draft reviewed.
- Created a gathering through the admin route and verified it appears on the gatherings index.
- Verified no YAML file changed during admin actions.
- Logged into the local review server in the in-app Browser.
- Captured Browser geometry and screenshots for offering setup and gathering form layouts.
- Ran focused Rails tests.

## Evidence Files

- Eval record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-onboarding-qa-sweep-eval.md`
- Offering setup screenshot: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-onboarding-qa-sweep-offering-setup.jpg`
- Gathering form screenshot: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-onboarding-qa-sweep-gathering-new.jpg`

## Browser Layout Result

Offering setup at `1280x720`:

- stage: `x=292`, `width=988`
- primary column: `x=292`, `width=547`
- secondary column: `x=852`, `width=428`

Gathering form at `1280x720`:

- stage: `x=292`, `width=988`
- primary column: `x=292`, `width=547`
- secondary column: `x=852`, `width=428`

Both forms rendered as desktop two-column layouts in the in-app Browser.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-onboarding-qa-sweep.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-onboarding-qa-sweep-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-onboarding-qa-sweep-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-onboarding-qa-sweep-offering-setup.jpg`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-onboarding-qa-sweep-gathering-new.jpg`

No app/runtime code was changed.

## Verification

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails db:create
```

Result: pass.

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session bin/rails db:migrate
```

Result: pass.

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session ADMIN_REVIEW_EMAIL=operator-ui-review@example.test ADMIN_REVIEW_PASSWORD='Password123!' bin/rails admin_review:prepare
```

Result: pass.

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session ADMIN_REVIEW_EMAIL=operator-ui-review@example.test ADMIN_REVIEW_PASSWORD='Password123!' bin/rails runner /private/tmp/shengfukung_admin_onboarding_sweep.rb
```

Result: pass. Output included:

```json
{
  "ok": true,
  "database": "golden_template_review",
  "service_draft": {
    "status": "applied",
    "applied_offering_type": "TempleService",
    "applied_service_status": "draft",
    "lamp_option_count": 4
  },
  "event_apply": {
    "status_after_apply_attempt": "reviewed",
    "response_status": 422
  },
  "yaml_changed": []
}
```

Browser check:

```text
Login to http://127.0.0.1:3312/admin/login with the disposable review admin, then inspect /admin/offering-setup/new and /admin/gatherings/new.
```

Result: pass.

Command:

```bash
bin/rails test test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/gatherings_layout_test.rb test/integration/admin/layout_css_test.rb test/integration/admin/sessions_test.rb
```

Result:

```text
14 runs, 260 assertions, 0 failures, 0 errors, 0 skips
```

## Skipped Checks

- Full Rails suite was not run.
- Production server check was not run.
- Large-data accounting QA was not run.
- Mobile browser layout was not separately swept in this checkpoint.

## Boundary Confirmation

- Rails app/runtime code: not changed.
- Vue: not touched.
- Expo: not touched.
- Payment provider configuration: not touched.
- Accounting behavior: not changed.
- Temple production data: not touched.
- Deployment/server config: not changed.
- Secrets: not accessed.
- YAML writes from admin: avoided; no YAML file changed during sweep.

## Draft-Only Apply

Confirmed. The applied target was `TempleService` and remained `status: draft`.

## Event Apply

Confirmed blocked. Event draft apply returned `422` and left the event draft in `reviewed`.

## Residual Risk

- This is local prototype evidence only.
- Full production-readiness acceptance still requires broader product QA.
- Accounting remains untested against large data.
- Mobile layout was not separately captured in this sweep.
- Browser screenshots prove rendered layout at `1280x720`, not every supported viewport.

## Next Owner

Coordinator should accept this local sweep with gaps, create the matching execution record, and commit the docs/evidence checkpoint.
