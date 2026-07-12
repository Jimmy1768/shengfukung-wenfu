# Handoff: Account/Admin Final Polish

```yaml
handoff:
  handoff_id: shengfukung-2026-07-12-account-admin-final-polish
  control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  objective: >-
    Perform a bounded final polish pass on the core account and admin web
    surfaces, fixing clear visual, responsive, accessibility, copy, and
    consistency defects without redesigning the product or changing authority,
    persistence, payment, or business behavior.
  accepted_design_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/shared/design-system/themes.json
    - /Users/jimmy1768/Projects/shengfukung-wenfu/ops/docs/reference/deployment_notes.md
    - OperatorKit commit b5175f8d
  readiness_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-rails-full-suite-repair-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-synthetic-onboarding-acceptance-update-acceptance.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: cb887294c8d34dbc16993231caec6003ece3f16b
    status_sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    verified_at: 2026-07-12T16:29:32+08:00
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
    - docs/operator/returns/2026-07-12-account-admin-final-polish-return.md
    - docs/operator/eval_records/2026-07-12-account-admin-final-polish-eval.md
  required_behavior:
    - Inspect the core account and admin pages before editing and identify only clear, high-confidence polish defects.
    - Prioritize layouts/navigation, sign-in/sign-up, account dashboard/profile/settings, admin dashboard/temple profile, offering setup, registrations, orders, and payments.
    - Improve visual consistency, spacing, hierarchy, responsive behavior, focus states, labels, empty states, action clarity, and Traditional Chinese/English presentation where evidence supports a narrow fix.
    - Reuse shared design tokens and existing component patterns; do not introduce a visual redesign or new design system.
    - Preserve all routes, form parameters, authorization checks, role/permission behavior, persistence, payment behavior, and onboarding business rules.
    - If a possible defect requires authority, security, persistence, controller, model, route, migration, or cross-contract changes, do not change it in this job; record it as a separate high-profile follow-up.
    - Use the in-app browser for a local visual walkthrough when available. If browser policy blocks a path, continue with render/request evidence and record the gap; do not treat an unavailable external participant as a blocker.
    - Rebuild checked-in Rails CSS with `bin/build_rails_css` after SCSS changes.
    - Add or update focused integration assertions for behavior or markup changed by the polish pass.
    - Keep all edits directly tied to observed account/admin defects; avoid opportunistic cleanup.
    - Write a durable eval record describing pages reviewed, defects fixed, browser or equivalent evidence, and remaining non-blocking issues.
    - Write a durable return with exact changed paths, checks, browser gaps, authority boundary confirmation, and recommended Control action.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/build_rails_css
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test test/integration/account test/integration/admin
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - controllers, models, forms, services, helpers, routes, migrations, schema, seeds, and database data
    - auth/session/permission/role behavior changes
    - Vue, mobile/Expo, shared design-system source, ops, nginx, deployment, server, and production changes
    - dependency installation or network access
    - git branch creation or switching
    - git commit, merge, push, reset, restore, or clean
    - production, staging, secrets, payment-provider, real ECPay, or customer-data actions
    - product redesign or new feature scope
  codex_execution:
    requested_model: gpt-5.4
    requested_reasoning: medium
    execution_profile: ordinary_bounded_implementation
    selection_reason: >-
      The job is a bounded view/style/test polish pass with authority,
      persistence, security, and cross-contract changes explicitly blocked.
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
    heartbeat_delay_minutes: 10
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
    - browser_evidence
    - authority_boundary
    - blockers
    - recommended_control_action
```

## Terminal Continuation Rule

After all repository mutations and checks, send exactly one minimal wake payload
to Wenfu Control as the final tool action. Then write the authoritative
structured return in the Handoff task and stop the job. The healthy Handoff
remains bound and reusable.
