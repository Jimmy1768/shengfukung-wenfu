# Acceptance: Offering Setup Supported Field Catalog

Acceptance id: `shengfukung-2026-05-25-offering-setup-supported-field-catalog-acceptance`

Created: 2026-05-25

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-supported-field-catalog.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-supported-field-catalog-return.md`

Related prior acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md`

Related execution record: not created yet

## Decision

retry_required

## Decision Reason

The field catalog direction is correct and the implementation passes the focused automated suite, but the current option editor does not satisfy the handoff's backward-compatibility requirement:

```text
preserve existing option entries or show them in a structured way.
```

The setup draft form renders exactly three option rows:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/_form.html.erb`

Saving the form posts only those rendered rows, and `selected_options` rebuilds `setup_payload["options"]` from submitted rows:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offering_setup_drafts_controller.rb`

That means an existing draft with more than three option entries can be truncated on a normal edit/save. This is not just a future richer-editor gap because existing Shengfukung offering data already has option lists longer than three, including `lamp_type` with four values and `blessing_target_type` lists with more than three values in:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/offerings/shengfukung-wenfu.yml`

The current behavior risks data loss and undermines the core product goal of making temple offering onboarding usable for real temple service lists.

## Findings

### P1: Existing option entries beyond three can be silently dropped

The form loops `3.times` for option rows, so `option_entries[3..]` are not rendered. On save, the controller reconstructs options only from submitted structured rows plus legacy text params, so the omitted existing entries are lost unless the user manually re-enters them somewhere else.

Relevant files:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/_form.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offering_setup_drafts_controller.rb`

Required retry:

- render all existing option entries, plus a small number of blank rows for new entries; or
- keep a visible/preserved legacy option textarea for entries not represented by structured rows; or
- otherwise guarantee that saving an existing draft does not drop unrendered options.

Add a test that creates/edits a draft with at least four options and proves all options survive an update.

### P1: Unsupported legacy option targets are not preserved as visible blockers

Unsupported existing field requirements are preserved in a visible textarea, but unsupported option field keys do not get the same treatment. If an existing option entry targets a field not in `SetupFieldCatalog.option_bearing_keys`, the select cannot faithfully show that unsupported key. A subsequent save can drop or misrepresent that option instead of preserving it as a visible apply blocker.

Required retry:

- show unsupported option targets explicitly, similar to unsupported field requirements; and
- preserve them unless the admin deliberately removes or remaps them.

Add a test for a legacy option entry whose `field` is unsupported, proving it remains visible and does not disappear on save.

### P2: Legacy option text parsing can crash on malformed rows

`option_lines_from` splits legacy rows as `field | label | value`, then falls back to `label.parameterize`. A malformed one-part legacy row leaves `label` nil and can raise `NoMethodError`.

Required retry:

- reject malformed legacy option lines with a validation-style error; or
- ignore incomplete lines safely; or
- normalize the legacy parser so it cannot crash the request.

This is lower priority than option preservation, but it is in the compatibility surface kept for old prototype drafts.

## Positive Findings

The main catalog implementation is aligned with the direction:

- `Offerings::SetupFieldCatalog` centralizes supported setup fields, labels, hints, groups, field kinds, and option-bearing metadata;
- `Offerings::SetupDraftApplier` validates supported fields and option-bearing targets through the catalog;
- the form now presents grouped staff-facing field choices instead of raw field-key typing for supported fields;
- unsupported legacy field requirements remain visible and continue to block unsafe apply;
- reviewed service drafts still apply only to draft `TempleService` records;
- event apply remains blocked;
- YAML writes remain avoided.

## Mode Reviewed

prototype

## Verification Reviewed

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/services/offerings/setup_field_catalog_test.rb test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
20 runs, 164 assertions, 0 failures, 0 errors, 0 skips
```

Tests pass, but they do not cover preserving more than three existing options or preserving unsupported legacy option targets.

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit reviewed: `fd7f26d Add offering setup field catalog`

Observed git status before this acceptance record was added:

```text
## offering-setup-admin-workflow
 M ops/docs/commands.md
?? docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md
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

Not accepted yet because of the option preservation issues.

Expected acceptable gaps after retry:

- catalog labels/hints may remain code-backed in prototype mode;
- full registration intake authoring may remain future work;
- event apply may remain blocked;
- full Rails suite and browser/manual UI pass may remain skipped with reasons.

## Rejected Items

- Fixed three-row option editor that can drop existing option data.
- Unsupported legacy option targets disappearing instead of remaining visible blockers.

## Required Retry

Implementation thread should make one focused corrective pass:

1. Preserve all existing option entries on edit/save, including option lists longer than three.
2. Make unsupported legacy option targets visible and preserved, or explicitly blocked without silent data loss.
3. Harden legacy option text parsing against malformed rows.
4. Add focused tests for four-plus option preservation and unsupported option target preservation.
5. Keep the focused catalog, applier, model, audit, and template parity tests passing.
6. Return updated evidence in the same return file or a retry return under `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`.

## Friction To Record

No separate friction record required. This is a normal prototype retry caused by option cardinality and legacy-data preservation.

## Next Owner

Implementation thread should retry the option editor preservation behavior and return updated evidence.

## Meeting Needed

No.

## Docs Update Needed

No immediate docs update required.

## Promotion Allowed

No.
