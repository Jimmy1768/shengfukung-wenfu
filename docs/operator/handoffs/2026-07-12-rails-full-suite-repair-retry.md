# Handoff: Rails Full-Suite Repair Retry

```yaml
handoff:
  handoff_id: shengfukung-2026-07-12-rails-full-suite-repair-retry
  owner_control_thread_id: 019f5518-af59-74f3-af7f-a37241bf418d
  handoff_thread_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_handoff_task_id: 019f5519-0f72-7273-b50e-65739e5a2a36
  objective: >-
    Correct the bounded localization and evidence defects found during Control
    review while preserving the otherwise green Rails full-suite repair.
  accepted_design_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-rails-full-suite-repair.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-rails-full-suite-repair-retry.md
  readiness_refs:
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-rails-full-suite-repair-return.md
  checkout:
    path: /Users/jimmy1768/Projects/shengfukung-wenfu
    branch: main
    base_commit: a26f18167cff42023fc7e0764f73c37970d35e61
    status_sha256: 74fc7103997539a9b3f0aabbaeb98134dfaf483bdcfe27499a58a5c8845e594e
    verified_at: 2026-07-12T15:26:57+08:00
  owned_files_or_surfaces:
    - rails/config/locales/errors.zh-TW.yml
    - rails/test/models/data_anomaly_test.rb
    - rails/test/models/data_export_job_test.rb
    - rails/test/models/notification_test.rb
    - rails/test/models/blacklist_entry_test.rb
    - rails/test/models/agreement_acceptance_test.rb
    - rails/test/models/feature_flag_rollout_test.rb
    - rails/test/models/background_task_test.rb
    - rails/test/models/api_request_counter_test.rb
    - rails/test/models/data_export_payload_test.rb
    - rails/test/models/notification_rule_test.rb
    - rails/test/services/payments/cash_payment_recorder_test.rb
    - docs/operator/returns/2026-07-12-rails-full-suite-repair-return.md
  required_behavior:
    - Delete `rails/config/locales/errors.zh-TW.yml`; do not put English copy under `zh-TW`.
    - Keep English validation-message assertions explicit to `I18n.with_locale(:en)` in the affected model tests, using the narrowest readable helper or per-test scope.
    - Do not change production locale selection or weaken validation behavior.
    - Preserve every accepted first-pass repair outside this retry's owned paths.
    - Strengthen the cash recorder test to identify the created ledger entry by durable fields such as external reference, amount, details registration id, and recorded admin metadata; do not rely only on a global count delta.
    - Correct the durable return's root-cause explanation and `changed_paths` so they match the final diff exactly and no longer claim `rails/test/test_helper.rb` changed.
  required_checks:
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check
    - cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short
  blocked_surfaces:
    - all paths not explicitly owned by this retry
    - git branch creation or switching
    - git commit, merge, push, reset, restore, or clean
    - dependency installation or network access
    - database migrations or schema changes
    - production, staging, deployment, secrets, payment-provider, real ECPay, or customer-data actions
    - V1 acceptance or production-promotion decisions
  codex_execution:
    profile_id: handoff
    model: gpt-5.4-mini
    reasoning: medium
    execution_surface: shared_checkout
    lifecycle: persistent_disposable
  approval_policy:
    owned_by: Control
    handoff_must_return_on_approval: true
  follow_up:
    dispatch_mode: fire_and_forget
    sole_continuation_signal: heartbeat_wakeup
    expected_runtime_class: small
    heartbeat_required: true
    heartbeat_delay_minutes: 3
    active_check_scope: task_status_only
    transcript_read_only_after_terminal_status: true
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

## Terminal Return Rule

Write exactly one terminal return as the final output in the Wenfu Handoff task,
then stop. Do not send it to Wenfu Control and do not claim cross-task delivery.
Heartbeat is the sole wakeup path.
