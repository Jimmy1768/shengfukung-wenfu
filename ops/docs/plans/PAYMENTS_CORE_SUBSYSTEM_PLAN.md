# PAYMENTS CORE SUBSYSTEM PLAN

## Purpose

- Build a reusable provider-agnostic `payments-core` subsystem in TempleMate first.
- Keep current fake/dummy payment flow active for development and staging.
- Prepare a portable seam so the subsystem can be copied into sibling Rails projects (including Golden Template descendants and Combatives) without forcing identical schemas.

## Current Decisions (Locked)

- Reuse existing TempleMate payment tables/models where practical (for this repo).
- Keep core payment domain logic schema-agnostic via a persistence/repository seam.
- Migration changes require explicit user approval before any migration file edits.
  - Pre-deploy projects: rollback/edit is allowed if approved.
  - Deployed projects: additive migrations only.
- Do not start implementation until this plan is reviewed/approved.

## Scope

- Internal subsystem architecture and service boundaries:
  - `Payments::CheckoutService`
  - `Payments::WebhookIngestService`
  - `Payments::RefundService`
- Gateway adapter contract + fake adapter + Stripe-ready scaffold.
- Payment lifecycle/status policy and transition enforcement.
- Idempotency for request execution and webhook ingest.
- Provider event persistence for replay protection and auditing.
- Developer/operator docs for local run and cross-project portability.

## Out of Scope (This Phase)

- Full live Stripe production rollout.
- UI redesign for payment screens.
- Advanced fraud engine implementation (only seam/hooks now).
- Queue/retry orchestration beyond baseline needed by webhook + core flows.

## Architecture Rules

- App/domain code must call `Payments::*` services only.
- Provider SDK calls must be isolated to `PaymentGateway::*Adapter` classes.
- No direct Stripe SDK usage outside adapter layer.
- Core services must not assume `TemplePayment` exists; persistence access goes through a project-local mapper/repository interface.

## Adapter Contract (Target)

Define a shared adapter interface (`PaymentGateway::Adapter`) with normalized return payloads:

- `checkout(intent:, amount_cents:, currency:, metadata:, idempotency_key:)`
  - returns: `provider_checkout_id`, `provider_payment_id` (if available), `status`, `redirect_url`/`client_secret`, `raw`
- `ingest_webhook(payload:, headers:)`
  - verifies signature (if provider supports), parses event, returns normalized event envelope
- `confirm(provider_payment_ref:, amount_cents: nil, currency: nil, metadata: {}, idempotency_key:)`
  - finalizes/acknowledges provider-side payment where required (mandatory for some gateways like LINE Pay)
- `query_status(provider_payment_ref:, metadata: {})`
  - fetches current provider status for reconciliation/callback recovery flows
- `refund(payment_reference:, amount_cents: nil, reason: nil, idempotency_key:)`
  - returns: normalized refund status + provider identifiers
- `cancel(payment_reference:, reason: nil, idempotency_key:)`
  - returns: normalized cancel/void status + provider identifiers

### Adapter Implementations

- `PaymentGateway::FakeAdapter` (fully functional in dev/test/staging)
- `PaymentGateway::StripeAdapter` (scaffold + gated implementation; can remain partial until provider cutover)
- `PaymentGateway::LinePayAdapter` (scaffold in this plan; implementation phase after credential confirmation)

## Provider Capability Matrix (v1 Target)

| Capability | Fake | Stripe | LINE Pay |
| --- | --- | --- | --- |
| Checkout create | Yes | Yes | Yes |
| Confirm step | Optional no-op | Usually no (intent/session handles) | Yes (required flow) |
| Webhook ingest | Simulated | Yes (primary lifecycle source) | Partial/provider-dependent; callback + confirm/query still required |
| Status query | Yes (simulated) | Optional | Yes (important for reconciliation) |
| Refund | Yes | Yes | Yes (subject to provider/account limits) |
| Cancel/Void | Yes | Yes | Yes |
| Signature verification | Bypass allowed in dev/test | Webhook signing secret | LINE request/callback signature scheme |
| Idempotency key passthrough | Yes | Yes | Yes |

Notes:
- `payments-core` must not assume webhook-first lifecycle. Some providers (including LINE Pay patterns) require confirm/query-centric orchestration.
- Normalized internal statuses remain authoritative; provider-specific statuses are mapped in adapters.

## Payment State Machine (Target)

Canonical internal statuses (exact names to finalize during implementation):

- `initiated`
- `pending`
- `authorized`
- `succeeded`
- `failed`
- `canceled`
- `refunded` (partial/full detail in metadata)

Allowed transitions (baseline):

- `initiated -> pending|failed|canceled`
- `pending -> authorized|succeeded|failed|canceled`
- `authorized -> succeeded|canceled|failed`
- `succeeded -> refunded` (or partially refunded metadata state)
- terminal: `failed`, `canceled`, `refunded` (no backward transition)

Rules:

- Reject invalid transitions server-side.
- Persist transition attempts in audit metadata/logs.
- Never store sensitive card data in app records/logs.

## Idempotency Strategy

### Request-side

- Every checkout/refund/cancel call requires a deterministic idempotency key.
- Enforce unique processing by business intent key (e.g., registration/order + action type).

### Webhook-side

- Persist provider webhook event identity (`event_id` + provider) in event store.
- Ignore already-seen events safely (replay idempotency).
- Keep raw payload hash/metadata for audit and debugging.

### Duplicate Intent Prevention

- Prevent duplicate successful payment records for same business intent when prior payment is already in terminal success state (policy to finalize per intent type).

## Fraud/Misuse Hooks (Seam Only)

- Add policy hook point before checkout execution:
  - velocity checks
  - deny/allow rules
  - future risk scoring integration
- Default behavior now: pass-through unless explicit rule configured.

## Environment Strategy

- Default provider in `development` and `test`: fake adapter.
- Staging may use fake by default unless explicitly switched.
- Stripe activation must be explicit via env configuration.
- LINE Pay activation must be explicit via env configuration and enabled only after merchant credentials are validated.
- Provider selection should be centralized (resolver/factory), not conditionals scattered across services.

### Environment Variables (Planned)

Shared:

- `PAYMENTS_PROVIDER` (`fake|stripe|line_pay`)
- `PAYMENTS_IDEMPOTENCY_WINDOW_SECONDS` (optional)

Stripe:

- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `STRIPE_PUBLISHABLE_KEY` (client-side surfaces if needed)

LINE Pay:

- `LINE_PAY_CHANNEL_ID`
- `LINE_PAY_CHANNEL_SECRET`
- `LINE_PAY_API_BASE`
- `LINE_PAY_CONFIRM_BASE_URL` (if flow requires explicit return/confirm URL composition)

Policy:

- Dev/test default to `fake` unless explicitly overridden.
- Missing provider credentials must fail closed (clear startup/runtime error), not silently downgrade in production.

## Persistence Strategy (TempleMate + Portability)

- TempleMate implementation can map to current models/tables (e.g., `TemplePayment` + provider event records).
- Introduce a small repository/mapper seam so sibling projects can adapt to different schemas without rewriting core orchestration logic.
- Document required fields/contracts for portable persistence adapter.

## Phased Checklist

### Phase 0 — Discovery + Reuse/Replace Decision

- [ ] Audit current payment code paths/models/services/controllers.
- [ ] Write short reuse-vs-replace decision notes in this plan.
- [ ] Identify exact seam points for adapter + persistence abstraction.

### Phase 1 — Core Service + Adapter Boundary

- [ ] Create/confirm `Payments::CheckoutService`.
- [ ] Create/confirm `Payments::WebhookIngestService`.
- [ ] Create/confirm `Payments::RefundService`.
- [ ] Create `PaymentGateway::Adapter` contract.
- [ ] Implement `PaymentGateway::FakeAdapter`.
- [ ] Scaffold `PaymentGateway::StripeAdapter` behind provider gating.
- [ ] Add `PaymentGateway::LinePayAdapter` scaffold behind provider gating.

### Phase 2 — State Machine + Idempotency

- [ ] Enforce internal status transition matrix.
- [ ] Add request idempotency key handling.
- [ ] Add provider webhook event dedupe store + replay ignore behavior.
- [ ] Add duplicate business-intent payment guardrails.

### Phase 3 — Safety + Audit Baseline

- [ ] Webhook signature verification seam (fake bypass; Stripe verify path).
- [ ] Structured, audit-friendly metadata/logging (no PCI-sensitive fields).
- [ ] Failure handling paths documented for operator recovery.

### Phase 4 — Test Coverage (Fake End-to-End)

- [ ] Checkout success path test.
- [ ] Checkout failure path test.
- [ ] Webhook replay duplicate ignored test.
- [ ] Invalid state transition blocked test.
- [ ] Refund/cancel path tests.
- [ ] Record exact commands and pass/fail results in this plan.

### Phase 5 — Reference Documentation

- [ ] Add `ops/docs/reference/platform_payments.md`.
- [ ] Document architecture (text diagram), adapter contract, and payload examples.
- [ ] Document lifecycle table, idempotency rules, env vars, and local runbook.
- [ ] Add failure scenarios + recovery playbooks.
- [ ] Add portability checklist for copying into Combatives/sibling apps.

### Phase 6 — Provider Rollout Sequence

- [ ] Phase A provider: Fake adapter complete and default in dev/test.
- [ ] Phase B provider: Stripe adapter integrated end-to-end using test account.
- [ ] Phase C provider: LINE Pay adapter integrated after merchant credential validation.
- [ ] Phase D provider(s): optional additional gateways (e.g., Alipay) via same adapter contract.

## Done Criteria

- Core app payment flows call `Payments::*` services only.
- Provider-specific logic is fully isolated to adapter layer.
- Fake adapter remains default in dev/test unless explicitly overridden.
- Webhook ingest and request flows are idempotent with verified replay handling.
- State transition policy is enforced and covered by tests.
- Plan + reference docs are updated with actual implementation outcomes.
- Portable file manifest is produced for low-risk copy into sibling projects.

Provider-specific completion:

- Stripe-ready:
  - [ ] Checkout + webhook + refund/cancel working in test mode
  - [ ] Signature verification active
  - [ ] Replay/idempotency tests passing
- LINE Pay-ready:
  - [ ] Checkout + confirm + query_status working
  - [ ] Callback/signature verification flow verified
  - [ ] Replay/idempotency + reconciliation tests passing

## Migration Governance (Must Follow)

- No migration edits without explicit user approval.
- If migration changes are approved:
  - pre-deploy repo: rollback/edit may be used to keep schema history tidy
  - deployed repo: additive migrations only
- Record migration decisions in this plan before applying changes.

## Implementation Hold

- Build is intentionally paused at planning stage pending user review.
