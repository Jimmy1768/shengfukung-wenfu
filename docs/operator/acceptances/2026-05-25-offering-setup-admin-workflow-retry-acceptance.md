# Acceptance: Offering Setup Admin Workflow Retry

Acceptance id: `shengfukung-2026-05-25-offering-setup-admin-workflow-retry-acceptance`

Created: 2026-05-25

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-admin-workflow.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-admin-workflow-return.md`

Related prior acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-acceptance.md`

Related execution record: not created yet

## Decision

accepted_with_gaps

## Decision Reason

The retry fixed the blocking review/apply state-transition issue. Reviewed offering setup drafts are now locked from edit/update before apply, and focused tests cover the behavior.

The prototype meets the handoff objective for a bounded admin-console offering setup lane:

- setup drafts are DB-backed and temple-scoped;
- create/edit/submit/review/apply states exist;
- generated YAML-shaped output is reviewable;
- apply remains conservative and does not mutate live offerings/YAML;
- admin permission enforcement uses existing `manage_offerings`;
- the existing live offering creation freeze remains in place.

## Mode Reviewed

prototype

## Verification Reviewed

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
10 runs, 85 assertions, 0 failures, 0 errors, 0 skips
```

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit reviewed: `d0f7742 Lock reviewed offering setup drafts`

Reviewed commits:

- `a613e80 Add offering setup draft workflow`
- `d0f7742 Lock reviewed offering setup drafts`

Observed git status before this acceptance record was added:

```text
## offering-setup-admin-workflow
 M ops/docs/commands.md
?? docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-acceptance.md
?? docs/operator/handoffs/2026-05-25-offering-setup-admin-workflow.md
?? docs/operator/returns/2026-05-25-offering-setup-admin-workflow-return.md
```

`ops/docs/commands.md` remains an unrelated pre-existing unstaged change.

## Boundary Reviewed

- Rails/admin: touched.
- Vue: not touched.
- Expo: not touched.
- Payment/accounting: not touched.
- Runtime live offering config: not touched by apply.
- Deployment/server/secrets/production data: not touched.

## Accepted Gaps

- Generated template output is still a prototype preview and does not write existing YAML/template files.
- Apply does not yet create/update live `TempleService` or `TempleEvent` records.
- Field vocabulary remains free-text and needs future mapping to supported admin/registration schema fields.
- Review/apply permissions still use `manage_offerings`; a stricter owner/reviewer split can be designed later.
- Full Rails suite and browser/manual UI pass were not run.

These gaps are acceptable for prototype mode.

## Rejected Items

None.

## Required Retry

None for the current prototype objective.

## Friction To Record

No separate friction record required.

## Next Owner

Coordinator/product owner should decide the next stage:

- keep apply as copy/review-only;
- create draft DB offerings from accepted setup drafts;
- or generate/write reviewed config into the existing YAML/template pipeline.

## Meeting Needed

No.

## Docs Update Needed

No immediate docs update required.

## Promotion Allowed

No production promotion. Prototype acceptance only.
