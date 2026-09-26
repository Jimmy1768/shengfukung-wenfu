# Payment Foundation Parallel-Track Integration Plan

Status: accepted for implementation

Accepted: 2026-08-13

Owner: Wenfu Planning

## Exact Inputs

- Canonical base: `75e16f5fa2e53cc8afa56819f7f1a3981246b210`
- Phase 1 checkpoint: `ab05e844067b6c6c5c8e74e45d9b1d2536fef2a1`
- Phase 2 checkpoint: `f1049789079c93ebfe31a579ed68d6d27453f1fc`
- Phase 1 plan:
  `ops/docs/plans/PLATFORM_BILLING_QUALIFYING_REGISTRATION_ACCOUNTING_PLAN.md`
  (deleted 2026-09-26: implemented; see `ops/docs/reference/templemate_platform_billing_runtime.md`)
- Phase 2 plan:
  TENANT_SCOPED_PATRON_PAYMENT_PROVIDER_PLAN.md (deleted 2026-08-22 in the
  plans/archive cleanup; recoverable via `git log --grep`)

Both checkpoints are accepted immutable pre-integration outcomes from the same
base. This plan authorizes their local integration through Control A.

## Objective

Preserve both checkpoint ancestries and produce one canonical payment-
foundation baseline in which qualifying-registration accounting and tenant-
scoped patron provider selection coexist without weakening either contract.

## Known Overlap

Only these product/test paths overlap:

- `rails/app/services/payments/refund_service.rb`
- `rails/test/services/payments/refund_service_test.rb`

The accepted resolution is additive:

- retain Phase 1's fail-closed full-refund-only contract, including rejection
  of requested or provider-reported partial refund before payment,
  registration, or billing-eligibility mutation; and
- retain Phase 2's exact payment-temple propagation when resolving the
  recorded provider for refund or cancel.

No other semantic redesign is authorized.

## Integration Requirements

1. Start from exact clean canonical base and create a new isolated
   `codex/` integration branch/worktree.
2. Incorporate both exact checkpoint tips with their ancestry preserved.
3. Resolve only the two known overlapping paths according to the additive rule
   above. Any other conflict is a stop requiring Planning review.
4. Preserve the additive reversible migration, schema, qualifying timestamp,
   aggregate correction, concurrency/idempotency, tenant provider precedence,
   Shengfukung fake selection, historical provider binding, and webhook tenant
   boundaries exactly as accepted.
5. Run both complete checkpoint test matrices together, migration
   forward/rollback/forward in a guarded disposable test database, the full
   Rails suite, Ruby syntax for changed source, and `git diff --check`.
6. Prove the final commit contains both accepted checkpoint tips as ancestors.
7. On acceptance, Control A may locally integrate the combined result into
   canonical `main` and return one immutable terminal packet.

## Exclusions

No offering/template/price change; no provider, Stripe, or ECPay call; no
credential/configuration inspection; no Vue/Expo change; no production data,
deployment, timer, release ref, push, or external action.

## Acceptance Criteria

- Both checkpoint ancestries are present.
- All Phase 1 and Phase 2 immutable criteria remain true.
- Partial refund fails closed and refund/cancel retains exact temple context.
- Required combined tests and migration rehearsal pass.
- Canonical `main` ends clean with empty staging at the accepted integration
  commit.

## Next Step

After Planning accepts the integration terminal, it commits and dispatches the
separate Phase 3 four-offering controlled-configuration plan. No Phase 3 work
is implied by this plan.
