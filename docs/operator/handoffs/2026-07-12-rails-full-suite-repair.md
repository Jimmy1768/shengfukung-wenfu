# Handoff: Rails Full-Suite Repair

```yaml
handoff:
  handoff_id: shengfukung-2026-07-12-rails-full-suite-repair
  owner_control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  objective: >-
    Diagnose and repair the current Rails full-suite failures so `bin/rails
    test` passes without weakening intended authorization, validation,
    localization, routing, or temple-event behavior.
  accepted_design_refs:
    - OperatorKit commit 4c29cf518e41f4aeaa60828a0efd0d2199afa351
    - OperatorKit commit b745b6a82be373ed5d4d855e4a0e107c0be23acb
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md
  readiness_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-11-repo-cleanup-integration-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-11-lumenharbor-css-warning-repair-acceptance.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: 4b1c6396985697bfa876f3d821bb5dac964de3cf
    status_sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    verified_at: 2026-07-12T15:09:32+08:00
  owned_files_or_surfaces:
    - rails/app/**
    - rails/config/**
    - rails/test/**
    - docs/operator/returns/2026-07-12-rails-full-suite-repair-return.md
  required_behavior:
    - Re-run the full Rails suite first and classify every failure/error by root cause.
    - Repair production code when behavior is wrong; repair tests only when assertions or setup are stale.
    - Preserve authorization boundaries; do not make unauthorized admin endpoints return success merely to satisfy tests.
    - Preserve Traditional Chinese as a supported/default product locale while making validation tests locale-explicit or supplying correct locale data as appropriate.
    - Preserve the `temple_events.starts_on` database invariant; make test setup create valid records rather than weakening the constraint unless repository evidence proves the invariant itself is wrong.
    - Restore or correctly update account API route-helper coverage based on the intended current routes.
    - Keep the repair bounded to failures reproducible from the current full suite.
    - Write a durable return file with root-cause groups, changed paths, exact checks, residual gaps, and recommended Control action.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - git branch creation or switching
    - git commit, merge, push, reset, restore, or clean
    - dependency installation or network access
    - database migrations or schema changes unless returned blocked with evidence that they are unavoidable
    - Vue, mobile/Expo, shared design-system, ops, nginx, deployment, or server changes
    - production, staging, secrets, payment-provider, real ECPay, or customer-data actions
    - V1 acceptance, production-readiness, deployment, or promotion decisions
    - files under docs/operator other than the named return file
  codex_execution:
    profile_id: handoff
    model: gpt-5.4-mini
    reasoning: medium
    execution_surface: shared_checkout
    lifecycle: persistent_disposable
  approval_policy:
    owned_by: Control
    handoff_must_return_on_approval: true
  follow_up:
    dispatch_mode: fire_and_forget
    sole_continuation_signal: heartbeat_wakeup
    expected_runtime_class: normal
    heartbeat_required: true
    heartbeat_delay_minutes: 10
    active_check_scope: task_status_only
    transcript_read_only_after_terminal_status: true
    terminal_return:
      location: handoff_thread
      delivery_to_control: false
      cross_thread_send_required: false
      exactly_once: true
      submission_id_allowed: false
      stop_after_return: true
  return_shape:
    - status
    - checkout_observed
    - changed_paths
    - checks
    - blockers
    - recommended_control_action
```

## Observed Baseline

On 2026-07-12, Wenfu Control ran `bin/rails test` from `rails/` and observed:

- `310 runs, 1703 assertions, 15 failures, 10 errors, 0 skips`;
- validation-message assertions resolving to missing `zh-TW` translations;
- test-created `TempleEvent` rows violating the non-null `starts_on` constraint;
- missing account API route helpers for certificates, registrations, and guest lists;
- an admin patron-picker authorization expectation mismatch;
- an admin registration-entry localization/content expectation mismatch.

The Vue production build passed, `git diff --check` passed, and the checkout was
clean before this packet was created.

## Terminal Return Rule

Write exactly one terminal return as the final output in the Wenfu Handoff task,
then stop. Do not send it to Wenfu Control and do not claim cross-task delivery.
Heartbeat is the sole wakeup path.
