# Handoff: Offering Setup Registration Intake Authoring

Handoff id: `shengfukung-2026-06-12-offering-setup-registration-intake-authoring`

Created: 2026-06-12

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: prototype

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Let admin offering setup drafts choose supported customer-facing registration intake fields, grouped by the existing registration schema sections, then apply those choices into draft `TempleService.metadata["registration_form"]`.

This follows the accepted local admin rehearsal:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-offering-setup-admin-ui-rehearsal-acceptance.md`

## Product Decision

Registration intake authoring should come before event apply or staging prep.

Reason:

- the admin setup lane can already create reviewed setup drafts and draft services;
- the remaining onboarding gap is that temple staff cannot choose what customers/staff must collect during registration beyond the conservative default;
- event apply depends on richer scheduling/intake fields and should wait until the registration field selection shape is proven.

## Required Build

Add a small registration intake field selector to the offering setup draft workflow.

Use the existing supported vocabulary from:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/registrations/form_schema.rb`

Expected sections:

- `order`
- `contact`
- `logistics`
- `ritual_metadata`

Implementation should:

- expose supported registration fields in the setup draft form as staff-readable grouped choices;
- persist selected registration fields separately from admin setup fields, preferably under `setup_payload["registration_fields"]`;
- keep old setup drafts compatible by using the current conservative default registration form when no registration field selection exists;
- validate selected registration fields before apply;
- apply selected fields into `TempleService.metadata["registration_form"]["sections"]`;
- keep order defaults sane, including quantity default;
- keep YAML writes avoided;
- keep applied services `status: "draft"`;
- keep event apply blocked.

## Expected Coverage

Add or update focused tests proving:

- setup draft create/update persists selected registration fields;
- applied service metadata uses selected registration form sections;
- old drafts without `registration_fields` keep the existing conservative registration form;
- unsupported registration fields block apply without creating a service;
- the previous local rehearsal examples still pass.

Run the focused offering setup suite.

## Non-Goals

- Do not deploy.
- Do not change server config.
- Do not rotate or access secrets.
- Do not touch payment provider configuration.
- Do not touch production data.
- Do not publish offerings.
- Do not write YAML files from admin.
- Do not implement event apply.
- Do not redesign accounting.
- Do not build a full drag-and-drop form builder.
- Do not move existing `ops/docs/` history.

## Stop Conditions

Stop and return `retry_required` evidence if:

- selected registration fields cannot be preserved safely;
- old setup drafts lose their conservative default registration form;
- unsupported registration fields can apply into service metadata;
- apply creates published/live offerings;
- YAML files are written;
- event apply becomes enabled by accident;
- focused tests fail and cannot be fixed within this bounded scope.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- completed work;
- repo path;
- branch name;
- latest commit hash and subject if committed, or uncommitted state if not;
- staged, unstaged, untracked, committed, and pushed state;
- ahead/behind state if known;
- files changed;
- verification commands and pass/fail output;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation;
- payment/accounting/admin/temple boundary confirmation;
- deployment/server/secrets/production-data impact;
- YAML-write confirmation;
- draft-only apply confirmation;
- event apply confirmation;
- residual risk;
- product gaps found;
- next owner.

Do not paste the full return in chat when the file exists.
