# Rails Full-Suite Repair Return

```yaml
status: complete
checkout_observed:
  branch: main
  repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  base_commit: a26f18167cff42023fc7e0764f73c37970d35e61
root_cause_groups:
  - group: locale-scoped validation assertions
    details:
      - The first-pass attempt added English validation copy under `zh-TW`, which the retry packet explicitly rejected.
      - The affected model tests now scope message assertions with `I18n.with_locale(:en)` instead of changing the product locale.
  - group: cash recorder evidence strength
    details:
      - The cash recorder test now validates the created ledger entry via durable fields: external reference, amount, registration id in `details`, and recorded admin metadata.
      - It still verifies the completed payment and paid registration state.
  - group: preserved first-pass repairs
    details:
      - The earlier route-helper, temple-event invariant, authorization/content, and payment fixture repairs remain intact outside this retry surface.
changed_paths:
  - rails/app/controllers/api/v1/account/certificates_controller.rb
  - rails/app/controllers/api/v1/account/guest_lists_controller.rb
  - rails/app/controllers/api/v1/account/registrations_controller.rb
  - rails/test/integration/account/api/certificates_test.rb
  - rails/test/integration/account/api/guest_lists_test.rb
  - rails/test/integration/account/api/registrations_test.rb
  - rails/test/integration/admin/patron_picker_test.rb
  - rails/test/integration/admin/registrations_access_test.rb
  - rails/test/models/agreement_acceptance_test.rb
  - rails/test/models/api_request_counter_test.rb
  - rails/test/models/background_task_test.rb
  - rails/test/models/blacklist_entry_test.rb
  - rails/test/models/data_anomaly_test.rb
  - rails/test/models/data_export_job_test.rb
  - rails/test/models/notification_test.rb
  - rails/test/models/feature_flag_rollout_test.rb
  - rails/test/models/data_export_payload_test.rb
  - rails/test/models/notification_rule_test.rb
  - rails/test/models/temple_payment_test.rb
  - rails/test/services/archives_annual_rollup_test.rb
  - rails/test/services/archives_lookup_test.rb
  - rails/test/services/payments/cash_payment_recorder_test.rb
  - rails/test/services/payments/temple_registration_builder_test.rb
  - docs/operator/returns/2026-07-12-rails-full-suite-repair-return.md
checks:
  - command: "cd /Users/jimmy1768/Projects/shengfukung-wenfu/rails && bin/rails test"
    result: "pass (310 runs, 1748 assertions, 0 failures, 0 errors, 0 skips)"
  - command: "cd /Users/jimmy1768/Projects/shengfukung-wenfu && git diff --check"
    result: "pass"
  - command: "cd /Users/jimmy1768/Projects/shengfukung-wenfu && git status --short"
    result: "pass"
residual_gaps:
  - "None blocking; the suite is green. The only visible runtime noise is the pre-existing Rack `:unprocessable_entity` deprecation warnings."
recommended_control_action:
  - "Review the final diff and hand back to Wenfu Control for the next decision."
```
