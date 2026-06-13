# Eval Record: ECPay Default Path Local Verification

Eval id: `shengfukung-2026-06-13-ecpay-default-path-local-verification-eval`

Created: 2026-06-13

Evaluator: Shengfukung Wenfu coordinator/implementation thread

Mode: local prototype implementation QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-13-ecpay-default-path-local-verification.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-ecpay-default-path-local-verification-return.md`

## Objective

Evaluate whether the bounded local ECPay default-path verification met the V1 accounting/payment decision set without changing runtime provider behavior or production state.

## Code Evidence

Reviewed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/provider_resolver.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/checkout_service.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/checkout_return_service.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/webhook_ingest_service.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/status_mapper.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payments/registration_payment_sync.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/payment_gateway/ecpay_adapter.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/payments_controller.rb`

Changed:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/payments/provider_resolver_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/payments/checkout_service_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/payments/checkout_return_service_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/api/v1/payment_webhooks_test.rb`

## Evidence Added

- Provider resolver default behavior:
  - test environment defaults to fake;
  - non-test local environments default to ECPay;
  - explicit `PAYMENTS_PROVIDER` overrides still win.
- Checkout service:
  - ECPay checkout creates `payment_method: "ecpay"`;
  - ECPay checkout remains pending before provider confirmation;
  - temple context reaches the resolver/adapter path.
- Checkout return service:
  - ECPay return uses `query_status`;
  - cancelled status maps to failed;
  - cancelled return does not mark the registration paid.
- ECPay webhook integration:
  - completed callback marks payment completed and registration paid;
  - failed callback marks payment failed and registration failed;
  - failed callback does not set `processed_at`;
  - callback response remains `1|OK` after valid signature handling.

## Verification

Initial sandbox command was blocked by PostgreSQL sandbox access.

Escalated local database pre-patch result:

```text
20 runs, 88 assertions, 0 failures, 2 errors, 0 skips
```

Final focused command:

```bash
RAILS_ENV=test bin/rails test test/services/payments/provider_resolver_test.rb test/services/payments/checkout_service_test.rb test/services/payments/checkout_return_service_test.rb test/services/payments/status_mapper_test.rb test/services/payment_gateway/ecpay_adapter_test.rb test/integration/admin/payments_flow_test.rb test/integration/api/v1/payment_webhooks_test.rb
```

Final result:

```text
26 runs, 121 assertions, 0 failures, 0 errors, 0 skips
```

Static check:

```bash
git diff --check
```

Result: pass.

## Browser Evidence

Not applicable. No UI rendering changed.

## Decision

pass_with_gaps

## Remaining Gaps

- This does not prove a real ECPay sandbox merchant round trip.
- Public callback reachability from ECPay was not tested.
- Production credentials/configuration were intentionally not tested.
- Settlement reconciliation remains out of scope.
- Final V1 production promotion remains blocked by the production-boundary decision.
