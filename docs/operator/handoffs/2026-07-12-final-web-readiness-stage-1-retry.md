# Handoff: Final Web Readiness Stage 1 Retry

```yaml
handoff:
  handoff_id: shengfukung-2026-07-12-final-web-readiness-stage-1-retry
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f55bd-3447-74f3-8225-eabfdc511e64
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f55bd-3447-74f3-8225-eabfdc511e64
  objective: >-
    Complete the interrupted stage-one authority repair by making temple
    membership role authoritative in admin promotion and revocation, auditing
    every remaining global owner-role call site, and rerunning the complete
    WR-1 through WR-3 verification set.
  required_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-final-web-readiness-stage-1.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-final-web-readiness-stage-1-retry.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-07-12-final-web-readiness-stage-1-eval.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-final-web-readiness-stage-1-return.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: c4a5f38d3aa0bc1e0009fa02b8a0dd6ae4472f8e
    expected_existing_diff_sha256: 5afdf0c725e9e4834ff0ecdc43a2e06620d3903c9791eac5d9956fe327c4daa2
    verified_at: 2026-07-12T17:51:43+08:00
  owned_files_or_surfaces:
    - rails/app/services/admin/patron_admin_manager.rb
    - rails/app/controllers/admin/base_controller.rb
    - rails/app/models/admin_account.rb
    - rails/app/models/admin_temple_membership.rb
    - rails/test/**
    - docs/operator/eval_records/2026-07-12-final-web-readiness-stage-1-eval.md
    - docs/operator/returns/2026-07-12-final-web-readiness-stage-1-return.md
  required_behavior:
    - Preserve and review the existing uncommitted stage-one diff; do not discard or overwrite it blindly.
    - Read the retry decision and trace every remaining application use of `owner_role?`.
    - Make `AdminTempleMembership.role` authoritative for all temple-scoped owner authorization.
    - Ensure ordinary patron-to-admin promotion creates an admin membership in the selected temple and never inherits ownership from another temple.
    - Ensure revocation checks the selected temple membership: block revoking its owner, allow revoking its admin even when the account owns another temple.
    - Treat any remaining global-role call as acceptable only when it is demonstrably global or development-only and cannot widen authority; record that reasoning in the eval.
    - Add focused regressions for cross-temple promotion and revocation and preserve the existing permission, registration-scope, and ECPay-secret regressions.
    - Do not redesign the role schema, add a migration, change public APIs, or introduce dependencies.
    - Update the durable eval and return to reflect the complete final diff, actual checks, and replacement Handoff id.
    - Do not claim final readiness; this retry can only complete WR-1 through WR-3.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && bin/build_rails_css
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails db:migrate:status
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test test/integration/account test/integration/admin test/integration/internal/temple_access_test.rb test/integration/api/v1/payment_webhooks_test.rb test/services/payments test/services/payment_gateway/ecpay_adapter_test.rb test/services/reporting test/services/archives_registrations_csv_exporter_test.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/vue && npm run build
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - migrations, schema redesign, seeds, destructive database actions, or real data
    - new dependencies, dependency upgrades, network access, or cross-repository work
    - product-policy redesign, Expo/mobile, deployment, production, staging, secrets, or live ECPay
    - git branch creation/switching, commit, merge, push, reset, restore, or clean
  codex_execution:
    requested_model: gpt-5.4
    requested_reasoning: high
    execution_profile: authority_security_readiness_retry
    selection_reason: >-
      This retry closes a cross-temple authority root cause and must verify all
      remaining role call sites without expanding into schema redesign.
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
    - root_cause
    - remaining_owner_role_call_sites
    - checks
    - blockers
    - recommended_control_action
```

## Terminal Continuation Rule

After all repository mutations and checks, send exactly one minimal wake payload
to Wenfu Control as the final tool action. Then write the authoritative
structured return in the Handoff task and stop the bounded job. The healthy
replacement Handoff remains bound and reusable.
