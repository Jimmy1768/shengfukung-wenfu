# Return: Apply Reviewed Offering Setup To Draft DB Offering

Handoff id: `shengfukung-2026-05-25-offering-setup-apply-draft-db-offering`

Created: 2026-05-25

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Objective

Make reviewed offering setup drafts useful by applying validated service setup data into draft `TempleService` records, while avoiding YAML writes, publication, deployment, payment/accounting changes, and production data changes.

## Completed Work

- Added a durable polymorphic applied target link on `TempleOfferingSetupDraft`:
  - `applied_offering_type`
  - `applied_offering_id`
- Added `Offerings::SetupDraftApplier` to centralize apply behavior.
- Apply now validates supported setup field names before creating/updating a DB offering.
- Apply validates option attachment targets and blocks options for unsupported/non-option fields.
- Apply creates a draft `TempleService` for reviewed service setup drafts.
- Applied service metadata follows existing template-backed conventions:
  - `metadata["offering_type"]`
  - `metadata["form_fields"]`
  - `metadata["form_defaults"]`
  - `metadata["form_options"]`
  - `metadata["form_ui"]`
  - `metadata["form_label"]`
  - `metadata["registration_form"]`
  - `metadata["allow_repeat_registrations"]`
- Apply records the linked draft offering target and logs the apply action with target metadata.
- Apply is idempotent for already-applied drafts with a linked target and does not create duplicates.
- Apply blocks unrelated service slug collisions.
- Event-kind apply is explicitly blocked until event scheduling fields are captured safely.
- Setup draft show UI now displays apply validation errors and linked draft offering targets.
- Retry fix: removed the unsafe public `TempleOfferingSetupDraft#apply!` bypass so the supported apply path is the validating applier/controller flow.

## Branch

- Branch role: continuing implementation branch
- Branch name: `offering-setup-admin-workflow`

## Latest Commit

- `2d1d6d4 Remove unsafe setup draft apply bypass`

## State

- Staged: none at return creation time.
- Unstaged: `ops/docs/commands.md` remained modified and untouched.
- Untracked:
  - acceptance/handoff docs already present in `docs/operator/...`
  - previous return file `docs/operator/returns/2026-05-25-offering-setup-admin-workflow-return.md`
  - this return record
- Committed: apply implementation committed as `b061592`; retry fix committed as `2d1d6d4`.
- Pushed: not pushed.
- Ahead/behind against `origin/main`: `0 behind, 5 ahead` at retry return update time.

## Files Changed In Latest Commit

- `rails/app/models/temple_offering_setup_draft.rb`
- `rails/test/models/temple_offering_setup_draft_test.rb`

## Files Changed In Apply Implementation Commit

- `rails/app/controllers/admin/offering_setup_drafts_controller.rb`
- `rails/app/models/temple_offering_setup_draft.rb`
- `rails/app/services/offerings/setup_draft_applier.rb`
- `rails/app/views/admin/offering_setup_drafts/show.html.erb`
- `rails/config/locales/admin.en.yml`
- `rails/config/locales/admin.zh-TW.yml`
- `rails/db/migrate/20260525000020_add_applied_offering_to_setup_drafts.rb`
- `rails/db/schema.rb`
- `rails/test/integration/admin/offering_setup_drafts_test.rb`
- `rails/test/services/offerings/setup_draft_applier_test.rb`

## Verification

Command:

```bash
bin/rails test test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
17 runs, 138 assertions, 0 failures, 0 errors, 0 skips
```

## Skipped Checks

- Full Rails test suite was not run; the changed behavior is covered by focused service/model/integration tests plus existing offering audit and template parity tests.
- No browser/manual UI pass was run.

## Boundary Confirmation

- Rails: touched.
- Vue: not touched.
- Expo: not touched.
- Admin: touched; apply workflow now creates/links draft services.
- Temple data: touched; new applied-offering link and draft `TempleService` creation path.
- Payment: not touched.
- Accounting: not touched.
- Public site/runtime published offering config: not touched; created offerings remain `status: "draft"`.

## Deployment And Production Impact

- Requires Rails migration before production use: `20260525000020_add_applied_offering_to_setup_drafts.rb`.
- Does not deploy, change server config, change secrets, change payment provider config, run OTA, or touch production data.

## YAML Writes

Avoided. Apply creates/updates draft DB services only and does not write YAML files.

## Draft-Only Guarantee

Applied services are created with `status: "draft"`. Apply does not publish offerings.

## `ops/docs/commands.md`

Left untouched. It remains an unstaged local modification outside this implementation.

## Residual Risk

- Event apply is intentionally blocked until event scheduling fields are captured and validated.
- Supported setup field vocabulary is centralized in `Offerings::SetupDraftApplier`; future renderer/schema expansion must update this list.
- Registration form generation is conservative and uses a default order/contact shape; richer registration form authoring remains future work.

## Production Gaps

- No production deployment performed.
- No production migration run.
- No reviewer role split beyond existing `manage_offerings`.

## Next Owner

Coordinator/product owner should review the service apply behavior, especially the supported field vocabulary, option format, and whether the conservative default registration form is sufficient for the next prototype round.
