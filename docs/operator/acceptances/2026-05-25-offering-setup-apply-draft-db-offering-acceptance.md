# Acceptance: Apply Reviewed Offering Setup To Draft DB Offering

Acceptance id: `shengfukung-2026-05-25-offering-setup-apply-draft-db-offering-acceptance`

Created: 2026-05-25

Reviewer: Shengfukung Wenfu coordinator thread

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-apply-draft-db-offering.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-apply-draft-db-offering-return.md`

Related prior acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md`

Related execution record: not created yet

## Decision

retry_required

## Decision Reason

The implementation is close and the main controller path uses `Offerings::SetupDraftApplier`, but there is a blocking bypass path:

`TempleOfferingSetupDraft#apply!` still directly marks a setup draft `applied` without:

- validating supported setup fields;
- creating or updating a draft `TempleService`;
- linking `applied_offering`;
- checking slug collisions;
- blocking event-kind apply.

The model test still asserts this old behavior:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/models/temple_offering_setup_draft_test.rb`

That conflicts with the handoff goal:

```text
reviewed offering setup draft -> validated supported schema -> draft DB offering
```

The apply concept should have one safe path. Leaving a public model method named `apply!` that skips the new applier is likely to cause future code or tests to bypass the review/apply guarantees.

## Positive Findings

The new `Offerings::SetupDraftApplier` mostly matches the intended behavior:

- validates supported admin fields;
- validates option-bearing fields;
- blocks event apply;
- blocks unrelated service slug collisions;
- creates draft `TempleService` records;
- records the applied target;
- keeps YAML write-free;
- keeps services draft-only.

## Mode Reviewed

prototype

## Verification Reviewed

Ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
17 runs, 136 assertions, 0 failures, 0 errors, 0 skips
```

Tests pass, but they also preserve the unsafe `apply!` behavior, so the pass is not sufficient for acceptance.

## Branch/Worktree Reviewed

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Latest commit reviewed: `b061592 Apply reviewed setup drafts to draft services`

Observed git status after coordinator verification:

```text
## offering-setup-admin-workflow
 M ops/docs/commands.md
?? docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-acceptance.md
?? docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md
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
- YAML writes: avoided in the new applier path.
- Published/live offerings: not touched by the new applier path.
- Deployment/server/secrets/production data: not touched.

## Required Retry

Implementation thread should make one focused corrective pass:

1. Remove the unsafe `TempleOfferingSetupDraft#apply!` method, make it private/unavailable, or change it to delegate to the same safe applier behavior.
2. Update model tests so they no longer assert that `apply!` marks a draft applied without creating/linking a draft offering.
3. Add or update tests proving every supported apply entry point validates schema, creates/links a draft service, and cannot mark applied without an applied target.
4. Keep the existing controller applier behavior and focused tests passing.
5. Return updated evidence in the same return file or a new retry return under `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`.

## Accepted Gaps

Not accepted yet because of the bypass.

Expected acceptable gaps after retry:

- event apply remains blocked;
- richer registration form authoring remains future work;
- full Rails suite and browser/manual UI pass may remain skipped with reasons;
- reviewer role split can remain deferred.

## Rejected Items

Unsafe direct `apply!` behavior that bypasses the applier.

## Friction To Record

No separate friction record yet. This is a normal retry issue around stale API surface.

## Next Owner

Implementation thread should retry the apply API cleanup and return updated evidence.

## Meeting Needed

No.

## Docs Update Needed

No.

## Promotion Allowed

No.
