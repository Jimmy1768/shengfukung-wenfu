# Platform Payments Reference
Last updated: 2026-03-01

## Purpose
- Define the reusable `payments-core` architecture implemented in this repo.
- Keep provider logic isolated so future adapters (Stripe, LINE Pay, Alipay, etc.) can be added without rewriting domain flows.
- Provide a copy/port checklist for sibling Rails projects that use different table/model names.

## Architecture (Text Diagram)
```text
Controller / job / webhook endpoint
        |
        v
Payments::* service entrypoints
  - CheckoutService
  - WebhookIngestService
  - RefundService
        |
        +--> Payments::ProviderResolver
        |        |
        |        v
        |    PaymentGateway::*Adapter
        |      - FakeAdapter
        |      - StripeAdapter (scaffold)
        |      - LinePayAdapter (scaffold)
        |
        +--> Payments::Repositories::*
                 - PaymentRepository
                 - PaymentEventLogRepository
                 (project-specific persistence seam)
```

## Core Service Responsibilities
- `Payments::CheckoutService`
  - validates required keys (`idempotency_key`, `intent_key`)
  - enforces idempotency + duplicate-intent guard
  - creates pending payment via repository
  - executes provider checkout through adapter
  - maps provider status to internal status
- `Payments::WebhookIngestService`
  - ingests provider webhook payloads through adapter
  - writes provider event log with dedupe guard
  - enforces signature validity (fail-closed for non-fake providers)
  - applies payment status update when payment reference is found
- `Payments::RefundService`
  - supports `operation: :refund` and `operation: :cancel`
  - requires idempotency key
  - updates canonical payment status through repository

## Adapter Contract
All adapters implement `PaymentGateway::Adapter`.

Required methods:
- `verify_webhook_signature(payload:, headers:)`
- `checkout(intent:, amount_cents:, currency:, metadata:, idempotency_key:)`
- `ingest_webhook(payload:, headers:)`
- `confirm(provider_payment_ref:, amount_cents: nil, currency: nil, metadata: {}, idempotency_key:)`
- `query_status(provider_payment_ref:, metadata: {})`
- `refund(payment_reference:, amount_cents: nil, reason: nil, idempotency_key:)`
- `cancel(payment_reference:, reason: nil, idempotency_key:)`

### Normalized payload examples
Checkout response:
```ruby
{
  status: "pending",
  provider_checkout_id: "chk_123",
  provider_payment_id: "pay_123",
  provider_reference: "pay_123",
  redirect_url: nil,
  raw: { ... }
}
```

Webhook ingest response:
```ruby
{
  event_type: "payment.updated",
  provider_event_id: "evt_123",
  provider_reference: "pay_123",
  status: "completed",
  signature_valid: true,
  signature_reason: "header_and_secret_present",
  raw: { payload: ..., headers: ... }
}
```

Refund/cancel response:
```ruby
{
  status: "refunded", # or "canceled"
  provider_reference: "pay_123",
  raw: { ... }
}
```

Stripe checkout modes supported by adapter:
- `payment_intent`:
  - intended for Expo/native in-app payment sheets
  - returns `client_secret`
- `checkout_session`:
  - intended for web/account redirect flow
  - returns `redirect_url`
  - requires `success_url` + `cancel_url` in metadata

LINE Pay adapter capabilities:
- `checkout` via `/v3/payments/request`
- `confirm` via `/v3/payments/{transactionId}/confirm`
- `query_status` via `/v3/payments/requests/{orderId}/check`
- `refund` via `/v3/payments/{transactionId}/refund`
- `cancel` currently mapped to refund behavior for parity
- webhook/callback signature check uses `x-line-signature` against raw request body HMAC

## Internal Status Lifecycle
Current canonical statuses:
- `pending`
- `completed`
- `failed`
- `refunded`

Transition policy (`Payments::StatusTransitionPolicy`):
- `pending -> pending|completed|failed`
- `completed -> completed|refunded`
- `failed -> failed`
- `refunded -> refunded`

Invalid transitions raise `Payments::StatusTransitionPolicy::InvalidTransition`.

## Idempotency + Replay Rules
- Request idempotency:
  - checkout/refund require `idempotency_key`
  - repeated checkout with same idempotency key reuses existing payment
- Business intent dedupe:
  - checkout blocks duplicate successful charge intent via `intent_key`
- Webhook replay dedupe:
  - `PaymentEventLogRepository` rejects duplicate provider events by (`provider`, `provider_event_id`)
  - duplicate webhook returns `duplicate: true` with no payment mutation

## Safety and Audit Rules
- Webhook signature verification:
  - fake: bypass allowed
  - stripe/line: fail closed when required signature header/secret is missing
- Audit payload sanitization:
  - sensitive fields are redacted (`secret`, `token`, `authorization`, `card`, `cvv`, etc.)
  - `_raw_body` is excluded from event payload storage
- Processing errors:
  - persisted and truncated to safe length (`500` chars)
- Never persist raw PCI/card data in app records.

## Environment Variables
Shared:
- `PAYMENTS_PROVIDER=fake|stripe|line_pay`
- `PAYMENTS_IDEMPOTENCY_WINDOW_SECONDS` (optional policy window)

Stripe:
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PUBLISHABLE_KEY`

LINE Pay:
- `LINE_PAY_CHANNEL_ID`
- `LINE_PAY_CHANNEL_SECRET`
- `LINE_PAY_API_BASE`
- `LINE_PAY_CONFIRM_BASE_URL`

Policy:
- default to `fake` in development/test
- production must fail closed if required provider credentials are missing

## Local Runbook
1. Ensure provider:
   - set `PAYMENTS_PROVIDER=fake` in local env for deterministic tests.
2. Run focused payment-core tests:
```bash
cd rails && bin/rails test \
  test/services/payments/status_transition_policy_test.rb \
  test/services/payments/checkout_service_test.rb \
  test/services/payments/webhook_ingest_service_test.rb \
  test/services/payments/refund_service_test.rb
```
3. Validate no uncommitted files after edits:
```bash
git status --short
```

## Common Failures + Recovery
- Invalid webhook signature:
  - Symptom: `InvalidWebhookSignature` and event log `processed=false`.
  - Action: fix provider secret/header configuration, then replay webhook from provider dashboard.
- Duplicate webhook:
  - Symptom: service returns `duplicate: true`.
  - Action: no mutation needed unless provider and app states diverge.
- Transition blocked:
  - Symptom: `InvalidTransition` error.
  - Action: inspect payment current state + provider truth; reconcile via controlled update script/admin operation.
- Missing provider credentials:
  - Symptom: adapter verification fails (invalid signature reason includes missing secret).
  - Action: populate env vars and restart app worker/web processes.

## Portability Checklist (Siblings / Combatives)
Use this checklist when porting to another Rails app with different schema names.

Canonical file manifest for copy/adapt scope:
- `ops/docs/reference/payments_core_portability_manifest.md`

1. Copy core files:
   - `rails/app/services/payment_gateway/*`
   - `rails/app/services/payments/checkout_service.rb`
   - `rails/app/services/payments/webhook_ingest_service.rb`
   - `rails/app/services/payments/refund_service.rb`
   - `rails/app/services/payments/status_transition_policy.rb`
2. Replace repository adapters only:
   - implement project-specific `PaymentRepository`
   - implement project-specific `PaymentEventLogRepository`
3. Map model/table fields:
   - canonical transaction table (generic: `payments_transactions`)
   - provider event table (generic: `payments_provider_events`)
4. Add provider env vars in target project config.
5. Add/update tests in target repo for:
   - checkout success/failure
   - webhook duplicate replay
   - transition block
   - refund/cancel
6. Keep controller boundary:
   - controllers/jobs/webhooks call `Payments::*` services only
   - no direct provider SDK calls outside adapters
