# Handoff: Final Web Readiness WR-4 And WR-5

```yaml
handoff:
  handoff_id: shengfukung-2026-07-13-final-web-readiness-wr4-wr5
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f55bd-3447-74f3-8225-eabfdc511e64
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f55bd-3447-74f3-8225-eabfdc511e64
  objective: >-
    Execute WR-4 and WR-5 of the accepted final web-readiness plan: prove one
    realistic synthetic offering intake can be translated into supported
    temple-specific configuration and safely applied into a working offering,
    and close every locally verifiable ECPay setup and application-contract
    check without real credentials, provider calls, or production claims.
  accepted_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/ops/docs/plans/FINAL_WEB_READINESS_AND_EXPO_GATE_PLAN.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-final-web-readiness-stage-1-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-12-assisted-onboarding-ecpay-gap-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/ops/docs/reference/onboarding.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-offering-setup-registration-intake-authoring-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-13-ecpay-default-path-local-verification-acceptance.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: a36cbd9af2e45036723f7389f41ae0dc971cf7fa
    status_sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    verified_at: 2026-07-13T11:16:57+08:00
  owned_files_or_surfaces:
    - docs/operator/workflows/**synthetic**intake**
    - docs/operator/eval_records/2026-07-13-final-web-readiness-wr4-wr5-eval.md
    - docs/operator/returns/2026-07-13-final-web-readiness-wr4-wr5-return.md
    - ops/docs/reference/onboarding.md
    - ops/scripts/audit_offering_configs.rb
    - ops/scripts/ensure_offering_configs.rb
    - ops/scripts/sync_offering_configs.rb
    - rails/db/temples/readiness-synthetic.yml
    - rails/db/temples/offerings/readiness-synthetic.yml
    - rails/app/services/offerings/**
    - rails/app/forms/admin/payment_methods_form.rb
    - rails/app/controllers/admin/payment_methods_controller.rb
    - rails/app/views/admin/payment_methods/show.html.erb
    - rails/app/services/payment_gateway/ecpay_adapter.rb
    - rails/app/services/payments/**
    - rails/app/controllers/payments/ecpay_checkouts_controller.rb
    - rails/config/initializers/ecpay.rb
    - rails/test/**
  required_behavior:
    - Read WR-4 and WR-5 completely and inspect the current intake, YAML/template, bootstrap, audit, ensure, sync, setup-draft, and ECPay paths before editing.
    - Locate the existing V1 offering intake material. If no durable human-facing one-offering intake template exists, add the smallest reusable non-secret template needed for this proof.
    - Complete one realistic synthetic intake for a clearly synthetic Taiwan temple service offering using public/non-secret information only.
    - Translate that intake into the repository's supported profile and offering configuration contract. Temple staff must not edit YAML; record the operator mapping from intake fields to configuration.
    - Prefer a service offering with a valid registration-period key so the proof does not silently widen into the currently blocked event-scheduling apply gap.
    - Use a clearly synthetic slug such as `readiness-synthetic`; do not change Shengfukung or another real/client temple configuration.
    - Prove the configured temple and offering through the actual bootstrap/template/audit/ensure/sync services or scripts in an isolated local test environment.
    - Verify the offering is created as draft/non-live, carries the intended form and registration metadata, is visible to admin/patron application contracts, and participates in registration, order/payment-status, and export paths.
    - Prove rerun idempotency or safe duplicate rejection and demonstrate dry-run, rollback, cleanup, or transaction isolation sufficient to leave no synthetic database state behind.
    - If the existing scripts cannot provide a safe isolated/dry-run proof, add the narrowest safety option and regression coverage; do not redesign onboarding.
    - Preserve a replayable synthetic fixture/config and focused automated regression so future changes can rerun this proof without a real temple.
    - Verify ECPay remains the intended non-test Taiwan online-payment default while test mode stays fake unless explicitly overridden.
    - Verify the owner-gated admin setup page explains Merchant ID, HashKey, HashIV, and environment setup; credential fields are protected and stored secrets do not render back into HTML or logs.
    - Verify local/stubbed checkout starts pending; authenticated completed return/webhook transitions correctly; failed/cancelled remains non-received; duplicate callbacks are idempotent; refund state/accounting/export semantics remain correct.
    - Use fake/static values only. Never access, invent as real, transmit, print, or persist actual merchant credentials.
    - Treat live merchant setup, public callback reachability, settlement, real payment, and real refund as accepted first-approved-temple rollout gaps, not blockers or bugs.
    - Repair only concrete local defects within owned paths. If a fix requires schema migration, provider-contract redesign, accounting-policy change, cross-repository reuse, or production action, return it as a separate blocker/follow-up rather than widening scope.
    - Write a durable eval with the completed synthetic intake/config mapping, exact apply evidence, idempotency/cleanup evidence, ECPay matrix, commands/counts, accepted gaps, and residual risk.
    - Write a structured return with exact changed paths and recommended Control action.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && ruby ops/scripts/audit_offering_configs.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test test/services/offerings test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/integration/admin/offering_orders_registrant_flow_test.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test test/services/payment_gateway/ecpay_adapter_test.rb test/services/payments test/integration/admin/payment_methods_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/orders_and_payments_access_test.rb test/integration/account/registration_payment_flow_test.rb test/integration/account/api/payment_statuses_test.rb test/integration/api/v1/payment_webhooks_test.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - real temple, real participant, or real offering data
    - real ECPay account, credentials, network calls, callbacks, payments, refunds, settlement, or merchant changes
    - Shengfukung or another real/client temple profile/offering YAML
    - published/live offering activation or production data
    - migrations, schema redesign, destructive database actions outside isolated synthetic cleanup, or accounting-policy changes
    - new dependencies, dependency upgrades, cross-repository inspection/reuse, Expo/mobile implementation, deployment, servers, production, staging, secrets, or customer state
    - git branch creation/switching, commit, merge, push, reset, restore, or clean
  codex_execution:
    requested_model: gpt-5.4
    requested_reasoning: high
    execution_profile: persistence_payment_contract_readiness
    selection_reason: >-
      WR-4 exercises configuration-to-persistence and idempotency boundaries,
      while WR-5 verifies payment-provider, secret-handling, refund, and
      accounting contracts; both require the high implementation baseline.
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
    heartbeat_delay_minutes: 25
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
    - synthetic_intake_and_config
    - apply_idempotency_cleanup_evidence
    - ecpay_local_contract_matrix
    - checks
    - accepted_gaps
    - residual_risk
    - blockers
    - recommended_control_action
```

## Terminal Continuation Rule

After all repository mutations and checks, send exactly one minimal wake payload
to Wenfu Control as the final tool action. Then write the authoritative
structured return in the Handoff task and stop the bounded job. The healthy
Handoff remains bound and reusable.
