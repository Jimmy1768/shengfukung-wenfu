# Return: ECPay Default Path Local Verification

Handoff id: `shengfukung-2026-06-13-ecpay-default-path-local-verification`

Created: 2026-06-13

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

## Objective

Verify the V1 local code path for ECPay as the default online payment method for Taiwan temples without calling ECPay, changing provider configuration, or making a production-readiness claim.

## Reviewed Context Records

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-v1-admin-accounting-policy-readiness-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-13-v1-admin-accounting-policy-readiness-eval.md`

## Result

Completed with accepted gaps.

The local ECPay default path now has focused test evidence:

- test environment still defaults to fake checkout;
- non-test local environments default to ECPay when `PAYMENTS_PROVIDER` is unset;
- explicit `PAYMENTS_PROVIDER` overrides still win;
- ECPay checkout creates an ECPay pending payment and passes temple context into the adapter path;
- ECPay checkout return uses query-status reconciliation, not confirmation mutation;
- cancelled ECPay return maps to failed and does not mark the registration paid;
- valid failed ECPay server callback maps to failed, returns `1|OK`, and does not set `processed_at`.

## Implementation Summary

- Added `Payments::ProviderResolverTest` for default provider behavior.
- Fixed the `CheckoutServiceTest` fake resolver signature to match the current service contract.
- Added a checkout service assertion proving ECPay starts as pending before provider confirmation.
- Added an ECPay cancelled-return assertion proving it remains non-received.
- Added an ECPay failed-webhook assertion proving failed provider status remains non-received.
- No runtime payment behavior changed.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-13-ecpay-default-path-local-verification.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-ecpay-default-path-local-verification-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-13-ecpay-default-path-local-verification-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-13-ecpay-default-path-local-verification-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-13-ecpay-default-path-local-verification-execution.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/payments/provider_resolver_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/payments/checkout_service_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/services/payments/checkout_return_service_test.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/test/integration/api/v1/payment_webhooks_test.rb`

## Verification

Initial command:

```bash
RAILS_ENV=test bin/rails test test/services/payments/checkout_service_test.rb test/services/payments/checkout_return_service_test.rb test/services/payments/status_mapper_test.rb test/services/payment_gateway/ecpay_adapter_test.rb test/integration/admin/payments_flow_test.rb test/integration/api/v1/payment_webhooks_test.rb
```

Sandbox result:

```text
blocked by local PostgreSQL sandbox restriction: Operation not permitted.
```

Escalated local database rerun result before patch:

```text
20 runs, 88 assertions, 0 failures, 2 errors, 0 skips
```

Errors were both stale test-double signature mismatches in `Payments::CheckoutServiceTest`, where the fake resolver did not accept the real `temple:` keyword.

Final command:

```bash
RAILS_ENV=test bin/rails test test/services/payments/provider_resolver_test.rb test/services/payments/checkout_service_test.rb test/services/payments/checkout_return_service_test.rb test/services/payments/status_mapper_test.rb test/services/payment_gateway/ecpay_adapter_test.rb test/integration/admin/payments_flow_test.rb test/integration/api/v1/payment_webhooks_test.rb
```

Final result:

```text
26 runs, 121 assertions, 0 failures, 0 errors, 0 skips
```

Command:

```bash
git diff --check
```

Result: pass.

## Browser Evidence

Browser verification was not run because this pass changed payment tests and OperatorKit records only. No rendered admin or account UI changed.

## Boundary Confirmation

- No runtime payment code changed.
- No real ECPay call was made.
- No ECPay merchant configuration was added or changed.
- No secrets were accessed or rotated.
- No production data was touched.
- No deployment or server configuration changed.
- No payment provider production configuration changed.
- No settlement reconciliation, close/lock state, or new payment status was added.
- Vue: not touched.
- Expo/mobile: not touched.
- Existing `ops/docs/`: not touched.

## Residual Risk

- This is local code-path verification, not real ECPay sandbox merchant acceptance.
- It does not prove production credentials, ECPay account readiness, callback reachability from the public internet, or settlement reconciliation.
- It does not replace the final V1 real temple/admin rehearsal required by the production-boundary decision.

## Follow-Up Gaps

- Previous-month accounting export needs explicit admin/browser rehearsal for the V1 monthly process.
- Comprehensive V1 help guide remains pending after behavior settles.
- Real temple admin/staff rehearsal remains required before production promotion.
- Production promotion remains blocked until the production-boundary decision is satisfied.

## Next Owner

Coordinator/implementation thread should create matching eval, acceptance, and execution records, commit and push this checkpoint, then continue to the previous-month export rehearsal gap.
