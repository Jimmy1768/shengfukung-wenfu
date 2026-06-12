# Return: Offering Setup Registration Intake Authoring

Handoff id: `shengfukung-2026-06-12-offering-setup-registration-intake-authoring`

Created: 2026-06-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Objective

Let admin offering setup drafts choose supported customer-facing registration intake fields, grouped by the existing registration schema sections, then apply those choices into draft `TempleService.metadata["registration_form"]`.

## Completed Work

- Added registration intake field metadata to `Offerings::SetupFieldCatalog`.
- Added grouped registration field choices for `order`, `contact`, `logistics`, and `ritual_metadata`.
- Added conservative default registration fields for old setup drafts without `setup_payload["registration_fields"]`.
- Added registration intake checkboxes to the setup draft form.
- Persisted selected registration fields under `setup_payload["registration_fields"]`.
- Included selected registration fields in the generated setup preview.
- Updated `Offerings::SetupDraftApplier` to validate selected registration field section/key pairs.
- Applied selected registration fields into `TempleService.metadata["registration_form"]["sections"]`.
- Kept order defaults sane with `quantity: 1`.
- Added focused tests for catalog metadata, create/update persistence, generated preview, selected apply metadata, default compatibility, unsupported registration field blocking, and the prior three-example rehearsal.

## Branch

- Branch role: continuing implementation branch.
- Branch name: `offering-setup-admin-workflow`.

## Latest Commit At Return Creation

- `f276024 Add offering setup admin rehearsal`

The registration intake authoring work was not committed at return creation time.

## State At Return Creation

- Staged: none.
- Unstaged:
  - `rails/app/controllers/admin/offering_setup_drafts_controller.rb`
  - `rails/app/models/temple_offering_setup_draft.rb`
  - `rails/app/services/offerings/setup_draft_applier.rb`
  - `rails/app/services/offerings/setup_field_catalog.rb`
  - `rails/app/views/admin/offering_setup_drafts/_form.html.erb`
  - `rails/config/locales/admin.en.yml`
  - `rails/config/locales/admin.zh-TW.yml`
  - `rails/test/integration/admin/offering_setup_drafts_test.rb`
  - `rails/test/models/temple_offering_setup_draft_test.rb`
  - `rails/test/services/offerings/setup_draft_applier_test.rb`
  - `rails/test/services/offerings/setup_field_catalog_test.rb`
- Untracked:
  - `docs/operator/handoffs/2026-06-12-offering-setup-registration-intake-authoring.md`
  - this return record
- Committed: not yet.
- Pushed: not pushed.
- Ahead/behind against `origin/offering-setup-admin-workflow`: `0 behind, 1 ahead` before this commit, from the prior local rehearsal checkpoint.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-offering-setup-registration-intake-authoring.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-offering-setup-registration-intake-authoring-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offering_setup_drafts_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/temple_offering_setup_draft.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/offerings/setup_draft_applier.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/offerings/setup_field_catalog.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/_form.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/offering_setup_drafts_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/models/temple_offering_setup_draft_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/offerings/setup_draft_applier_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/offerings/setup_field_catalog_test.rb`

## Verification

Command:

```bash
bin/rails test test/services/offerings/setup_field_catalog_test.rb test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
28 runs, 345 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
bin/rails test test/integration/admin/offering_orders_registrant_flow_test.rb
```

Result:

```text
7 runs, 47 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

## Skipped Checks

- Full Rails suite was not run; focused setup/applier/catalog/admin order coverage was run.
- Browser/manual UI pass was not run.

## Boundary Confirmation

- Rails: touched.
- Vue: not touched.
- Expo: not touched.
- Admin: touched; setup draft form now includes registration intake field choices.
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

Preserved. Apply still creates or updates draft `TempleService` records.

## Event Apply

Not implemented. Event apply remains blocked.

## Residual Risk

- Browser/manual usability of the larger setup form was not checked.
- Catalog labels/hints remain code-backed.
- Field-specific options for registration intake fields remain future work.
- Event setup/apply remains future work.

## Product Gaps Found

No blocking gap found for prototype registration intake authoring.

## Next Owner

Coordinator should accept the prototype if the evidence is sufficient, create the execution record, and commit the checkpoint. Next product work can proceed to browser/manual UI review or safe event setup/apply.
