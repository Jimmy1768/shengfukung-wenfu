# Wenfu Main Checkpoint Push Handoff

```yaml
handoff:
  handoff_id: wenfu-main-checkpoint-push-2026-07-11
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_control: Wenfu Control
  objective: Commit this push authorization record and push the complete accepted local main checkpoint to origin/main without rewriting remote history.
  accepted_design_refs:
    - /Users/jimmy1768/Projects/operator-kit/ops/docs/reference/codex_work_mode.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-11-repo-cleanup-integration-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-07-11-repo-cleanup-integration-execution.md
  readiness_refs:
    - local main commit bf7baf0bb26d975bcf50e5fd48b75c18558ddf5c
    - origin/main commit 5e5ad16f4f254109cf7cb0f33d0757c617f4de6c before fresh fetch
  owned_files_or_surfaces:
    - docs/operator/handoffs/2026-07-11-main-checkpoint-push.md
    - docs/operator/returns/2026-07-11-main-checkpoint-push-return.md
    - local main
    - origin/main fast-forward update
  implementation_scope:
    - Confirm main is clean except this untracked Handoff file.
    - Commit this Handoff on main with the declared commit subject.
    - Fetch origin without pruning or mutating remote refs.
    - Require fetched origin/main to be an ancestor of local main.
    - Require local main to contain accepted cleanup commit bf7baf0bb26d975bcf50e5fd48b75c18558ddf5c.
    - Push local main to origin/main as a normal fast-forward; never force-push.
    - Verify origin/main resolves to the pushed local commit after the push.
    - Write the exact push return, commit it on main, and push that return commit with a second normal fast-forward.
    - Verify local main and origin/main resolve to the same final commit and leave the worktree clean.
  blocked_surfaces:
    - force push, remote branch deletion, tags, and non-main remote refs
    - product/runtime code and CSS repair
    - deploy, restart, production/staging, secrets, billing, payments, and customer state
  required_checks:
    - git status --short --branch
    - git fetch origin
    - git merge-base --is-ancestor origin/main main
    - git merge-base --is-ancestor bf7baf0bb26d975bcf50e5fd48b75c18558ddf5c main
    - git diff --check
    - git push origin main:main
    - compare git rev-parse main and git rev-parse origin/main after each push
    - final git status --short --branch
  commit_required: true
  commit_message: Authorize Wenfu main checkpoint push
  codex_execution:
    profile_id: handoff_standard
    model: gpt-5.4
    reasoning: medium
  escalation_conditions:
    - starting dirty paths exist beyond this Handoff file
    - fetched origin/main is not an ancestor of local main
    - push requires force, lease override, conflict resolution, credentials repair, or remote policy changes
    - any requested action would touch a blocked surface
  return_shape:
    - status: complete | blocked
    - commits_created
    - pushed_ref
    - before_and_after_remote_commit
    - checks
    - final_git_status
    - blockers
```

## Authorization

The Director explicitly authorized pushing the accepted local `main` checkpoint
before beginning the separate `LumenHarbor.vue` repair. This authorization is
limited to normal fast-forward updates of `origin/main`.

## Return Location

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-11-main-checkpoint-push-return.md`

Return to Wenfu Control only. Do not dispatch another Handoff.
