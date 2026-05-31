# Execution Record: Apply Reviewed Offering Setup To Draft DB Offering

Execution id: `shengfukung-2026-05-25-offering-setup-apply-draft-db-offering-execution`

Record created: 2026-05-26

Execution date: 2026-05-25

Execution type: `agent_assisted`

Executor: Shengfukung Wenfu implementation thread

Executor type: `implementation_thread`

Authority level: repo-local implementation authority for Rails/admin prototype code, tests, and docs return only. No authority to deploy, change server config, rotate/access secrets, change payments, or touch production data.

Mode: prototype

Trigger/input: coordinator handoff to apply reviewed offering setup drafts into validated draft DB offerings.

Handoff packet: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-apply-draft-db-offering.md`

Execution return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-apply-draft-db-offering-return.md`

Acceptance record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-acceptance.md`

Related prior acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md`

Related later retry acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md`

Repo/path: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch/worktree state: branch `offering-setup-admin-workflow`; original apply-stage acceptance reviewed commit `b061592 Apply reviewed setup drafts to draft services`; observed coordinator status included unrelated unstaged `ops/docs/commands.md`, which was not touched by the implementation or acceptance.

## Actions Taken

- Added a durable polymorphic applied target link on `TempleOfferingSetupDraft`.
- Added `Offerings::SetupDraftApplier` to centralize the reviewed setup draft apply path.
- Validated supported setup field names before creating/updating draft DB offerings.
- Validated option attachment targets and blocked options for unsupported or non-option fields.
- Created draft `TempleService` records from reviewed service setup drafts.
- Recorded linked draft offering targets and audit metadata.
- Kept apply idempotent for already-applied drafts with linked targets.
- Blocked unrelated service slug collisions.
- Blocked event-kind apply until event scheduling fields are captured safely.
- Avoided YAML writes and publication.

## Files Read

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-05-25-offering-setup-apply-draft-db-offering.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-05-25-offering-setup-apply-draft-db-offering-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md`

## Files Changed

Apply implementation commit `b061592 Apply reviewed setup drafts to draft services` changed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offering_setup_drafts_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/temple_offering_setup_draft.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/offerings/setup_draft_applier.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/show.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.en.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/config/locales/admin.zh-TW.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/migrate/20260525000020_add_applied_offering_to_setup_drafts.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/schema.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/offering_setup_drafts_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/offerings/setup_draft_applier_test.rb`

This execution record was created as a docs-only queue backfill and did not change product code.

## Commands Run

Coordinator verification for the original apply-stage acceptance ran from `/Users/jimmy1768/Projects/shengfukung-wenfu/rails`:

```bash
bin/rails test test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Result:

```text
17 runs, 136 assertions, 0 failures, 0 errors, 0 skips
```

## External Services Called

None.

## Secrets Accessed

None.

## Verification Evidence

The focused Rails test command above passed, and the coordinator found the new `Offerings::SetupDraftApplier` mostly matched the intended behavior:

- supported admin fields were validated;
- option-bearing fields were validated;
- event apply was blocked;
- unrelated service slug collisions were blocked;
- draft `TempleService` records were created;
- applied targets were recorded;
- YAML writes were avoided;
- applied services remained draft-only.

However, the same review found a blocking bypass:

- public `TempleOfferingSetupDraft#apply!` still directly marked a setup draft `applied`;
- that bypass did not validate supported setup fields;
- it did not create or link a draft `TempleService`;
- it did not check slug collisions;
- it did not block event-kind apply.

## Skipped/Refused Actions

- Full Rails suite was not run.
- Browser/manual UI pass was not run.
- No deployment was performed.
- No server, secret, payment, or production-data action was performed.
- Existing unstaged `ops/docs/commands.md` was left untouched.

## Freeze Conditions Hit

None. Event-kind apply was explicitly blocked by the implementation path under review.

## Risk/Residual Gaps

Original apply-stage acceptance result was `retry_required`, not final prototype acceptance and not production readiness.

Blocking risk identified: a stale public model `apply!` API could bypass the new validating applier and mark drafts applied without creating/linking validated draft offerings.

This issue was later addressed by retry commit `2d1d6d4 Remove unsafe setup draft apply bypass` and accepted with gaps in:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md`

## Accepted By

Original decision reviewed by Shengfukung Wenfu coordinator thread.

## Result

`retry_required`

This record preserves the original failed apply-stage acceptance decision. It should not be treated as production acceptance or promotion approval. The later retry acceptance supersedes the unsafe bypass issue for this workflow stage.

## Next Owner

At the time of the original acceptance, the next owner was the implementation thread for one focused retry on removing or safely delegating the stale `TempleOfferingSetupDraft#apply!` bypass.

After the later retry acceptance, the next owner became coordinator/product owner for choosing the next product iteration.

## Rollback/Disable Path

Prototype branch only. If needed before promotion, revert or withhold the implementation commits and do not run the migration in production. No production deployment occurred in this execution.

## Reputation/Payment Eligibility

`not_applicable`
