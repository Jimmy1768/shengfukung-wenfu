# Execution Record: Apply Reviewed Offering Setup To Draft DB Offering Retry

Execution id: `shengfukung-2026-05-25-offering-setup-apply-draft-db-offering-retry-execution`

Record created: 2026-05-26

Execution date: 2026-05-25

Execution type: `agent_assisted`

Executor: Shengfukung Wenfu implementation thread

Executor type: `implementation_thread`

Authority level: repo-local implementation authority for Rails/admin prototype code, tests, and docs return only. No authority to deploy, change server config, rotate/access secrets, change payments, or touch production data.

Mode: prototype

Trigger/input: retry required by the original apply-stage coordinator acceptance because a public `TempleOfferingSetupDraft#apply!` bypass could mark setup drafts applied without the validating applier path.

Handoff packet: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-apply-draft-db-offering.md`

Execution return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-apply-draft-db-offering-return.md`

Acceptance record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md`

Related prior acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-acceptance.md`

Related prior execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-05-25-offering-setup-apply-draft-db-offering-execution.md`

Related admin workflow retry acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md`

Repo/path: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch/worktree state: branch `offering-setup-admin-workflow`; retry acceptance reviewed commit `2d1d6d4 Remove unsafe setup draft apply bypass` after apply implementation commit `b061592 Apply reviewed setup drafts to draft services`; observed coordinator status included unrelated unstaged `ops/docs/commands.md`, which was not touched by the implementation, retry, or acceptance.

## Actions Taken

- Removed the unsafe public `TempleOfferingSetupDraft#apply!` bypass.
- Kept the supported apply path routed through `Offerings::SetupDraftApplier` from the admin controller/service flow.
- Updated model coverage so stale direct model apply behavior is no longer asserted.
- Preserved the apply implementation that creates/links draft `TempleService` records from reviewed service setup drafts.
- Preserved validations for unsupported setup fields, unsupported option targets, unrelated slug collisions, and event-kind apply.
- Kept YAML writes avoided and applied offerings draft-only.

## Files Read

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-apply-draft-db-offering.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-apply-draft-db-offering-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-05-25-offering-setup-apply-draft-db-offering-execution.md`

## Files Changed

Retry fix commit `2d1d6d4 Remove unsafe setup draft apply bypass` changed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/temple_offering_setup_draft.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/models/temple_offering_setup_draft_test.rb`

The broader apply implementation was recorded in:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-05-25-offering-setup-apply-draft-db-offering-execution.md`

This execution record was created as a docs-only queue backfill and did not change product code.

## Commands Run

Coordinator verification for the retry acceptance ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
17 runs, 138 assertions, 0 failures, 0 errors, 0 skips
```

## External Services Called

None.

## Secrets Accessed

None.

## Verification Evidence

The retry acceptance found that the unsafe public model apply bypass was removed and the supported apply path now routes through `Offerings::SetupDraftApplier`.

Accepted prototype behavior:

- reviewed service setup drafts can be applied into draft `TempleService` records;
- unsupported setup fields block apply;
- unsupported option targets block apply;
- unrelated slug collisions block apply;
- event apply remains explicitly blocked;
- applied draft links to the created draft service;
- repeated apply does not create duplicate services;
- YAML writes are avoided;
- applied offerings remain draft-only.

## Skipped/Refused Actions

- Full Rails suite was not run.
- Browser/manual UI pass was not run.
- No deployment was performed.
- No server, secret, payment, or production-data action was performed.
- Existing unstaged `ops/docs/commands.md` was left untouched.

## Freeze Conditions Hit

None. Event-kind apply remained explicitly blocked.

## Risk/Residual Gaps

This was `accepted_with_gaps` for prototype mode only, not production acceptance.

Accepted gaps:

- event apply remains blocked until scheduling fields are captured and validated;
- registration form generation is conservative and uses a default order/contact shape;
- supported field vocabulary remains a future renderer/schema maintenance point;
- full Rails suite and browser/manual UI pass were not run;
- reviewer role split remains deferred and uses existing `manage_offerings`.

## Accepted By

Shengfukung Wenfu coordinator thread.

## Result

`accepted_with_gaps`

This record preserves the retry acceptance decision. It should not be treated as production acceptance or promotion approval.

## Next Owner

Coordinator/product owner should decide the next product iteration:

- improve staff-friendly field mapping;
- expand registration form authoring beyond the conservative default;
- add safe event setup fields and event apply;
- or prepare this branch for staging/manual UI review.

## Rollback/Disable Path

Prototype branch only. If needed before promotion, revert or withhold implementation commits and do not run the migration in production. No production deployment occurred in this execution.

## Reputation/Payment Eligibility

`not_applicable`
