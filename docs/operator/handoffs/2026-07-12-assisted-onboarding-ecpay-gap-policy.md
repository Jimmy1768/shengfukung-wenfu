# Handoff: Assisted Onboarding and ECPay Gap Policy

```yaml
handoff:
  handoff_id: shengfukung-2026-07-12-assisted-onboarding-ecpay-gap-policy
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  objective: >-
    Document the owner-approved assisted onboarding model and the two accepted,
    non-blocking external validation gaps: temple-specific offering intake and
    live ECPay merchant verification.
  accepted_design_refs:
    - Owner direction in Wenfu Control on 2026-07-12
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-13-ecpay-default-path-local-verification-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md
  readiness_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/payment_methods/show.html.erb
    - /Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/payment_methods_test.rb
    - /Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/payments_flow_test.rb
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: 551759d0bf8af758597fe6f206e777dcbf3f8287
    status_sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    verified_at: 2026-07-12T16:56:45+08:00
  owned_files_or_surfaces:
    - docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md
    - docs/operator/workflows/2026-06-13-production-boundary-decision.md
    - docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md
    - docs/operator/workflows/2026-07-12-assisted-onboarding-ecpay-gap-decision.md
    - docs/operator/returns/2026-07-12-assisted-onboarding-ecpay-gap-policy-return.md
  required_behavior:
    - Define onboarding as an operator-assisted business process, not unrestricted public temple-account creation.
    - Record that temple legitimacy and representative authorization require human approval and are business trust boundaries, not code defects.
    - Record that temple and owner/admin account creation/promotion flows were owner-tested and are not the remaining engineering gate.
    - Define the remaining offering proof narrowly as completed offering intake to temple-specific YAML/configuration to onboarding/apply script to working offering.
    - State that a realistic synthetic intake is sufficient; refusal by the initial testing temple to complete a form is not a bug or blocker.
    - State that one intake form per offering and manual translation into YAML are acceptable now because temple configurations are not standardized.
    - Record that an onboarding fee may cover verification, configuration, training, and launch support; it is a business model decision, not legitimacy proof.
    - Record that no live ECPay merchant account is available because the owner is not a temple, so real ECPay payment/refund/callback testing cannot currently occur.
    - Treat the existing local/stubbed ECPay checkout, return, webhook, status, and refund-related evidence as sufficient for current code acceptance, without claiming live ECPay production acceptance.
    - Record the owner-provided evidence that platform payment/refund behavior has been proven in Combatives and DojoMate as a reusable implementation reference, not as runtime proof for this repo.
    - Require any future cross-repository code reuse or contract comparison to route Control-to-Control and receive a separate implementation review.
    - Confirm the current admin payment-method page already explains ECPay setup and provides fields for Merchant ID, HashKey, and HashIV; no product-code change is authorized by this docs job.
    - Keep passwords, API keys, provider credentials, and other secrets out of offering intake forms, docs, examples, logs, and source control.
    - Reserve live ECPay merchant setup, callback reachability, and a minimal payment/refund smoke test for the first approved temple rollout with explicit human approval.
    - State explicitly that the two real gaps are accepted and non-blocking; neither blocks web onboarding acceptance, Expo work, or continued product development.
    - Record future Guide/bot assistance as optional support for intake and ECPay setup, not a prerequisite.
    - Preserve production, payment-provider, secret, and production-data boundaries.
    - Write a durable return with exact changed paths, checks, accepted gaps, and next action.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && rg -n "non-blocking|offering intake|YAML|ECPay|Combatives|DojoMate|Guide|onboarding fee|first approved temple|secret" docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md docs/operator/workflows/2026-06-13-production-boundary-decision.md docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md docs/operator/workflows/2026-07-12-assisted-onboarding-ecpay-gap-decision.md
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - all paths not explicitly owned by this docs handoff
    - product code, tests, Rails, Vue, mobile/Expo, shared design-system, ops, deployment, or server changes
    - direct inspection or mutation of Combatives, DojoMate, or any other repository
    - live ECPay calls, merchant configuration, credentials, callbacks, payments, or refunds
    - dependency installation or network access
    - git branch creation or switching
    - git commit, merge, push, reset, restore, or clean
    - production, staging, secrets, provider, or customer-data actions
    - claims of live ECPay or production payment acceptance
  codex_execution:
    requested_model: gpt-5.4-mini
    requested_reasoning: medium
    execution_profile: mechanical_docs_tests_fixtures
    selection_reason: >-
      This job changes policy documentation only and performs terminology and
      diff checks; it does not implement payment, authority, or cross-repository
      behavior.
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
    - accepted_gaps
    - boundaries
    - blockers
    - recommended_control_action
```

## Terminal Continuation Rule

After all mutations and checks, send the minimal terminal wake as the final tool
action. Then write one authoritative structured return in the Handoff task and
stop the job. The healthy bound Handoff remains reusable.
