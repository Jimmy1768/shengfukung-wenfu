# Acceptance: Offering Setup Admin UI Rehearsal

Acceptance id: `shengfukung-2026-06-12-offering-setup-admin-ui-rehearsal-acceptance`

Created: 2026-06-12

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-offering-setup-admin-ui-rehearsal.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-offering-setup-admin-ui-rehearsal-return.md`

Related execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-offering-setup-admin-ui-rehearsal-execution.md`

## Decision

accepted_with_gaps

## Decision Reason

The local rehearsal satisfies the handoff objective for prototype mode.

Accepted behavior:

- three realistic service setup examples are covered through admin request routes;
- selected catalog fields persist;
- option lists longer than three entries persist;
- submit and review transitions work;
- reviewed drafts remain locked from edit/update before apply;
- apply creates draft `TempleService` targets;
- applied service metadata includes expected setup fields, options, form UI provenance, and default registration form metadata;
- YAML writes are avoided;
- event apply remains blocked;
- no production, payment, server, secret, or deployment action occurred.

## Mode Reviewed

prototype

## Verification Reviewed

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/integration/admin/offering_setup_drafts_test.rb
```

Result:

```text
7 runs, 180 assertions, 0 failures, 0 errors, 0 skips
```

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/services/offerings/setup_field_catalog_test.rb test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
23 runs, 298 assertions, 0 failures, 0 errors, 0 skips
```

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit before local rehearsal changes: `dde90d1 Standardize Redis support layer`

Observed changed files before this acceptance record was added:

```text
 M rails/test/integration/admin/offering_setup_drafts_test.rb
?? docs/operator/handoffs/2026-06-12-offering-setup-admin-ui-rehearsal.md
?? docs/operator/returns/2026-06-12-offering-setup-admin-ui-rehearsal-return.md
```

## Boundary Reviewed

- Rails/admin: touched through test coverage.
- Vue: not touched.
- Expo: not touched.
- Payment/accounting: not touched.
- YAML writes: avoided.
- Published/live offerings: not touched; applied services remain draft-only in test.
- Deployment/server/secrets/production data: not touched.

## Accepted Gaps

- Browser/manual click-through was not run.
- Full Rails suite was not run.
- Catalog labels/hints remain code-backed.
- Registration intake authoring remains future work.
- Event setup/apply remains future work.

These gaps are acceptable for this local prototype rehearsal.

## Rejected Items

None.

## Required Retry

None for this rehearsal objective.

## Friction To Record

No separate friction record required.

## Next Owner

Coordinator should create the execution record and commit the checkpoint. Next product work can proceed to registration intake authoring or a browser/manual UI review pass.

## Meeting Needed

No.

## Docs Update Needed

No.

## Promotion Allowed

No production promotion. Prototype/local rehearsal acceptance only.
