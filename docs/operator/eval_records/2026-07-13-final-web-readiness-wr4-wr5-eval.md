# Eval Record: Final Web Readiness WR-4 And WR-5

Eval id: `shengfukung-2026-07-13-final-web-readiness-wr4-wr5-eval`

Created: 2026-07-13

Evaluator: Wenfu Handoff `019f55bd-3447-74f3-8225-eabfdc511e64`

Mode: synthetic onboarding proof, payment-contract verification, and complete automated regression

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `main`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-13-final-web-readiness-wr4-wr5.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-13-final-web-readiness-wr4-wr5-return.md`

## Objective

Execute WR-4 and WR-5 of the accepted final readiness plan:

- prove one realistic synthetic offering intake can be translated into the supported temple profile and offering YAML contract;
- prove the current bootstrap, template, ensure, sync, registration, payment-status, and admin-order paths accept that synthetic configuration safely;
- verify all locally testable ECPay setup, credential-handling, pending/completed/failed, idempotency, and refund-related application contracts without real provider access.

## Synthetic Intake And Config Mapping

- human-facing intake record:
  - `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-13-readiness-synthetic-intake.md`
- temple profile fixture:
  - `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/readiness-synthetic.yml`
- offering config fixture:
  - `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/offerings/readiness-synthetic.yml`

Synthetic proof shape:

- temple slug: `readiness-synthetic`
- offering slug: `readiness-peace-lamp`
- offering kind: service
- category: `lamp`
- registration period key: `2026-q4-peace-light`
- offering status after ensure/apply: `draft`
- operator mapping is recorded in the intake workflow and referenced from `ops/docs/reference/onboarding.md`

## Work Completed

- added one durable, clearly synthetic, non-secret temple profile and offering fixture
- added one durable, human-facing intake record that maps operator intake fields to YAML keys
- added `Offerings::TemplateSync` so sync behavior is testable without widening the onboarding design
- added focused WR-4 regressions for:
  - synthetic bootstrap from profile YAML
  - synthetic ensure/create from offering YAML
  - rerun idempotency
  - metadata sync repair without duplicate creation
  - admin order creation against the configured synthetic draft service
  - payment-status visibility for a registration tied to the configured synthetic service
- added WR-5 regression proving payment-method audit logs do not persist raw HashKey or HashIV values
- updated onboarding docs to reference the synthetic readiness intake and safer single-slug audit/sync operation

## Apply, Idempotency, And Cleanup Evidence

- `Seeds::Temples.bootstrap(slug: "readiness-synthetic")` created the synthetic temple row from durable YAML and loaded registration periods
- `Offerings::TemplateParity.ensure_missing!(temple, kinds: [:services])` created `readiness-peace-lamp` as a draft service with registration metadata, options, and repeat-registration flags sourced from YAML
- rerunning `ensure_missing!` created no duplicates once the service existed
- `Offerings::TemplateSync.call(temple)` restored stale metadata on the existing synthetic service without creating a second row
- focused proof executed in transactional Rails tests, so synthetic database state rolled back automatically after each test and left no persistent local synthetic rows behind

## ECPay Local Contract Matrix

- default provider intent:
  - existing focused tests still cover ECPay as the intended non-test default and fake as the test default
- checkout setup:
  - existing adapter tests still cover hosted checkout payload generation, stage endpoint default, and temple-specific production override
- credential visibility:
  - payment-method page renders Merchant ID, HashKey, and HashIV setup copy
  - stored HashKey and HashIV still do not render back into HTML
  - new regression proves audit-log metadata does not persist raw HashKey or HashIV values
- successful completion:
  - existing admin/account/webhook tests still cover pending checkout creation plus completed return/webhook reconciliation
- failed or cancelled paths:
  - existing focused tests still cover failed/cancelled as non-received and not paid
- idempotency:
  - existing webhook duplicate-event test still covers callback idempotency
- refund/accounting/export semantics:
  - existing focused payment and reporting tests still cover refund-related application semantics without provider execution
- accepted live gap:
  - no live merchant account, callback reachability, settlement, or real refund/provider calls were performed

## Commands Run

1. `ruby ops/scripts/audit_offering_configs.rb`
2. `cd rails && bin/rails test test/services/offerings test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/integration/admin/offering_orders_registrant_flow_test.rb`
3. `cd rails && bin/rails test test/services/payment_gateway/ecpay_adapter_test.rb test/services/payments test/integration/admin/payment_methods_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/orders_and_payments_access_test.rb test/integration/account/registration_payment_flow_test.rb test/integration/account/api/payment_statuses_test.rb test/integration/api/v1/payment_webhooks_test.rb`
4. `cd rails && bin/rails test`
5. `git diff --check`
6. `git status --short`

## Verification Results

- `ruby ops/scripts/audit_offering_configs.rb`
  - pass
- `SLUG=definitely-missing-readiness-slug ruby ops/scripts/audit_offering_configs.rb`
  - pass
  - non-zero exit with concise `Unknown SLUG: definitely-missing-readiness-slug`
- `SLUG=definitely-missing-readiness-slug ruby ops/scripts/sync_offering_configs.rb`
  - pass
  - non-zero exit with concise `Unknown SLUG: definitely-missing-readiness-slug`
- focused WR-4 suite
  - pass
  - `40 runs, 439 assertions, 0 failures, 0 errors, 0 skips`
- focused WR-5 suite
  - pass
  - `79 runs, 434 assertions, 0 failures, 0 errors, 0 skips`
- full Rails suite
  - pass
  - `324 runs, 1846 assertions, 0 failures, 0 errors, 0 skips`
- final `git diff --check`
  - pass
- final `git status --short`
  - pass for expected owned-path changes only
  - six modified tracked files plus seven untracked packet-owned additions

## Accepted Gaps

- no real temple, participant, intake submitter, or production data
- no real ECPay merchant account, credentials, callback reachability, payment, settlement, or refund
- synthetic fixture proves one realistic service-intake path, not every future temple offering shape
- service remained draft/non-live throughout the synthetic proof

## Residual Risk

- WR-4 proof is intentionally service-scoped because event apply remains separately blocked by the existing scheduling gap
- live ECPay smoke validation still belongs to the first explicitly approved temple rollout
- any future generalized intake automation or guide/bot assistance remains optional follow-up work, not part of this readiness packet
