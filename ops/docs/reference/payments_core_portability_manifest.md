# Payments Core Portability Manifest

## Purpose

- Define the smallest useful copy/adapt package for moving `payments-core` into another Rails app.
- Keep schema and model names explicitly project-specific.

## Copy First

Docs:
- `ops/docs/reference/platform_payments.md`
- `ops/docs/plans/PAYMENTS_CORE_SUBSYSTEM_PLAN.md`

Core provider boundary:
- `rails/app/services/payment_gateway/adapter.rb`
- `rails/app/services/payment_gateway/fake_adapter.rb`
- `rails/app/services/payment_gateway/stripe_adapter.rb`
- `rails/app/services/payment_gateway/line_pay_adapter.rb`

Core orchestration:
- `rails/app/services/payments/provider_resolver.rb`
- `rails/app/services/payments/checkout_service.rb`
- `rails/app/services/payments/checkout_return_service.rb`
- `rails/app/services/payments/webhook_ingest_service.rb`
- `rails/app/services/payments/refund_service.rb`
- `rails/app/services/payments/checkout_flow.rb`
- `rails/app/services/payments/status_mapper.rb`
- `rails/app/services/payments/registration_payment_sync.rb`
- `rails/app/services/payments/status_transition_policy.rb`

## Adapt In The Target App

Persistence:
- `rails/app/services/payments/repositories/payment_repository.rb`
- `rails/app/services/payments/repositories/payment_event_log_repository.rb`

Project models/constants:
- `rails/app/models/temple_payment.rb`
- `rails/app/models/payment_webhook_log.rb`
- any registration/order model references used by `RegistrationPaymentSync`

HTTP entry points:
- `rails/app/controllers/api/v1/payment_webhooks_controller.rb`
- `rails/config/routes.rb`

Optional UI surfaces:
- account/admin payment controllers and views
- payment status serializer/API
- reporting/export code

## Required Contract In The Target App

- controllers and jobs call `Payments::*` services only
- provider SDK/API calls stay inside `PaymentGateway::*Adapter`
- target persistence supports payment lookup, status updates, and webhook event dedupe
- target app preserves the canonical internal statuses:
  - `pending`
  - `completed`
  - `failed`
  - `refunded`

## Porting Sequence

1. Copy the docs and core service/adapter files.
2. Rewire the repository layer to the target schema.
3. Add the webhook endpoint and hosted checkout routes needed by the target app.
4. Run the target repo with `PAYMENTS_PROVIDER=fake` first.
5. Only after fake flows pass, add real provider credentials.

## Current Rollout Decision

- The approved path is still: build and port the subsystem with `PAYMENTS_PROVIDER=fake` first.
- Real LINE Pay access is not required for the architecture or app wiring phase.
- Real provider validation remains the final rollout gate.
