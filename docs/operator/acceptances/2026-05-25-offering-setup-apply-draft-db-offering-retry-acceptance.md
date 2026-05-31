# Acceptance: Apply Reviewed Offering Setup To Draft DB Offering Retry

Acceptance id: `shengfukung-2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance`

Created: 2026-05-25

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-apply-draft-db-offering.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-apply-draft-db-offering-return.md`

Related prior acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-acceptance.md`

Related execution record: not created yet

## Decision

accepted_with_gaps

## Decision Reason

The retry removed the unsafe public `TempleOfferingSetupDraft#apply!` bypass. The supported apply path now routes through `Offerings::SetupDraftApplier` from the admin controller/service flow.

The prototype now satisfies the handoff objective:

```text
reviewed offering setup draft -> validated supported schema -> draft DB offering
```

Accepted behavior:

- reviewed service setup drafts can be applied into draft `TempleService` records;
- unsupported setup fields block apply;
- unsupported option targets block apply;
- unrelated slug collisions block apply;
- event apply is explicitly blocked until event scheduling fields are captured safely;
- applied draft links to the created draft service;
- repeated apply does not create duplicate services;
- YAML writes are avoided;
- applied offerings remain draft-only.

## Mode Reviewed

prototype

## Verification Reviewed

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
17 runs, 138 assertions, 0 failures, 0 errors, 0 skips
```

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit reviewed: `2d1d6d4 Remove unsafe setup draft apply bypass`

Reviewed apply-stage commits:

- `b061592 Apply reviewed setup drafts to draft services`
- `2d1d6d4 Remove unsafe setup draft apply bypass`

Observed git status before this acceptance record was added:

```text
## offering-setup-admin-workflow
 M ops/docs/commands.md
?? docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-acceptance.md
?? docs/operator/handoffs/2026-05-25-offering-setup-admin-workflow.md
?? docs/operator/handoffs/2026-05-25-offering-setup-apply-draft-db-offering.md
?? docs/operator/returns/2026-05-25-offering-setup-admin-workflow-return.md
?? docs/operator/returns/2026-05-25-offering-setup-apply-draft-db-offering-return.md
```

`ops/docs/commands.md` remains an unrelated pre-existing unstaged change.

## Boundary Reviewed

- Rails/admin: touched.
- Vue: not touched.
- Expo: not touched.
- Payment/accounting: not touched.
- YAML writes: avoided.
- Published/live offerings: not touched; applied services remain `status: "draft"`.
- Deployment/server/secrets/production data: not touched.

## Accepted Gaps

- Event apply remains intentionally blocked until scheduling fields are captured and validated.
- Registration form generation is conservative and uses a default order/contact shape.
- Supported field vocabulary is centralized in `Offerings::SetupDraftApplier`; future renderer/schema expansion must keep it current.
- Full Rails suite was not run.
- Browser/manual UI pass was not run.
- Reviewer role split remains deferred; existing `manage_offerings` is used.

These gaps are acceptable for prototype mode.

## Rejected Items

None after retry.

## Required Retry

None for this prototype objective.

## Friction To Record

No separate friction record required.

## Next Owner

Coordinator/product owner should decide the next product iteration:

- improve staff-friendly field mapping;
- expand registration form authoring beyond the conservative default;
- add safe event setup fields and event apply;
- or prepare this branch for staging/manual UI review.

## Meeting Needed

No.

## Docs Update Needed

No immediate docs update required.

## Promotion Allowed

No production promotion. Prototype acceptance only.
