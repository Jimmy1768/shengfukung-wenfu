# Acceptance: Offering Setup Supported Field Catalog Retry

Acceptance id: `shengfukung-2026-05-25-offering-setup-supported-field-catalog-retry-acceptance`

Created: 2026-05-25

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-supported-field-catalog.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-supported-field-catalog-return.md`

Related prior acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-supported-field-catalog-acceptance.md`

Related execution record: not created yet

## Decision

accepted_with_gaps

## Decision Reason

The retry addresses the blocking option-preservation issues from the prior acceptance.

Accepted retry behavior:

- existing option lists longer than three rows are rendered and preserved on edit/save;
- the form adds blank rows for new option entries without truncating existing rows;
- unsupported legacy option field keys are visible as saved unsupported choices and remain preserved until changed;
- malformed legacy option text rows are ignored safely instead of crashing the request;
- unsupported option targets still block apply through the applier validation path;
- YAML writes remain avoided;
- applied offerings remain draft-only;
- event apply remains blocked.

The prototype now satisfies the handoff objective of replacing raw setup field entry with a staff-friendly supported field catalog while preserving old prototype draft data.

## Retry Findings Reviewed

### Resolved: Existing option entries beyond three can be silently dropped

Resolved by rendering `option_entries.size + 3` rows, with a minimum of three rows:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/_form.html.erb`

Coverage added in:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/offering_setup_drafts_test.rb`

### Resolved: Unsupported legacy option targets are not preserved as visible blockers

Resolved by adding unsupported saved option field keys to the option field choices and preserving them through update. Apply still fails visibly when those unsupported targets reach applier validation.

Coverage added in:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/offering_setup_drafts_test.rb`

### Resolved: Legacy option text parsing can crash on malformed rows

Resolved by changing `option_lines_from` to skip incomplete legacy rows before building option hashes:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offering_setup_drafts_controller.rb`

## Mode Reviewed

prototype

## Verification Reviewed

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/services/offerings/setup_field_catalog_test.rb test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
22 runs, 183 assertions, 0 failures, 0 errors, 0 skips
```

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit reviewed: `fe16645 Preserve setup option rows`

Reviewed catalog commits:

- `fd7f26d Add offering setup field catalog`
- `fe16645 Preserve setup option rows`

Observed git status before this acceptance record was added:

```text
## offering-setup-admin-workflow
 M ops/docs/commands.md
?? docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-supported-field-catalog-acceptance.md
?? docs/operator/handoffs/2026-05-25-offering-setup-admin-workflow.md
?? docs/operator/handoffs/2026-05-25-offering-setup-apply-draft-db-offering.md
?? docs/operator/handoffs/2026-05-25-offering-setup-supported-field-catalog.md
?? docs/operator/returns/2026-05-25-offering-setup-admin-workflow-return.md
?? docs/operator/returns/2026-05-25-offering-setup-apply-draft-db-offering-return.md
?? docs/operator/returns/2026-05-25-offering-setup-supported-field-catalog-return.md
```

`ops/docs/commands.md` remains an unrelated pre-existing unstaged change.

## Boundary Reviewed

- Rails/admin: touched by implementation.
- Vue: not touched.
- Expo: not touched.
- Payment/accounting: not touched.
- YAML writes: avoided.
- Published/live offerings: not touched; applied services remain `status: "draft"`.
- Deployment/server/secrets/production data: not touched.

## Accepted Gaps

- Catalog labels/hints may remain code-backed in prototype mode.
- The option editor is simple and row-based, not a full dynamic form builder.
- Full registration intake authoring remains future work.
- Event apply remains blocked.
- Full Rails suite was not run.
- Browser/manual UI pass was not run.
- Reviewer role split remains deferred; existing `manage_offerings` is used.

These gaps are acceptable for the prototype objective.

## Rejected Items

None after retry.

## Required Retry

None for this prototype objective.

## Friction To Record

No separate friction record required.

## Next Owner

Coordinator/product owner should decide the next product iteration:

- manual admin/browser UI review of the setup draft flow;
- expand registration intake authoring;
- add safe event setup fields and event apply;
- or prepare the branch for staging/manual review.

## Meeting Needed

No.

## Docs Update Needed

No immediate docs update required.

## Promotion Allowed

No production promotion. Prototype acceptance only.
