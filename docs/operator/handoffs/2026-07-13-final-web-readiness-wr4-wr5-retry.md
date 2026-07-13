# Handoff: Final Web Readiness WR-4 And WR-5 Retry

```yaml
handoff:
  handoff_id: shengfukung-2026-07-13-final-web-readiness-wr4-wr5-retry
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f55bd-3447-74f3-8225-eabfdc511e64
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f55bd-3447-74f3-8225-eabfdc511e64
  objective: >-
    Complete WR-4/WR-5 by making the new single-temple offering-config audit
    and sync options fail closed on an unknown SLUG, preserving all existing
    synthetic onboarding and ECPay proof work, and rerunning final verification.
  required_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-13-final-web-readiness-wr4-wr5.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-13-final-web-readiness-wr4-wr5-retry.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-07-13-final-web-readiness-wr4-wr5-eval.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-13-final-web-readiness-wr4-wr5-return.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: b57aec8107735fd366c2aaf7fc26dd31b6dc1812
    expected_existing_status_sha256: 9328bd80518aa094f02a70cf67f55e07cb13a0909c2944e6b479ab77d771fd61
    verified_at: 2026-07-13T11:34:12+08:00
  owned_files_or_surfaces:
    - ops/scripts/audit_offering_configs.rb
    - ops/scripts/sync_offering_configs.rb
    - ops/docs/reference/onboarding.md
    - rails/test/**
    - docs/operator/eval_records/2026-07-13-final-web-readiness-wr4-wr5-eval.md
    - docs/operator/returns/2026-07-13-final-web-readiness-wr4-wr5-return.md
  required_behavior:
    - Preserve and review the complete existing WR-4/WR-5 diff before editing.
    - Keep no-SLUG global audit and sync behavior unchanged.
    - When `SLUG` is set, resolve exactly one existing temple before entering the script loop.
    - Unknown selected slugs must fail non-zero with a concise error; never silently no-op successfully.
    - Valid selected slugs must audit/sync only that temple.
    - Do not print or expose secrets, connection strings, or unrelated environment values.
    - Add the narrowest durable regression for selector semantics if practical without introducing dependencies or redesigning the scripts.
    - Explicitly run both negative CLI commands using `definitely-missing-readiness-slug` and record their non-zero exits.
    - Rerun the original WR-4 and WR-5 focused suites and the full Rails suite on the final tree.
    - Update the eval and return with the retry fix, exact commands/counts, and Control reproduction resolution.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && ruby ops/scripts/audit_offering_configs.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && SLUG=definitely-missing-readiness-slug ruby ops/scripts/audit_offering_configs.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && SLUG=definitely-missing-readiness-slug ruby ops/scripts/sync_offering_configs.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test test/services/offerings test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/integration/admin/offering_orders_registrant_flow_test.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test test/services/payment_gateway/ecpay_adapter_test.rb test/services/payments test/integration/admin/payment_methods_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/orders_and_payments_access_test.rb test/integration/account/registration_payment_flow_test.rb test/integration/account/api/payment_statuses_test.rb test/integration/api/v1/payment_webhooks_test.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  expected_check_semantics:
    - global audit exits zero
    - both missing-slug commands exit non-zero and are counted as passing negative checks
    - all Rails suites exit zero
  blocked_surfaces:
    - real temple/client YAML, real ECPay, credentials, provider calls, production, deployment, published offerings, or customer state
    - migrations, schema or provider-contract redesign, new dependencies, cross-repository work, Expo/mobile, git commit/push/reset/clean
  codex_execution:
    requested_model: gpt-5.4-mini
    requested_reasoning: medium
    execution_profile: mechanical_operational_guard_retry
    selection_reason: >-
      The accepted implementation needs one narrow fail-closed script guard,
      explicit negative command evidence, and regression reruns without new
      architecture, persistence semantics, or payment behavior.
    execution_surface: shared_checkout
    lifecycle: persistent_bound
  approval_policy:
    owned_by: Control
    handoff_must_return_on_approval: true
  follow_up:
    dispatch_mode: fire_and_forget
    primary_continuation_signal: explicit_terminal_wake_signal
    expected_runtime_class: normal
    heartbeat_required: true
    heartbeat_delay_minutes: 15
    active_check_scope: task_status_only
    transcript_read_only_after_terminal_status: true
    terminal_wake_signal:
      tool: codex_app.send_message_to_thread
      receiver_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
      timing: final_tool_action_after_mutations_and_checks
      exactly_once: true
      authoritative_return: false
      payload:
        handoff_thread_id: 019f55bd-3447-74f3-8225-eabfdc511e64
        terminal_status: completed | blocked | failed
        instruction: read_handoff_terminal_return_once
      on_send_failure: finish_local_return_and_rely_on_fallback_heartbeat
      on_active_status_race:
        read_active_transcript: false
        status_only_recovery_delay_minutes: 1
    terminal_return:
      location: handoff_thread
      delivery_to_control: false
      exactly_once: true
      stop_after_return: true
  return_shape:
    - status
    - checkout_observed
    - requested_profile
    - changed_paths
    - fail_closed_guard
    - negative_cli_checks
    - checks
    - blockers
    - recommended_control_action
```

## Terminal Continuation Rule

After all repository mutations and checks, send exactly one minimal wake payload
to Wenfu Control as the final tool action. Then write the authoritative return
in the Handoff task and stop the bounded job. The healthy Handoff remains bound.
