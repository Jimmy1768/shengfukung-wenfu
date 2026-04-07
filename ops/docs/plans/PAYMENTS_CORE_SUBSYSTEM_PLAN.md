# PAYMENTS CORE SUBSYSTEM PLAN

## Purpose

- Track the current state of the provider-agnostic payments subsystem.
- Keep the remaining scope narrow and honest.

## Locked Decisions

- Build and use the shared payments core now.
- Use `ECPay` as the main hosted online payment provider for this Taiwan-only repo.
- Keep `PAYMENTS_PROVIDER=fake` available for tests and dummy local flows.
- Do not depend on LINE Pay or Stripe Connect onboarding for launch.

## What Is Already Built

- Shared orchestration services:
  - `Payments::CheckoutService`
  - `Payments::CheckoutReturnService`
  - `Payments::WebhookIngestService`
  - `Payments::RefundService`
- Shared helper layer:
  - `Payments::CheckoutFlow`
  - `Payments::StatusMapper`
  - `Payments::RegistrationPaymentSync`
- Adapter seam:
  - `PaymentGateway::FakeAdapter`
  - `PaymentGateway::EcpayAdapter`
- Repository seam for payment rows and provider event logs.
- Hosted checkout start/return flow for account and admin.
- Shared webhook ingest endpoint.
- Account payment status polling while pending.
- Failed-payment retry path on the account side.
- Test coverage for checkout, return, webhook, refund, status mapping, and adapter fallbacks.

## Current Status

Completed:
- [x] Provider-agnostic service layer
- [x] Fake adapter end-to-end app wiring
- [x] Hosted checkout return flow
- [x] Webhook replay/idempotency handling
- [x] Payment status transition enforcement
- [x] Account payment refresh and retry UX
- [x] Reference docs and portability manifest

Not in scope right now:
- [ ] Any hosted checkout provider besides ECPay
- [ ] Advanced reconciliation/admin tooling

## Remaining Work

Only keep these as future rollout items:

1. Dummy payment QA
   - Run manual app-level tests against the fake hosted checkout flow.
   - Record expected behavior for account, admin, return, refund, and webhook paths.

2. Real provider validation
   - Validate ECPay with stage credentials.
   - Confirm real callback/signature behavior against ECPay payloads.

3. Optional operator tooling
   - Add admin-side reconcile/recheck actions if real provider edge cases start to matter.

## Done Criteria For This Phase

Treat this phase as complete when:
- fake-provider flows are documented and manually testable
- controllers only use `Payments::*` services
- provider code remains isolated to adapters
- account/admin hosted checkout paths are stable
- remaining provider work is clearly tracked as rollout follow-up, not core architecture work

## Notes

- Migration edits still require explicit approval before implementation.
- Final provider readiness depends on credentials and live callback testing, not on more subsystem reshaping.
