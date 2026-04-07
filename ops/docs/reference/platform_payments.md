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

- `PAYMENTS_PROVIDER=ecpay` is the intended hosted checkout default for deployed temple environments.
- `PAYMENTS_PROVIDER=fake` remains useful in automated tests and local dummy-flow development.
- ECPay is the only supported hosted online payment rail in this repo’s Taiwan deployment model.
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
