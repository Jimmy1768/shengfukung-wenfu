# Handoff: Final Web Readiness WR-6 Through WR-8

```yaml
handoff:
  handoff_id: shengfukung-2026-07-13-final-web-readiness-wr6-wr8
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f55bd-3447-74f3-8225-eabfdc511e64
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f55bd-3447-74f3-8225-eabfdc511e64
  objective: >-
    Execute WR-6 through WR-8 of the accepted final web-readiness plan:
    complete the local account/admin operational UX review, reconcile all
    current-source readiness documentation, assemble exact final evidence and
    Git state, repair only concrete bounded defects, and recommend the binary
    `ready` or `not_ready` decision for Control acceptance.
  accepted_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/ops/docs/plans/FINAL_WEB_READINESS_AND_EXPO_GATE_PLAN.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-final-web-readiness-stage-1-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-13-final-web-readiness-wr4-wr5-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-account-admin-final-polish-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-12-assisted-onboarding-ecpay-gap-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-help-guide-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/ops/docs/plans/DEPLOYMENT_READINESS.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: 432b28bc695d45379306f470ffb5c6b77294ffbc
    status_sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    verified_at: 2026-07-13T11:55:38+08:00
  owned_files_or_surfaces:
    - rails/app/views/layouts/account.html.erb
    - rails/app/views/layouts/admin.html.erb
    - rails/app/views/account/**
    - rails/app/views/admin/**
    - rails/app/stylesheets/account/**
    - rails/app/stylesheets/admin/**
    - rails/public/backend/assets/account.css
    - rails/public/backend/assets/admin.css
    - rails/test/integration/account/**
    - rails/test/integration/admin/**
    - docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md
    - docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md
    - docs/operator/workflows/2026-07-12-assisted-onboarding-ecpay-gap-decision.md
    - docs/operator/workflows/2026-06-13-production-boundary-decision.md
    - docs/operator/workflows/2026-06-13-v1-help-guide-decision.md
    - ops/docs/plans/DEPLOYMENT_READINESS.md
    - docs/operator/eval_records/2026-07-13-final-web-readiness-wr6-wr8-eval.md
    - docs/operator/returns/2026-07-13-final-web-readiness-wr6-wr8-return.md
  required_behavior:
    - Read WR-6, WR-7, and WR-8 completely and treat all historical evidence as historical unless a current decision explicitly incorporates it.
    - Review account creation/login, account dashboard/profile/settings, owner/admin entry, navigation, responsive layout, temple profile, payment-method setup, offering setup/review, registrations, orders, payments, refunds/cancellations, CSV exports, and archives.
    - Verify pending, completed, failed/cancelled, and refunded states remain visually and textually distinct and operationally understandable.
    - Review empty states, validation/error presentation, long flash/notices, keyboard focus, field labels/hints, action clarity, and narrow/mobile layouts.
    - Use the in-app browser for local rendered-page evidence when available. Keep it local, use only synthetic/test data, do not follow external ECPay or other provider links, and do not submit external forms.
    - If the browser capability is unavailable or cannot safely reach a surface, use rendered HTML, request/integration tests, compiled CSS, source inspection, and existing accepted screenshots/eval records; record the exact fallback. Tool unavailability alone is not a blocker.
    - Repair only concrete high-confidence presentation, accessibility, copy, responsive, or test defects within owned account/admin paths. Do not redesign the product or change routes, parameters, authority, persistence, accounting, payment semantics, or business policy.
    - If a discovered defect requires controller/model/service/route/migration/security/provider-contract changes, do not widen scope; return the exact blocker and recommended next packet.
    - Rebuild checked-in CSS with repo-root `bin/build_rails_css` after style changes and add focused request/integration assertions for any changed markup or behavior.
    - Reconcile the current-source readiness documents so they consistently state: assisted onboarding is current; real offering intake and live ECPay are accepted rollout gaps; neither blocks hiring or Expo after `ready`; the broader help guide is later; production requires a separate approved workflow; historical records do not override current decisions.
    - Do not rewrite historical acceptance/eval/return records merely to make them look current. Amend current decision/plan sources only where a live contradiction exists.
    - Inventory exact HEAD, branch/upstream, ahead/behind, staged/unstaged/untracked, changed paths, commits reviewed, checks/counts, warnings, skipped checks, accepted gaps, residual risks, rollback/revert guidance, committed state, and pushed state.
    - Run the complete final build/test/check set on the finished tree.
    - Write a durable eval with page/surface evidence, doc reconciliation findings, exact commands/counts, gaps, boundaries, and Git state.
    - Write a structured return that recommends exactly `ready` or `not_ready`. Handoff must not create the Control acceptance record or claim final acceptance authority.
    - Recommend `not_ready` only for a concrete blocking repository defect and include exact impact and clearing verification. Do not use unavailable real participants, live ECPay, marketing manager, Guide agent, production deployment, or browser tooling as blockers.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && bin/build_rails_css
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test test/integration/account test/integration/admin
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/vue && npm run build
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && ruby ops/scripts/audit_offering_configs.rb
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && rg -n "assisted onboarding|operator-assisted|real offering|live ECPay|non-block|Expo|marketing manager|help guide|production" ops/docs/plans/FINAL_WEB_READINESS_AND_EXPO_GATE_PLAN.md ops/docs/plans/DEPLOYMENT_READINESS.md docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md docs/operator/workflows/2026-07-12-assisted-onboarding-ecpay-gap-decision.md docs/operator/workflows/2026-06-13-production-boundary-decision.md docs/operator/workflows/2026-06-13-v1-help-guide-decision.md
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short --branch
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git branch -vv --no-abbrev
  blocked_surfaces:
    - controllers, models, services, routes, migrations, schema, seeds, authority, tenant, payment, accounting, or provider-contract behavior
    - new dependencies, dependency upgrades, unrestricted redesign, Expo/mobile implementation, cross-repository inspection/reuse
    - real temple/customer data, real ECPay, credentials, external submissions, production, staging, deployment, servers, DNS, TLS, queues, cron, secrets, or customer state
    - git branch creation/switching, commit, merge, push, reset, restore, clean, or production promotion
  codex_execution:
    requested_model: gpt-5.4
    requested_reasoning: high
    execution_profile: final_ux_docs_readiness_closeout
    selection_reason: >-
      The final packet combines rendered operational UX judgment, cross-document
      contract reconciliation, payment/authority boundary review, exact Git
      evidence, and a binary readiness recommendation.
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
    - ux_evidence
    - documentation_reconciliation
    - final_checks
    - git_state
    - skipped_checks
    - accepted_gaps
    - residual_risks
    - rollback_guidance
    - boundaries
    - readiness_recommendation
    - blockers
    - recommended_control_action
```

## Terminal Continuation Rule

After all repository mutations and checks, send exactly one minimal wake payload
to Wenfu Control as the final tool action. Then write the authoritative return
in the Handoff task and stop the bounded job. The healthy Handoff remains bound.
