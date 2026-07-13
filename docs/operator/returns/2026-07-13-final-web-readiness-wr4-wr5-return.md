# Return: Final Web Readiness WR-4 And WR-5

Handoff id: `shengfukung-2026-07-13-final-web-readiness-wr4-wr5`

Created: 2026-07-13

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `main`

## status

completed

## checkout_observed

- observed `HEAD`: `b57aec8107735fd366c2aaf7fc26dd31b6dc1812`
- packet commit: `b57aec8`
- implementation base: `a36cbd9af2e45036723f7389f41ae0dc971cf7fa`
- branch: `main`
- packet status checksum expectation: clean checkout
- observed starting checkout: clean

## requested_profile

- requested_model: `gpt-5.4`
- requested_reasoning: `high`
- execution_profile: `persistence_payment_contract_readiness`

## changed_paths

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-13-readiness-synthetic-intake.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-07-13-final-web-readiness-wr4-wr5-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-13-final-web-readiness-wr4-wr5-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/ops/docs/reference/onboarding.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/ops/scripts/audit_offering_configs.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/ops/scripts/sync_offering_configs.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/readiness-synthetic.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/offerings/readiness-synthetic.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/offerings/template_sync.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/offerings/readiness_synthetic_proof_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/offering_orders_registrant_flow_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/admin/payment_methods_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/account/api/payment_statuses_test.rb`

## synthetic_intake_and_config

- durable intake record added at `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-13-readiness-synthetic-intake.md`
- synthetic temple fixture added at `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/readiness-synthetic.yml`
- synthetic offering fixture added at `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/offerings/readiness-synthetic.yml`
- proof offering:
  - slug: `readiness-peace-lamp`
  - kind: `service`
  - registration period key: `2026-q4-peace-light`
  - status after ensure/apply path: `draft`
  - repeat registrations: enabled
- operator mapping from intake fields to YAML is recorded in the intake workflow and referenced from onboarding docs

## apply_idempotency_cleanup_evidence

- bootstrap proof used `Seeds::Temples.bootstrap(slug: "readiness-synthetic")`
- ensure proof used `Offerings::TemplateParity.ensure_missing!(temple, kinds: [:services])`
- rerun proof showed no duplicate service creation after the first ensure
- sync proof used `Offerings::TemplateSync.call(temple)` to restore stale metadata on the existing service without new rows
- admin order proof showed the configured synthetic draft service can accept admin-created registrations through the real order controller path
- payment-status proof showed registrations tied to the configured synthetic service remain visible through the account API contract
- cleanup proof relied on transactional Rails tests, so synthetic database state rolled back automatically after each focused proof

## ecpay_local_contract_matrix

- ECPay remains the intended non-test default and fake remains the test default: covered by existing focused tests
- hosted checkout payload, stage endpoint default, and temple-specific production override: covered by existing adapter tests
- payment-method page still shows Merchant ID, HashKey, and HashIV setup instructions
- stored HashKey and HashIV still do not render back into HTML
- new regression confirms payment-method audit logs do not persist raw HashKey or HashIV values
- pending checkout, completed return/webhook, failed/cancelled non-received, and duplicate webhook idempotency remain covered by focused admin/account/webhook tests
- refund/accounting/export semantics remain locally covered without live provider execution
- live merchant setup, callback reachability, settlement, and real refunds remain accepted rollout-only gaps

## checks

- `ruby ops/scripts/audit_offering_configs.rb`
  - pass
- `SLUG=definitely-missing-readiness-slug ruby ops/scripts/audit_offering_configs.rb`
  - pass
  - non-zero exit with concise `Unknown SLUG: definitely-missing-readiness-slug`
- `SLUG=definitely-missing-readiness-slug ruby ops/scripts/sync_offering_configs.rb`
  - pass
  - non-zero exit with concise `Unknown SLUG: definitely-missing-readiness-slug`
- `cd rails && bin/rails test test/services/offerings test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/integration/admin/offering_orders_registrant_flow_test.rb`
  - pass
  - `40 runs, 439 assertions, 0 failures, 0 errors, 0 skips`
- `cd rails && bin/rails test test/services/payment_gateway/ecpay_adapter_test.rb test/services/payments test/integration/admin/payment_methods_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/orders_and_payments_access_test.rb test/integration/account/registration_payment_flow_test.rb test/integration/account/api/payment_statuses_test.rb test/integration/api/v1/payment_webhooks_test.rb`
  - pass
  - `79 runs, 434 assertions, 0 failures, 0 errors, 0 skips`
- `cd rails && bin/rails test`
  - pass
  - `324 runs, 1846 assertions, 0 failures, 0 errors, 0 skips`
- `git diff --check`
  - pass
- `git status --short`
  - pass for expected owned-path changes only
  - six modified tracked files plus seven untracked packet-owned additions

## accepted_gaps

- no real temple or real intake submitter
- no real ECPay merchant account, credentials, callbacks, payment, settlement, or refund
- proof covers one realistic synthetic service onboarding path, not every future temple configuration shape
- service remained draft/non-live by design

## residual_risk

- event apply remains out of WR-4 scope because the existing scheduling gap is still intentionally blocked
- live ECPay production validation still requires a separately approved first-temple rollout
- future guide-assisted intake or config generation is still optional and unimplemented

## blockers

- none

## recommended_control_action

- accept WR-4 and WR-5 as complete with the synthetic intake/config proof and the local ECPay contract matrix captured in the eval
- retain the new `readiness-synthetic` fixture and intake record as the replayable future readiness proof path
- continue to the final control-level readiness decision using WR-1 through WR-5 evidence plus the already accepted remaining boundaries
