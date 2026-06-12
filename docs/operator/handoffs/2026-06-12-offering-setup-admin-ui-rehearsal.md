# Handoff: Offering Setup Admin UI Rehearsal

Handoff id: `shengfukung-2026-06-12-offering-setup-admin-ui-rehearsal`

Created: 2026-06-12

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: prototype

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Run a local admin UI rehearsal of the offering setup workflow using realistic Shengfukung-style service examples.

The purpose is to verify whether the current admin setup lane is usable enough to support temple onboarding before expanding registration intake authoring, event apply, staging, or production readiness.

## Context

The accepted prototype chain includes:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-supported-field-catalog-retry-acceptance.md`

Current accepted behavior:

- setup drafts are DB-backed and temple-scoped;
- reviewed service drafts apply into draft `TempleService` records;
- supported setup fields and option-bearing metadata are centralized in `Offerings::SetupFieldCatalog`;
- option lists longer than three rows are preserved;
- unsupported legacy option targets remain visible blockers;
- YAML writes are avoided;
- applied offerings remain draft-only;
- event apply remains blocked.

## Required Rehearsal

Run a local-only admin flow rehearsal for at least three representative service setup examples:

1. light/lamp service with multiple `lamp_type` options;
2. blessing service with multiple `blessing_target_type` options;
3. table/food service using `table_size` and `table_items`.

For each example, verify through the admin setup flow that:

- draft creation succeeds;
- selected catalog fields persist;
- option entries persist, including lists longer than three rows where relevant;
- submit and review transitions work;
- reviewed drafts are locked from edit/update;
- apply creates or links a draft `TempleService`;
- resulting draft service metadata includes useful `form_fields`, `form_options`, `form_ui`, and default registration form metadata;
- no YAML files are written.

Use automated integration/service tests as the rehearsal mechanism if that gives more durable evidence than manual clicking. Browser/manual UI may be skipped only if covered by focused request/integration tests and recorded as skipped.

## Non-Goals

- Do not deploy.
- Do not change server config.
- Do not rotate or access secrets.
- Do not touch payment provider configuration.
- Do not touch production data.
- Do not publish offerings.
- Do not write YAML files from admin.
- Do not implement registration intake authoring.
- Do not implement event apply.
- Do not redesign accounting.
- Do not move existing `ops/docs/` history.

## Stop Conditions

Stop and return `retry_required` evidence if the rehearsal exposes:

- data loss in draft setup payload or applied service metadata;
- a reviewed draft that can be edited and applied without fresh review;
- apply creating published/live offerings;
- YAML writes;
- missing catalog fields needed for the three required examples;
- broken tests that cannot be fixed within this bounded QA/rehearsal scope.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

The return must include:

- objective;
- examples rehearsed;
- implementation or test changes made, if any;
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
