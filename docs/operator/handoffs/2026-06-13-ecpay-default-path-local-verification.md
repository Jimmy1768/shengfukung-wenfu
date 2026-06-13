# Handoff: ECPay Default Path Local Verification

Handoff id: `shengfukung-2026-06-13-ecpay-default-path-local-verification`

Created: 2026-06-13

Coordinator: Shengfukung Wenfu coordinator/implementation thread

Target: Shengfukung Wenfu implementation thread

Mode: local prototype implementation/QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Verify the V1 local code path for ECPay as the default online payment method for Taiwan temples, without calling ECPay, changing production/provider configuration, or making a production-readiness claim.

This pass should turn the accepted accounting decision into durable local evidence:

- non-test local/admin online checkout defaults to ECPay unless explicitly overridden;
- test environments can continue using fake checkout by default;
- ECPay checkout creates a pending payment and hosted-payment handoff only;
- ECPay browser return/server callback can move a payment to completed when provider status is completed;
- failed or cancelled ECPay statuses do not count as received;
- no real ECPay request, merchant config mutation, deployment, secrets access, or production data access occurs.

## Required Context

Read before implementation:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-v1-admin-accounting-policy-readiness-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-13-v1-admin-accounting-policy-readiness-eval.md`

## Required Review

Review the current Rails payment code paths:

- provider resolver/default provider behavior;
- admin checkout start;
- account checkout start if relevant;
- checkout service;
- checkout return service;
- ECPay adapter normalization;
- webhook ingest service;
- payment status mapper;
- registration payment sync;
- existing focused tests for checkout, return, webhook, and ECPay adapter behavior.

## Implementation Scope

If evidence is missing, add or adjust focused local tests only. Change production behavior only if a clear local bug is discovered and can be fixed narrowly.

Likely acceptable changes:

- add tests proving ECPay is the non-test default provider and test remains fake by default;
- add tests proving admin checkout uses ECPay by default when the resolver returns ECPay;
- add tests proving ECPay checkout handoff remains pending before provider confirmation;
- add tests proving completed ECPay return/webhook marks the registration paid;
- add tests proving failed/cancelled ECPay signals do not mark the registration paid;
- fix stale test doubles if they no longer match current service interfaces.

## Non-Goals

- Do not call real ECPay.
- Do not add or change real ECPay merchant configuration.
- Do not add ECPay secrets.
- Do not change payment provider production configuration.
- Do not deploy.
- Do not change server configuration.
- Do not access or rotate secrets.
- Do not touch production data.
- Do not add settlement reconciliation.
- Do not add an accounting close/lock state.
- Do not change the accepted V1 payment status set.
- Do not work on mobile or Expo.
- Do not move existing `ops/docs/` history.

## Acceptance Criteria

- Focused local tests prove the default/provider path described above.
- Failed/cancelled ECPay attempts remain non-received and do not mark registrations paid.
- Pending ECPay checkout remains pending until provider confirmation.
- Verification evidence explicitly states that no real ECPay/API/network provider call was made.
- No production-readiness, deployment, provider-configuration, or legal/accounting-finality claim is made.

## Verification

Run focused tests based on touched files. At minimum, run:

```bash
RAILS_ENV=test bin/rails test test/services/payments/checkout_service_test.rb test/services/payments/checkout_return_service_test.rb test/services/payments/status_mapper_test.rb test/services/payment_gateway/ecpay_adapter_test.rb test/integration/admin/payments_flow_test.rb test/integration/api/v1/payment_webhooks_test.rb
```

Also run:

```bash
git diff --check
```

Browser verification is not required unless rendered UI changes.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- reviewed decision/context records;
- implementation summary;
- files changed;
- verification commands and results;
- explicit no-live-ECPay/no-production-data boundary confirmation;
- skipped checks and reasons;
- residual risk;
- follow-up gaps;
- next owner.

Also create matching eval, acceptance, and execution records if the workflow completes.

Do not paste full records in chat when files exist.
