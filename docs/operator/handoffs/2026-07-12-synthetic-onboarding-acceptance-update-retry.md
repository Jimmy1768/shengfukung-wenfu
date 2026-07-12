# Handoff: Synthetic Onboarding Acceptance Update Retry

```yaml
handoff:
  handoff_id: shengfukung-2026-07-12-synthetic-onboarding-acceptance-update-retry
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  objective: >-
    Resolve the milestone wording conflict while preserving the owner-directed
    synthetic onboarding path and removal of external dependencies.
  accepted_design_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-synthetic-onboarding-acceptance-update-retry.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-synthetic-onboarding-acceptance-update.md
  readiness_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-synthetic-onboarding-acceptance-update-return.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: 2f663517b10d3387258a22e63680970b23e6c036
    status_sha256: 738b2788d73e7876f849570d6a640efa661b998a8e5f8695a0e2f9c8244d13ec
    verified_at: 2026-07-12T15:56:03+08:00
  owned_files_or_surfaces:
    - docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md
    - docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md
    - docs/operator/returns/2026-07-12-synthetic-onboarding-acceptance-update-return.md
  required_behavior:
    - Replace any claim that synthetic proof alone completes every V1 broader-rollout requirement.
    - State that synthetic proof satisfies the onboarding/rehearsal gate and is sufficient to accept the web onboarding flow.
    - State that accepted web onboarding unblocks Expo work.
    - Preserve the comprehensive help guide and its links as later broader-rollout deliverables, not prerequisites for Expo work.
    - Preserve that no real temple, real offering, employee, marketing manager, or outside participant is required for synthetic proof.
    - Preserve all production, payment-provider, secret, and production-data boundaries.
    - Update the durable return so its outcome and current next action use the same milestone language.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && rg -n "web onboarding|Expo|broader rollout|synthetic|real temple|marketing manager" docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md docs/operator/returns/2026-07-12-synthetic-onboarding-acceptance-update-return.md
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - all paths not explicitly owned by this retry
    - product code, tests, Rails, Vue, mobile, Expo, deployment, or operational changes
    - git branch creation or switching
    - git commit, merge, push, reset, restore, or clean
    - dependency installation or network access
    - production, staging, secrets, payment-provider, real ECPay, or customer-data actions
  codex_execution:
    profile_id: handoff
    model: gpt-5.4-mini
    reasoning: medium
    execution_surface: shared_checkout
    lifecycle: persistent_bound
  approval_policy:
    owned_by: Control
    handoff_must_return_on_approval: true
  follow_up:
    dispatch_mode: fire_and_forget
    primary_continuation_signal: explicit_terminal_wake_signal
    expected_runtime_class: small
    heartbeat_required: true
    heartbeat_delay_minutes: 3
    active_check_scope: task_status_only
    transcript_read_only_after_terminal_status: true
    terminal_wake_signal:
      tool: codex_app.send_message_to_thread
      receiver_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
      timing: final_tool_action_after_mutations_and_checks
      exactly_once: true
      authoritative_return: false
      payload:
        handoff_thread_id: 019f5519-0f72-7273-b50e-65739e5a2a36
        terminal_status: completed | blocked | failed
        instruction: read_handoff_terminal_return_once
      on_send_failure: finish_local_return_and_rely_on_fallback_heartbeat
      on_active_status_race:
        read_active_transcript: false
        status_only_recovery_delay_minutes: 1
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

## Terminal Continuation Rule

After all mutations and checks, send the minimal explicit wake as the final tool
action. Then write one authoritative structured return in the Handoff task and
stop the job. The healthy Handoff remains bound and reusable.
