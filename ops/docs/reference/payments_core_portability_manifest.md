# Payments Core Portability Manifest
Last updated: 2026-03-01

## Purpose
- Provide a concrete copy/adapt manifest for porting the payments-core subsystem into sibling Rails projects.
- Keep schema portability explicit: migrations and model/table names are project-specific.

## Source Baseline
- Source repo: `shenfukung-wenfu`
- Recommended process:
  1. Freeze a source SHA before export.
  2. Copy files in this manifest from that SHA only.
  3. Adapt target persistence/model wiring after copy.

## Migration + Schema Policy (Confirmed)
- Migration/schema portability is intentional.
- See [deployment_notes.md](/Users/jimmy1768/Projects/shenfukung-wenfu/ops/docs/reference/deployment_notes.md:149):
  - Use generic resource names in docs/contracts (`payments_transactions`, `payments_provider_events`).
  - Map to project-domain models/tables in each target repo.
  - Keep payment-core schema optional and onboarding-phase driven.

## Docs Package (Copy First)
- [platform_payments.md](/Users/jimmy1768/Projects/shenfukung-wenfu/ops/docs/reference/platform_payments.md)
- [PAYMENTS_CORE_SUBSYSTEM_PLAN.md](/Users/jimmy1768/Projects/shenfukung-wenfu/ops/docs/plans/PAYMENTS_CORE_SUBSYSTEM_PLAN.md)
- [deployment_notes.md](/Users/jimmy1768/Projects/shenfukung-wenfu/ops/docs/reference/deployment_notes.md)

## Code Manifest

### Copy As-Is (Core Infra)
- `rails/app/services/payment_gateway/adapter.rb`
- `rails/app/services/payment_gateway/fake_adapter.rb`
- `rails/app/services/payment_gateway/stripe_adapter.rb`
- `rails/app/services/payment_gateway/line_pay_adapter.rb`
- `rails/app/services/payments/provider_resolver.rb`
- `rails/app/services/payments/checkout_service.rb`
- `rails/app/services/payments/webhook_ingest_service.rb`
- `rails/app/services/payments/refund_service.rb`
- `rails/app/services/payments/status_transition_policy.rb`

### Adapt Required (Project Persistence + Domain Mapping)
- `rails/app/services/payments/repositories/payment_repository.rb`
  - Replace `TemplePayment` persistence assumptions with target transaction model/table.
- `rails/app/services/payments/repositories/payment_event_log_repository.rb`
  - Replace `PaymentWebhookLog` persistence assumptions with target provider-event model/table.
- `rails/app/models/temple_payment.rb`
  - Either port as compatibility model or map service/repository logic to target model.
- `rails/app/models/payment_webhook_log.rb`
  - Either port as compatibility model or map to target event-log model.
- `rails/app/services/payments/checkout_service.rb`
- `rails/app/services/payments/webhook_ingest_service.rb`
- `rails/app/services/payments/refund_service.rb`
- `rails/app/services/payments/status_transition_policy.rb`
  - These service files are mostly identical infra plumbing, but they reference:
  - `TemplePayment::STATUSES`
  - `TemplePayment::PAYMENT_METHODS`
  - `TempleRegistration::PAYMENT_STATUSES`
  - If target constants differ, add a compatibility shim or update these references.

### Required HTTP Entry Points
- `rails/app/controllers/api/v1/payment_webhooks_controller.rb`
- `rails/config/routes.rb`
  - Ensure route exists: `POST /api/v1/payments/webhooks/:provider`

### Optional but Commonly Ported (UI/Reporting Integration)
- `rails/app/controllers/admin/payments_controller.rb`
- `rails/app/controllers/account/payments_controller.rb`
- `rails/app/controllers/api/v1/account/payment_statuses_controller.rb`
- `rails/app/views/admin/payments/index.html.erb`
- `rails/app/views/admin/payments/new.html.erb`
- `rails/app/views/admin/payments/_ledger_table.html.erb`
- `rails/app/views/account/payments/index.html.erb`
- `rails/app/views/account/registrations/payment.html.erb`
- `rails/app/serializers/account/api/payment_status_serializer.rb`
- `rails/app/services/payments/cash_payment_recorder.rb`
- `rails/app/services/payments/temple_registration_builder.rb`
- `rails/app/services/reporting/payment_summary.rb`
- `rails/app/services/reporting/payments_csv_exporter.rb`

## Test Manifest

### Must Port (Core Contract Safety)
- `rails/test/services/payments/checkout_service_test.rb`
- `rails/test/services/payments/webhook_ingest_service_test.rb`
- `rails/test/services/payments/refund_service_test.rb`
- `rails/test/services/payments/status_transition_policy_test.rb`
- `rails/test/services/payment_gateway/stripe_adapter_test.rb`
- `rails/test/services/payment_gateway/line_pay_adapter_test.rb`

### Port If Feature Surfaces Are Included
- `rails/test/integration/api/v1/payment_webhooks_test.rb`
- `rails/test/integration/admin/payments_flow_test.rb`
- `rails/test/integration/account/registration_payment_flow_test.rb`
- `rails/test/models/temple_payment_test.rb`
- `rails/test/services/payments/cash_payment_recorder_test.rb`
- `rails/test/services/reporting/payment_summary_test.rb`
- `rails/test/services/reporting/payments_csv_exporter_test.rb`

## Environment Contract (Target Repo)
- `PAYMENTS_PROVIDER=fake|stripe|line_pay`
- `PAYMENTS_IDEMPOTENCY_WINDOW_SECONDS` (optional)
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PUBLISHABLE_KEY`
- `LINE_PAY_CHANNEL_ID`
- `LINE_PAY_CHANNEL_SECRET`
- `LINE_PAY_API_BASE`
- `LINE_PAY_CONFIRM_BASE_URL`

## Porting Sequence (Recommended)
1. Copy docs package and core infra files.
2. Implement/adjust persistence repositories for target schema.
3. Wire webhook controller + route.
4. Set `PAYMENTS_PROVIDER=fake` and run core service tests.
5. Port optional UI/reporting files if target project needs those surfaces.
6. Add provider credentials later and run Stripe/LINE validation.

## Current Rollout Decision
- Approved build strategy: finish the shared payments-core architecture first with `PAYMENTS_PROVIDER=fake`.
- Do not block subsystem implementation on owning a real or sandbox LINE Pay account.
- Treat LINE Pay credential-based verification as the final provider rollout gate after the app is already wired end-to-end with the fake adapter.

## Acceptance Gates Before Marking Port Complete
- `Payments::*` services are the only orchestration path used by controllers/jobs.
- No direct provider SDK calls outside `PaymentGateway::*Adapter`.
- Webhook replay dedupe works in target event-log persistence.
- Invalid transition enforcement works with target status constants.
- Fake-provider test suite passes in target repo before real provider rollout.
