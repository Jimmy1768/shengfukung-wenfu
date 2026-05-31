# Return: Offering Setup Admin Workflow

Handoff id: `shengfukung-2026-05-25-offering-setup-admin-workflow`

Created: 2026-05-25

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Objective

Build the first bounded admin-console workflow for temple offering setup intake, separate from live offering creation, with draft/submission/review/apply states and a generated YAML-shaped preview.

## Completed Work

- Added DB-backed `TempleOfferingSetupDraft` records scoped to a temple.
- Added admin routes/controller/views under `/admin/offering-setup`.
- Added create/edit/submit/review/apply workflow.
- Added generated YAML-shaped config preview based on draft setup data.
- Added audit logging for create/update/submit/review/apply actions.
- Linked the setup lane from the existing Offerings index while leaving live offering creation frozen.
- Kept apply conservative: it marks the reviewed setup as applied and records audit state, but does not create, publish, update, or write live offerings/YAML.
- Added model and integration coverage for generation, permissions, state flow, and non-mutation of live offerings.
- Retry fix: reviewed drafts are now locked from edit/update before apply, preventing stale reviewed content from being changed and applied without a fresh review.

## Branch

- Branch role: scoped implementation branch
- Branch name: `offering-setup-admin-workflow`

## Latest Commit

- `d0f7742 Lock reviewed offering setup drafts`

## State

- Staged: none at return creation time.
- Unstaged: `ops/docs/commands.md` remained modified and untouched.
- Untracked:
  - `docs/operator/handoffs/2026-05-25-offering-setup-admin-workflow.md` existed before implementation work and was left untouched.
  - this return record.
- Committed: implementation committed as `a613e80`; retry fix committed as `d0f7742`.
- Pushed: not pushed.
- Ahead/behind against `origin/main`: `0 behind, 3 ahead` at retry return update time. The branch includes existing local commit `8b25d09 Seed Shengfukung operator workflow docs`, implementation commit `a613e80`, and retry fix `d0f7742`.

## Files Changed In Implementation Commit

- `rails/app/controllers/admin/offering_setup_drafts_controller.rb`
- `rails/app/models/temple.rb`
- `rails/app/models/temple_offering_setup_draft.rb`
- `rails/app/views/admin/offering_setup_drafts/_form.html.erb`
- `rails/app/views/admin/offering_setup_drafts/edit.html.erb`
- `rails/app/views/admin/offering_setup_drafts/index.html.erb`
- `rails/app/views/admin/offering_setup_drafts/new.html.erb`
- `rails/app/views/admin/offering_setup_drafts/show.html.erb`
- `rails/app/views/admin/offerings/index.html.erb`
- `rails/config/locales/admin.en.yml`
- `rails/config/locales/admin.zh-TW.yml`
- `rails/config/routes.rb`
- `rails/db/migrate/20260525000019_create_temple_offering_setup_drafts.rb`
- `rails/db/schema.rb`
- `rails/test/integration/admin/offering_setup_drafts_test.rb`
- `rails/test/models/temple_offering_setup_draft_test.rb`

## Files Changed In Retry Fix Commit

- `rails/app/models/temple_offering_setup_draft.rb`
- `rails/test/integration/admin/offering_setup_drafts_test.rb`
- `rails/test/models/temple_offering_setup_draft_test.rb`

## Verification

Command:

```bash
bin/rails test test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
10 runs, 85 assertions, 0 failures, 0 errors, 0 skips
```

## Skipped Checks

- Full Rails test suite was not run; the change is scoped to the admin offering setup lane plus related offering audit/template parity paths.
- No browser/manual UI pass was run.

## Boundary Confirmation

- Rails: touched.
- Vue: not touched.
- Expo: not touched.
- Admin: touched; new admin offering setup workflow added.
- Temple data: new temple-scoped setup draft model/table added.
- Payment: not touched.
- Accounting: not touched.
- Public site/runtime live offering config: not touched.

## Deployment And Production Impact

- Requires Rails migration before production use: `20260525000019_create_temple_offering_setup_drafts.rb`.
- Does not change server config, secrets, payment provider config, OTA, or public-site deployment.
- Does not mutate production data by itself.

## `ops/docs/commands.md`

Left untouched. It remains an unstaged local modification outside this implementation.

## Residual Risk

- Generated template output is YAML-shaped and reviewable, but not yet wired to write existing YAML template files or create/update live `TempleService`/`TempleEvent` records.
- Field vocabulary is free-text in the prototype; future work should map staff-friendly labels to the supported registration/form schema fields.
- Review/apply permissions currently use `manage_offerings` for both temple-side creation and review/apply.

## Production Gaps

- No production deployment performed.
- No migration run outside local development/test context.
- No owner/reviewer role split beyond existing `manage_offerings`.

## Next Owner

Coordinator/product owner should review the prototype workflow and decide whether apply should remain copy-only, create draft DB offerings, or write reviewed config to the existing YAML/template pipeline.
