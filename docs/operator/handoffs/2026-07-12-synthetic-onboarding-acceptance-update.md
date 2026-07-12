# Handoff: Synthetic Onboarding Acceptance Update

```yaml
handoff:
  handoff_id: shengfukung-2026-07-12-synthetic-onboarding-acceptance-update
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  objective: >-
    Update V1 and product-direction documentation so synthetic end-to-end
    onboarding proof is sufficient, no real temple or external participant is
    required, and Shengfukung or a future marketing hire cannot block product
    progress.
  accepted_design_refs:
    - Owner direction in Wenfu Control on 2026-07-12
    - OperatorKit commit 5f011c4ed0a23aee7139a1a0d1fafd71f9fee425
    - OperatorKit commit 9854262d243285d1ab2331b3678e6e117ab973ef
  readiness_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/friction_records/2026-06-14-real-temple-admin-staff-rehearsal-awaiting-participant.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-14-real-temple-admin-staff-rehearsal-session.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: 48c75b090ec66d0c3cec9b7e114eeff091245811
    status_sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    verified_at: 2026-07-12T15:50:21+08:00
  owned_files_or_surfaces:
    - docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md
    - docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md
    - docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md
    - docs/operator/friction_records/2026-06-14-real-temple-admin-staff-rehearsal-awaiting-participant.md
    - docs/operator/handoffs/2026-06-14-real-temple-admin-staff-rehearsal-session.md
    - docs/operator/returns/2026-07-12-synthetic-onboarding-acceptance-update-return.md
  required_behavior:
    - Record that Shengfukung was the initial development temple but declined onboarding and is no longer a product-progress dependency.
    - Replace the real-temple/real-offering/real-participant V1 requirement with synthetic end-to-end onboarding proof.
    - State explicitly that no real temple, real offering, employee, marketing manager, or outside participant is required for this proof.
    - Define sufficient evidence as automated Rails coverage plus a complete local browser or equivalent end-to-end walkthrough using a synthetic temple and realistic fake offering.
    - Cover temple profile setup, offering draft/create, review/apply, registration, order, and payment-status behavior.
    - Permit owner-, Control-, Handoff-, or automated test-driven verification; do not introduce an independence or unfamiliar-user requirement.
    - Mark the old real-temple rehearsal packet and session handoff as superseded for V1 acceptance while preserving them as optional future market-validation references.
    - Resolve the awaiting-participant friction record by owner policy change; do not claim that a real rehearsal occurred.
    - Record the current sequence: amend criteria, polish account/admin pages, prove synthetic onboarding end-to-end, accept web onboarding, then begin Expo work.
    - Preserve the comprehensive help guide as a broader-rollout deliverable, but do not make it a prerequisite for starting Expo development.
    - Preserve production, payment-provider, secret, and production-data boundaries.
    - Write a durable return with exact changed paths and the resulting current blocker/next action.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && rg -n "real temple|real participant|synthetic|marketing manager|Expo|blocked|superseded" docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md docs/operator/friction_records/2026-06-14-real-temple-admin-staff-rehearsal-awaiting-participant.md docs/operator/handoffs/2026-06-14-real-temple-admin-staff-rehearsal-session.md
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - all files outside the explicitly owned docs
    - product code, tests, Rails, Vue, mobile, Expo, shared design-system, ops, nginx, or deployment changes
    - git branch creation or switching
    - git commit, merge, push, reset, restore, or clean
    - dependency installation or network access
    - production, staging, secrets, payment-provider, real ECPay, or customer-data actions
    - claiming that a real temple or staff rehearsal occurred
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

After all repository mutations and checks, send exactly one minimal wake payload
to Wenfu Control as the final tool action. Do not include return content in the
wake. Then write the authoritative structured return as the final output in the
Wenfu Handoff task and stop the job. The healthy Handoff remains bound and
returns to idle after Control review.
