# Return: Offering Setup Admin UI Rehearsal

Handoff id: `shengfukung-2026-06-12-offering-setup-admin-ui-rehearsal`

Created: 2026-06-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Objective

Run a local admin flow rehearsal for realistic Shengfukung-style service setup examples before expanding registration intake authoring, event apply, staging, or production readiness.

## Examples Rehearsed

The rehearsal was encoded as a focused request-level integration test that drives the admin setup routes:

1. `光明燈服務`
   - fields: `lamp_type`, `lamp_location`, `fulfillment_method`, `logistics_notes`
   - options include four `lamp_type` entries plus a fulfillment method.
2. `祈福斗燈`
   - fields: `blessing_target_type`, `blessing_names`, `certificate_hint`, `fulfillment_method`
   - options include four `blessing_target_type` entries plus a fulfillment method.
3. `供桌服務`
   - fields: `table_size`, `table_items`, `logistics_notes`, `fulfillment_method`
   - options include table sizes plus a fulfillment method.

## Completed Work

- Added a focused admin integration rehearsal test.
- The test creates each setup draft through the admin route.
- The test verifies selected catalog fields persist in `setup_payload["field_requirements"]`.
- The test verifies option entries persist, including option lists longer than three rows.
- The test verifies submit and review transitions work.
- The test verifies reviewed drafts cannot be changed before apply.
- The test applies each reviewed draft through the admin route.
- The test verifies each applied target is a draft `TempleService`.
- The test verifies resulting service metadata includes useful `form_fields`, `form_options`, `form_ui`, and default registration form metadata.

## Branch

- Branch role: continuing implementation branch.
- Branch name: `offering-setup-admin-workflow`.

## Latest Commit At Return Creation

- `dde90d1 Standardize Redis support layer`

The rehearsal work was not committed at return creation time.

## State At Return Creation

- Staged: none.
- Unstaged:
  - `rails/test/integration/admin/offering_setup_drafts_test.rb`
- Untracked:
  - `docs/operator/handoffs/2026-06-12-offering-setup-admin-ui-rehearsal.md`
  - this return record
- Committed: not yet.
- Pushed: not pushed.
- Ahead/behind against `origin/offering-setup-admin-workflow`: clean tracking state before local changes.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-offering-setup-admin-ui-rehearsal.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-offering-setup-admin-ui-rehearsal-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/offering_setup_drafts_test.rb`

## Verification

Command:

```bash
bin/rails test test/integration/admin/offering_setup_drafts_test.rb
```

Result:

```text
7 runs, 180 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
bin/rails test test/services/offerings/setup_field_catalog_test.rb test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
23 runs, 298 assertions, 0 failures, 0 errors, 0 skips
```

## Skipped Checks

- Full Rails suite was not run; this was a focused local rehearsal around the accepted offering setup/admin apply lane.
- Browser/manual click-through was not run. The rehearsal used durable request-level integration coverage of the admin routes instead.

## Boundary Confirmation

- Rails: test coverage touched.
- Vue: not touched.
- Expo: not touched.
- Admin: touched through integration test coverage.
- Temple data: test database only.
- Payment: not touched.
- Accounting: not touched.
- Public site/runtime published offering config: not touched.

## Deployment And Production Impact

- No deployment performed.
- No server config changed.
- No secrets accessed or changed.
- No payment provider config changed.
- No production data touched.
- No migration added.

## YAML Writes

Avoided. No YAML files changed.

## Draft-Only Apply

Verified. Each applied target remained a `TempleService` with `status: "draft"`.

## Event Apply

Not implemented. Event apply remains blocked by the existing apply path.

## Residual Risk

- This is automated request-level rehearsal, not a human browser usability pass.
- Catalog labels/hints remain code-backed.
- Registration intake authoring remains future work.
- Event setup/apply remains future work.

## Product Gaps Found

No blocking product gap found in the three required service setup examples.

## Next Owner

Coordinator should accept the rehearsal if the evidence is sufficient, then commit the workflow checkpoint. After that, the next product iteration can be registration intake authoring or a browser/manual UI review pass.
