# Platform Payments Reference

## Purpose

- Describe the payment architecture that now exists in this repo.
- Keep future provider work constrained to adapter-level changes.

## Current Build

The app now has a provider-agnostic payments core.

Main service entrypoints:
- `Payments::CheckoutService`
- `Payments::CheckoutReturnService`
- `Payments::WebhookIngestService`
- `Payments::RefundService`

Shared helpers:
- `Payments::CheckoutFlow`
- `Payments::StatusMapper`
- `Payments::RegistrationPaymentSync`

Provider boundary:
- `PaymentGateway::FakeAdapter`
- `PaymentGateway::EcpayAdapter`

Persistence boundary:
- `Payments::Repositories::PaymentRepository`
- `Payments::Repositories::PaymentEventLogRepository`

## Important Runtime Behavior

- Controllers call `Payments::*` services instead of writing provider logic inline.
- Hosted checkout can start from both account and admin surfaces.
- Hosted providers can return into the app through dedicated return endpoints.
- Payment webhooks are ingested through a shared provider endpoint.
- Pending account payments can refresh on-page through the payment status API.
- Failed account payments now expose a retry path.

## Active Routes

Account:
- `POST /account/registrations/:id/start_checkout`
- `GET /account/registrations/:id/checkout_return`
- `GET /api/v1/account/payment_statuses/:reference`

Admin:
- `POST /admin/payments/start_checkout?registration_id=:id`
- `GET /admin/payments/checkout_return?registration_id=:id`

Webhook:
- `POST /api/v1/payments/webhooks/:provider`

## Status Model

Canonical internal statuses:
- `pending`
- `completed`
- `failed`
- `refunded`

Transition policy:
- `pending -> pending|completed|failed`
- `completed -> completed|refunded`
- `failed -> failed`
- `refunded -> refunded`

## Provider Strategy

- Provider selection is **per-tenant**, not a single global env-var switch. `Payments::ProviderResolver` (`rails/app/services/payments/provider_resolver.rb`) resolves the provider with this precedence: explicit argument → `temple.payment_provider_settings["patron_checkout_provider"]` → the `PAYMENTS_PROVIDER` env var (now a compatibility fallback default only, not the source of truth).
- A tenant's `patron_checkout_provider` setting can also be `"cash_only"`, which disables online checkout entirely for that temple (`ProviderResolver.online_checkout_available?` returns `false`) rather than selecting an adapter. Shengfukung's tenant config is deliberately set to `fake` (test checkout), not `cash_only` or `ecpay`.
- `PAYMENTS_PROVIDER=ecpay` remains the env-var fallback default for deployed temple environments that haven't set a tenant-level override; `PAYMENTS_PROVIDER=fake` remains useful in automated tests and local dummy-flow development.
- ECPay is the only supported hosted online payment rail in this repo's Taiwan deployment model.
- **ECPay wire-amount contract:** ECPay's `TotalAmount` (request) and `TradeAmt` (callback) fields are positive whole TWD integers, while Wenfu stores all payment amounts internally in minor-unit cents (`amount_cents`). `Payments::Taiwan::EcpayAmount` (`rails/app/lib/payments/taiwan/ecpay_amount.rb`) is the single conversion point: `.to_wire!(amount_cents:, currency:)` divides by 100 for outbound requests, `.from_wire!(amount:, currency:)` multiplies by 100 for inbound callbacks, and both raise `InvalidAmount`/`InvalidCurrency` rather than silently truncating. This exists because an earlier version of the adapter passed internal cents directly into `TotalAmount` — a real transaction would have been serialized as 100x the intended amount (e.g. NT$50 as `5000`). Any future ECPay-adjacent code must go through this class rather than reading/writing `amount_cents` directly against ECPay fields.
- Cash/manual payment rows remain supported.
- Stripe is not used here for hosted checkout or Connect onboarding; any Stripe platform-fee notes live only in temple payment settings for internal operations.

## Local Validation

Typical focused payment test command:

```bash
cd rails && bin/rails test \
  test/services/payments/checkout_flow_test.rb \
  test/services/payments/checkout_return_service_test.rb \
  test/services/payments/status_mapper_test.rb \
  test/services/payments/registration_payment_sync_test.rb \
  test/services/payments/checkout_service_test.rb \
  test/services/payments/webhook_ingest_service_test.rb \
  test/services/payments/refund_service_test.rb \
  test/services/payment_gateway/ecpay_adapter_test.rb \
  test/integration/account/registration_payment_flow_test.rb \
  test/integration/admin/payments_flow_test.rb \
  test/integration/api/v1/payment_webhooks_test.rb \
  test/integration/account/api/payment_statuses_test.rb
```

## Remaining External Work

- real ECPay stage validation with temple-specific credentials
- production ECPay onboarding and callback verification
- manual ops testing of hosted checkout and cash/manual fallbacks

## Temple-Facing Payment Semantics

Distilled 2026-09-03 from `docs/operator/workflows/` before that tree was
deleted. These were decided 2026-06-13 and recorded nowhere else.

- **ECPay is the default online payment method for Taiwan temples.** Provider
  changes in production stay gated by the authorization boundary in
  `ops/protocol/repo_context.md`.
- **Cash is an admin-attested receipt event, not an externally controlled
  one.** The system trusts the admin pressing *Received* and audits it:
  admin identity and timestamp are preserved. Nothing outside the product
  confirms a cash payment, so the audit trail is the control.
- **Monthly accounting export runs on the 1st of each month**, covering the
  previous calendar month in the temple's local timezone, handed to external
  accounting as CSV.
- **There is no in-app accounting close or lock state.** The monthly close is
  external and manual, supported by filters plus CSV export. Deliberate, not
  an omission — see the non-requirements the V1 threshold set out.

## Provider Activation Gates

Two provider tracks are deliberately not active, for different reasons:

- **Stripe** is deferred by Director choice, not blocked by anything
  technical. Sandbox work can begin whenever the Director decides it should.
- **Live ECPay** is externally blocked: it requires a real client supplying
  a legally usable merchant account plus target-specific authority. No
  amount of local work removes that gate, which is why local completion of
  the payment phases does not imply readiness to transact.

Local completion authorizes none of: provider inspection, credential access,
live payment or refund, production action, deployment, or push. Those are
separately authorized, per action.
