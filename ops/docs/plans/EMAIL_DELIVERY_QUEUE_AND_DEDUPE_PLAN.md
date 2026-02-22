# EMAIL DELIVERY QUEUE + DEDUPE PLAN

## Purpose

- Move feature email sending from synchronous request-cycle delivery to queued delivery (Sidekiq/workers).
- Add dedupe/idempotency controls at the email dispatch layer for better reliability and abuse resistance.
- Improve retry behavior, observability, and operational control for outbound email.

## Why This Exists

- Synchronous email send is acceptable for Phase 1 features, but it has limits:
  - request latency depends on network/provider
  - fewer retry options
  - harder to dedupe accidental duplicates cleanly
  - less centralized delivery control
- Multiple features will eventually send email (Contact Temple, notifications, reminders, alerts).

## Scope

- Queued email dispatch via Sidekiq worker(s)
- Delivery orchestration and retries
- Dedupe / idempotency for duplicate sends
- Structured delivery logging and failure handling

## Out of Scope (Initial Version)

- Full user-facing message center/inbox
- Provider failover (multiple email vendors)
- Per-recipient delivery analytics dashboard

## Product Direction

- Phase 1 features may ship synchronous sends behind a service boundary.
- Queue migration should preserve controller/API contracts.
- Dedupe belongs in the dispatch/enqueue layer, not in each controller.

## Dedupe / Idempotency (Target)

### What Dedupe Solves

- Double-submit clicks
- Retries causing duplicate sends
- Replayed requests
- Bursts of identical payloads from the same user in a short window

### Candidate Dedupe Key Inputs

- feature/event key (e.g., `contact_temple`)
- recipient(s)
- user id (if applicable)
- temple slug / tenant
- normalized subject/body hash
- time bucket (for soft dedupe windows)

### Dedupe Outcomes

- suppress duplicate send and return success-like result
- enqueue once and reuse existing job/delivery reference
- log duplicate suppression reason for auditing

## Queue Architecture (Target)

- Controller -> feature service -> email dispatch service -> enqueue worker
- Worker -> provider adapter (`Notifications::BrevoClient`) via delivery service
- Delivery result logged consistently (success/failure/retry/suppressed)

## Phased Rollout

### Phase A: Queue Boundary Standardization

- [ ] Audit current synchronous email send paths.
- [ ] Ensure feature code uses service boundaries (no direct provider calls in controllers).
- [ ] Define a shared email dispatch interface for sync + async compatibility.

### Phase B: Sidekiq Delivery Path

- [ ] Add/standardize email dispatch worker(s).
- [ ] Move selected feature sends (starting with `Contact Temple`) to enqueue-based flow.
- [ ] Preserve user-facing success/failure UX semantics (accepted vs delivered).

### Phase C: Dedupe / Idempotency

- [ ] Define dedupe key strategy by feature type.
- [ ] Implement short-window duplicate suppression for exact payload repeats.
- [ ] Add structured logs/metrics for dedupe hits and suppressions.

### Phase D: Retry + Failure Handling

- [ ] Add retry strategy and error classification (transient vs permanent).
- [ ] Add dead-letter/failed-job visibility (or equivalent operational workflow).
- [ ] Add alerts for repeated delivery failures by feature/provider.

### Phase E: Feature Adoption

- [ ] Migrate `Contact Temple` send path from synchronous to queued delivery.
- [ ] Evaluate migration for notification fan-out flows and reminders.
- [ ] Document feature integration checklist for future email-capable features.

## Contact Temple Integration (Immediate Relevance)

- Phase 1: synchronous send is acceptable.
- Dedupe decision for Contact Temple is deferred to this plan’s Phase C.
- Queue migration should avoid changing the `Contact Temple` controller contract.

## Risks + Mitigations

- Risk: async delivery changes UX expectations (“sent” vs “accepted”).
  - Mitigation: define success semantics clearly and log delivery outcomes.
- Risk: over-aggressive dedupe suppresses legitimate follow-ups.
  - Mitigation: start with exact-payload short-window dedupe only.
- Risk: queue retries amplify duplicates.
  - Mitigation: idempotency key enforcement at dispatch/worker level.

## Acceptance Criteria

- Email features can send through queued delivery without controller-specific logic.
- Duplicate submissions/retries can be suppressed centrally using dedupe rules.
- Delivery outcomes (sent/retried/failed/suppressed) are observable in logs/ops workflows.
- Contact Temple can migrate to queued delivery without changing UX/API contracts.
