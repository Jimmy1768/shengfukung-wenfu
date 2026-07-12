# Handoff: Assisted Onboarding and ECPay Gap Policy Retry

```yaml
handoff:
  handoff_id: shengfukung-2026-07-12-assisted-onboarding-ecpay-gap-policy-retry
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  objective: >-
    Resolve the single manual-YAML wording contradiction while preserving the
    accepted assisted-onboarding and ECPay gap policy.
  accepted_design_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-assisted-onboarding-ecpay-gap-policy-retry.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-12-assisted-onboarding-ecpay-gap-decision.md
  readiness_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-assisted-onboarding-ecpay-gap-policy-return.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: 1351ab6cf475f79a6f2f2caff347879ceb25da66
    status_sha256: eb63f7cbc8196c1a1237c03e70441c6149527e2efa16518cd44bcf6918de88f7
    verified_at: 2026-07-12T17:11:01+08:00
  owned_files_or_surfaces:
    - docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md
    - docs/operator/returns/2026-07-12-assisted-onboarding-ecpay-gap-policy-return.md
  required_behavior:
    - Change only the ambiguous V1 wording so temple staff are not required to edit YAML.
    - Preserve manual operator-side intake-to-YAML configuration as an accepted service step.
    - Preserve all non-blocking gap, Expo, hiring, Guide, ECPay, production, provider, and secret boundaries.
    - Update the return to record this clarification and exact final changed paths for the combined job.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && rg -n "manual YAML|temple staff|operator-assisted|non-blocking|ECPay" docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md docs/operator/workflows/2026-07-12-assisted-onboarding-ecpay-gap-decision.md docs/operator/returns/2026-07-12-assisted-onboarding-ecpay-gap-policy-return.md
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - all paths not explicitly owned by this retry
    - product code, tests, Rails, Vue, Expo/mobile, ops, or plan changes
    - other repositories, live ECPay, secrets, provider state, production, or customer data
    - dependency installation or network access
    - git branch creation, switching, commit, merge, push, reset, restore, or clean
  codex_execution:
    requested_model: gpt-5.4-mini
    requested_reasoning: medium
    execution_profile: mechanical_docs_tests_fixtures
    selection_reason: single policy wording correction and terminology checks
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
    - requested_profile
    - changed_paths
    - checks
    - blockers
    - recommended_control_action
```

## Terminal Continuation Rule

Send the minimal terminal wake after all mutations and checks, then write the
authoritative return and stop the bounded job. Keep the Handoff bound and idle.
