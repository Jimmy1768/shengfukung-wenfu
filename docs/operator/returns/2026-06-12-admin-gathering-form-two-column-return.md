# Return: Admin Gathering Form Two-Column Layout

Handoff id: `shengfukung-2026-06-12-admin-gathering-form-two-column`

Created: 2026-06-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Objective

Fix the admin gathering create/edit form layout after user review confirmed offering setup was repaired but gatherings still rendered as one long narrow column.

## Completed Work

- Moved gathering new/edit forms out of the narrow intro card and into their own fluid admin stack row.
- Changed the gathering form to render as `form-stack stack-item stack-item--fluid gathering-form`.
- Reorganized gathering fields into a two-column `offering-form-stage gathering-form-stage`:
  - primary column: basic details, pricing, schedule;
  - secondary column: cover image, location/status.
- Preserved existing field names, submit params, free/paid toggle selectors, date-range selectors, media upload selectors, and controller behavior.
- Replaced the stale direct `.gathering-form` grid CSS with stage-specific gathering form CSS that works with the existing form stack/stage pattern.
- Added English and Traditional Chinese locale labels for the new form sections.
- Rebuilt the committed admin CSS asset.
- Added focused tests for rendered gathering layout classes and create-submit behavior.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-gathering-form-two-column.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-gathering-form-two-column-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/stylesheets/admin/_components.scss`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/gatherings/_form.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/gatherings/edit.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/gatherings/new.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/public/backend/assets/admin.css`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/gatherings_layout_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/layout_css_test.rb`

## Verification

Command:

```bash
bin/build_rails_css
```

Result: pass.

Command:

```bash
bin/rails test test/integration/admin/layout_css_test.rb test/integration/admin/gatherings_layout_test.rb
```

Result:

```text
3 runs, 50 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
bin/rails test test/integration/admin/offering_orders_registrant_flow_test.rb test/integration/admin/accounting_reporting_gatherings_test.rb
```

Result:

```text
9 runs, 62 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

## Browser Evidence

The work was driven by user-provided authenticated local browser screenshots showing the repaired offering setup page and the still-broken gathering form.

Post-fix authenticated browser verification was not performed by this thread because the approved in-app Browser surface cannot control the authenticated external browser tab. The local test server remains available for manual refresh.

## Skipped Checks

- Full Rails suite was not run.
- Automated post-fix screenshot was not captured by this thread.

## Boundary

- Rails admin gathering view/CSS/test files touched.
- Locale labels touched.
- Committed admin CSS asset rebuilt.
- No deployment.
- No server config change.
- No secret access or rotation.
- No payment/accounting behavior change.
- No production data.
- No YAML writes.

## Residual Risk

Manual visual confirmation is still needed on the authenticated admin gathering page to confirm the layout matches the approved offering setup pattern in the browser viewport.

## Next Owner

Coordinator should create the acceptance and execution records, commit the checkpoint, and ask the user to refresh the local gathering form.
