# Return: Offering Setup Supported Field Catalog

Handoff id: `shengfukung-2026-05-25-offering-setup-supported-field-catalog`

Created: 2026-05-25

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Objective

Replace raw free-text runtime field entry in the offering setup workflow with a staff-friendly supported field catalog while preserving safe apply behavior and backward compatibility for existing prototype drafts.

## Completed Work

- Added `Offerings::SetupFieldCatalog` as the shared source of truth for supported offering setup fields.
- Catalog entries include internal key, staff-facing label, hint, group, field kind, and option-bearing metadata.
- Catalog distinguishes admin setup fields from `Registrations::FormSchema` registration fields.
- Updated `Offerings::SetupDraftApplier` to validate supported fields and option-bearing fields through the catalog instead of local constants.
- Replaced raw field-key textarea with grouped catalog checkboxes in the setup draft form.
- Added structured option inputs that attach options to explicit option-bearing fields.
- Preserved unsupported legacy field keys in a visible textarea so old prototype drafts remain inspectable and still block apply.
- Preserved legacy text parsing for old-style field/options payload submission.
- Updated tests for catalog metadata, form persistence, structured options, legacy display, and existing apply behavior.
- Retry fix: option editor now renders every existing option entry plus blank rows, so saving does not truncate option lists longer than three.
- Retry fix: unsupported legacy option targets are visible as unsupported saved field choices and remain preserved until explicitly changed.
- Retry fix: malformed legacy option text rows are ignored safely instead of crashing the request.

## Branch

- Branch role: continuing implementation branch
- Branch name: `offering-setup-admin-workflow`

## Latest Commit

- `fe16645 Preserve setup option rows`

## State

- Staged: none at return creation time.
- Unstaged: `ops/docs/commands.md` remained modified and untouched.
- Untracked:
  - acceptance/handoff docs already present in `docs/operator/...`
  - prior return files in `docs/operator/returns/`
  - this return record
- Committed: field catalog implementation committed as `fd7f26d`; retry fix committed as `fe16645`.
- Pushed: not pushed.
- Ahead/behind against `origin/main`: `0 behind, 7 ahead` at retry return update time.

## Files Changed In Latest Commit

- `rails/app/controllers/admin/offering_setup_drafts_controller.rb`
- `rails/app/views/admin/offering_setup_drafts/_form.html.erb`
- `rails/config/locales/admin.en.yml`
- `rails/config/locales/admin.zh-TW.yml`
- `rails/test/integration/admin/offering_setup_drafts_test.rb`

## Files Changed In Catalog Commit

- `rails/app/controllers/admin/offering_setup_drafts_controller.rb`
- `rails/app/services/offerings/setup_draft_applier.rb`
- `rails/app/services/offerings/setup_field_catalog.rb`
- `rails/app/views/admin/offering_setup_drafts/_form.html.erb`
- `rails/config/locales/admin.en.yml`
- `rails/config/locales/admin.zh-TW.yml`
- `rails/test/integration/admin/offering_setup_drafts_test.rb`
- `rails/test/services/offerings/setup_field_catalog_test.rb`

## Verification

Command:

```bash
bin/rails test test/services/offerings/setup_field_catalog_test.rb test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
22 runs, 183 assertions, 0 failures, 0 errors, 0 skips
```

## Skipped Checks

- Full Rails test suite was not run; focused service/model/integration coverage was run for the touched catalog, setup form, apply, audit, and template parity paths.
- Manual/browser UI check was not run.

## Boundary Confirmation

- Rails: touched.
- Vue: not touched.
- Expo: not touched.
- Admin: touched; setup draft form now uses catalog controls.
- Temple data: not structurally changed in this pass.
- Payment: not touched.
- Accounting: not touched.
- Public site/runtime published offering config: not touched.

## Deployment And Production Impact

- No new migration in this pass.
- Does not deploy, change server config, change secrets, change payment provider config, run OTA, or touch production data.

## YAML Writes

Avoided. YAML remains preview/export style only.

## Draft-Only Guarantee

Preserved from the apply stage. Applied offerings remain draft-only.

## Event Apply

Event apply remains blocked. This pass did not implement event scheduling capture.

## `ops/docs/commands.md`

Left untouched. It remains an unstaged local modification outside this implementation.

## Residual Risk

- Catalog labels/hints are currently coded in the catalog service rather than locale-backed translations.
- Structured option UI is still simple, but it preserves all existing option rows and adds blank rows for new entries.
- Registration intake authoring remains a future gap; the catalog only exposes registration field distinction for now.

## Production Gaps

- No production deployment performed.
- No production migration or data migration run.
- No reviewer role split beyond existing `manage_offerings`.

## Next Owner

Coordinator/product owner should review whether the initial catalog field set and option UI are usable enough for temple staff before expanding registration intake authoring or event apply.
