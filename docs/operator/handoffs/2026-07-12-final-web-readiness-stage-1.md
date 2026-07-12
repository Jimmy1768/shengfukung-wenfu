# Handoff: Final Web Readiness Stage 1

```yaml
handoff:
  handoff_id: shengfukung-2026-07-12-final-web-readiness-stage-1
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  objective: >-
    Execute WR-1 through WR-3 of the accepted final web-readiness plan:
    establish a reproducible repository baseline, run the complete automated
    web regression, and perform a security, authority, tenant-isolation, and
    secret-handling scan. Repair only concrete, bounded repository defects
    whose root cause and safe verification fit this packet.
  accepted_plan:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/ops/docs/plans/FINAL_WEB_READINESS_AND_EXPO_GATE_PLAN.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-assisted-onboarding-ecpay-gap-policy-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-rails-full-suite-repair-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-account-admin-final-polish-acceptance.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: 89a0314322806f2cc4835f54fc8beb742e7bb19b
    status_sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    verified_at: 2026-07-12T17:21:10+08:00
  owned_files_or_surfaces:
    - rails/app/**
    - rails/config/**
    - rails/test/**
    - rails/public/backend/assets/account.css
    - rails/public/backend/assets/admin.css
    - vue/src/**
    - docs/operator/eval_records/2026-07-12-final-web-readiness-stage-1-eval.md
    - docs/operator/returns/2026-07-12-final-web-readiness-stage-1-return.md
  required_behavior:
    - Read the accepted plan completely and execute only WR-1, WR-2, and WR-3.
    - Record branch, HEAD, upstream/ahead-behind state, and staged, unstaged, and untracked state before work.
    - Verify Ruby, Bundler, Node, npm, migrations, test schema, and canonical CSS build readiness without dependency upgrades or network access.
    - Run the complete Rails suite and Vue production build plus focused account/admin, authority, tenant, registration, order, payment, refund, export, archive, and ECPay checks.
    - Review owner/admin promotion, last-owner and self-demotion protections, unauthorized access, cross-temple denial, session boundaries, provider-credential rendering/update authorization, payment/accounting scoping, export/archive scoping, and secret exposure.
    - Treat the lack of a real temple, real offering, marketing manager, Guide agent, or live ECPay account as an accepted non-blocker.
    - Do not claim live ECPay or production acceptance from local/stubbed evidence.
    - If a concrete defect is narrow, fully root-caused, within owned paths, and requires no migration, new dependency, business-policy decision, external system, or cross-repository contract, repair it and add focused regression evidence.
    - If a defect would change persistence structure, public API contracts, business authority policy, payment semantics, provider contracts, or architecture beyond a bounded local correction, do not widen scope; return the exact defect and recommended next packet.
    - Rebuild checked-in CSS with the repo-root `bin/build_rails_css` only if relevant source changes require it.
    - Preserve unrelated user changes if any appear; stop and return if safe attribution becomes impossible.
    - Write a durable eval record with exact commands, counts, reviewed boundaries, findings, skipped checks, accepted gaps, and residual risk.
    - Write a durable structured return with exact changed paths and recommended Control action.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && bin/build_rails_css
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails db:migrate:status
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test test/integration/account test/integration/admin test/integration/internal/temple_access_test.rb test/integration/api/v1/payment_webhooks_test.rb test/services/payments test/services/payment_gateway/ecpay_adapter_test.rb test/services/reporting test/services/archives_registrations_csv_exporter_test.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/vue && npm run build
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - database migrations, schema redesign, destructive database operations, seeds, or real data
    - new dependencies, dependency upgrades, or network access
    - cross-repository inspection, copying, or contract changes
    - Expo/mobile implementation
    - unrestricted temple self-service creation or product-policy redesign
    - live ECPay, real credentials, provider calls, payments, refunds, callbacks, or merchant configuration
    - production, staging, deployment, servers, DNS, TLS, queues, cron, secrets, or customer/temple state
    - git branch creation or switching
    - git commit, merge, push, reset, restore, or clean
  codex_execution:
    requested_model: gpt-5.4
    requested_reasoning: high
    execution_profile: authority_security_readiness_implementation
    selection_reason: >-
      The bounded job includes authority, tenant-isolation, secret-handling,
      payment-contract review, and permission to repair safe local defects, so
      it requires the high baseline even though external and structural changes
      remain blocked.
    execution_surface: shared_checkout
    lifecycle: persistent_bound
  approval_policy:
    owned_by: Control
    handoff_must_return_on_approval: true
  follow_up:
    dispatch_mode: fire_and_forget
    primary_continuation_signal: explicit_terminal_wake_signal
    expected_runtime_class: long
    heartbeat_required: true
    heartbeat_delay_minutes: 20
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
      stop_after_return: true
  return_shape:
    - status
    - checkout_observed
    - requested_profile
    - changed_paths
    - baseline
    - checks
    - security_authority_tenant_review
    - accepted_gaps
    - skipped_checks
    - residual_risk
    - blockers
    - recommended_control_action
```

## Terminal Continuation Rule

After all repository mutations and checks, send exactly one minimal wake payload
to Wenfu Control as the final tool action. Then write the authoritative
structured return in the Handoff task and stop the bounded job. The healthy
Handoff remains bound and reusable.
