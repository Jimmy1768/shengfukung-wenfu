# Acceptance: Offering Setup Registration Intake Authoring

Acceptance id: `shengfukung-2026-06-12-offering-setup-registration-intake-authoring-acceptance`

Created: 2026-06-12

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-offering-setup-registration-intake-authoring.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-offering-setup-registration-intake-authoring-return.md`

Related execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-offering-setup-registration-intake-authoring-execution.md`

## Decision

accepted_with_gaps

## Decision Reason

The prototype satisfies the handoff objective.

Accepted behavior:

- admin setup drafts can choose supported registration intake fields by schema section;
- selected fields persist separately from admin setup fields under `setup_payload["registration_fields"]`;
- old drafts without registration field selections keep the existing conservative default registration form;
- selected registration fields apply into `TempleService.metadata["registration_form"]["sections"]`;
- unsupported registration section/field pairs block apply without creating a service;
- order defaults retain `quantity: 1`;
- YAML writes are avoided;
- applied services remain draft-only;
- event apply remains blocked;
- no production, payment, server, secret, or deployment action occurred.

## Mode Reviewed

prototype

## Verification Reviewed

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/services/offerings/setup_field_catalog_test.rb test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
28 runs, 345 assertions, 0 failures, 0 errors, 0 skips
```

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/integration/admin/offering_orders_registrant_flow_test.rb
```

Result:

```text
7 runs, 47 assertions, 0 failures, 0 errors, 0 skips
```

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit before local registration-intake changes: `f276024 Add offering setup admin rehearsal`

Observed changed files before this acceptance record was added:

```text
 M rails/app/controllers/admin/offering_setup_drafts_controller.rb
 M rails/app/models/temple_offering_setup_draft.rb
 M rails/app/services/offerings/setup_draft_applier.rb
 M rails/app/services/offerings/setup_field_catalog.rb
 M rails/app/views/admin/offering_setup_drafts/_form.html.erb
 M rails/config/locales/admin.en.yml
 M rails/config/locales/admin.zh-TW.yml
 M rails/test/integration/admin/offering_setup_drafts_test.rb
 M rails/test/models/temple_offering_setup_draft_test.rb
 M rails/test/services/offerings/setup_draft_applier_test.rb
 M rails/test/services/offerings/setup_field_catalog_test.rb
?? docs/operator/handoffs/2026-06-12-offering-setup-registration-intake-authoring.md
?? docs/operator/returns/2026-06-12-offering-setup-registration-intake-authoring-return.md
```

## Boundary Reviewed

- Rails/admin: touched.
- Vue: not touched.
- Expo: not touched.
- Payment/accounting: not touched.
- YAML writes: avoided.
- Published/live offerings: not touched; applied services remain draft-only.
- Deployment/server/secrets/production data: not touched.

## Accepted Gaps

- Browser/manual UI review was not run.
- Full Rails suite was not run.
- Catalog labels/hints remain code-backed.
- Field-specific registration intake options remain future work.
- Event setup/apply remains future work.

These gaps are acceptable for this prototype objective.

## Rejected Items

None.

## Required Retry

None for this prototype objective.

## Friction To Record

No separate friction record required.

## Next Owner

Coordinator should create the execution record and commit the checkpoint. Next product work can proceed to browser/manual UI review or safe event setup/apply.

## Meeting Needed

No.

## Docs Update Needed

No.

## Promotion Allowed

No production promotion. Prototype acceptance only.
