# Acceptance: Offering Setup Admin Workflow

Acceptance id: `shengfukung-2026-05-25-offering-setup-admin-workflow-acceptance`

Created: 2026-05-25

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-admin-workflow.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-admin-workflow-return.md`

Related execution record: not created yet

## Decision

retry_required

## Decision Reason

The implementation substantially matches the requested prototype shape, but the review/apply boundary has a blocking state-transition gap.

`TempleOfferingSetupDraft#editable?` allows `reviewed` drafts to be edited. The controller update path allows those edits without changing status or clearing review metadata. The apply action only checks for `status == "reviewed"`, so a reviewed draft can be edited and then applied without a new review.

Relevant code:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/temple_offering_setup_draft.rb`
  - `editable?` includes `reviewed`.
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offering_setup_drafts_controller.rb`
  - `update` preserves reviewed state.
  - `apply` only checks reviewed state.

This violates the handoff requirement that the review/apply boundary be explicit and auditable.

## Mode Reviewed

prototype

## Verification Reviewed

Ran:

```bash
bin/rails test test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
9 runs, 76 assertions, 0 failures, 0 errors, 0 skips
```

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit reviewed: `a613e80 Add offering setup draft workflow`

Exact git status after coordinator verification:

```text
## offering-setup-admin-workflow
 M ops/docs/commands.md
?? docs/operator/handoffs/2026-05-25-offering-setup-admin-workflow.md
?? docs/operator/returns/2026-05-25-offering-setup-admin-workflow-return.md
```

`ops/docs/commands.md` remains an unrelated pre-existing unstaged change.

## Boundary Reviewed

- Rails/admin: touched.
- Vue: not touched.
- Expo: not touched.
- Payment/accounting: not touched.
- Runtime live offering config: apply path is conservative and does not mutate live offerings/YAML.
- Deployment/server/secrets/production data: not touched.

## Accepted Gaps

- Generated template output is a prototype preview and is not yet wired into the existing YAML/template pipeline.
- Field vocabulary remains free-text and will need mapping to supported form/schema fields in a later pass.
- Review/apply currently uses `manage_offerings`; a stronger reviewer role split can be deferred.

These gaps are acceptable for prototype mode only after the review/apply state-transition issue is fixed.

## Required Retry

Implementation thread should make one focused corrective pass:

1. Prevent post-review edits from being applied without a new review.
2. Choose one clear behavior:
   - reviewed drafts are no longer editable; or
   - editing a reviewed draft reverts it to `draft` or `submitted` and clears stale review/apply metadata.
3. Add model/integration coverage proving that a reviewed draft cannot be changed and then applied without a fresh review.
4. Return an updated OperatorKit return file under `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`.

## Rejected Items

No broad rejection. The prototype direction is correct; only the review/apply boundary needs retry.

## Friction To Record

No separate friction record yet. This is a normal first-pass state-machine gap, not repeated process friction.

## Next Owner

Implementation thread should retry the state-transition fix and return evidence.

## Meeting Needed

No.

## Docs Update Needed

No product docs update required before retry.

## Promotion Allowed

No.
