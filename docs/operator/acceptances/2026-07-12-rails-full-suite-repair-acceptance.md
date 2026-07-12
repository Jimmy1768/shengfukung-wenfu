# Acceptance: Rails Full-Suite Repair

Acceptance id: `shengfukung-2026-07-12-rails-full-suite-repair-acceptance`

Created: 2026-07-12

Reviewer: Wenfu Control

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-rails-full-suite-repair.md`

Related retry handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-rails-full-suite-repair-retry.md`

Related retry decision: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-rails-full-suite-repair-retry.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-rails-full-suite-repair-return.md`

## Decision

accepted

## Decision Reason

The bounded repair and retry meet their requirements:

- serializer constants resolve from the intended top-level `Account::Api` namespace;
- account API tests use the generated current route helpers;
- test data now preserves the `temple_events.starts_on` invariant and current polymorphic registration shape;
- authorization coverage now uses a genuinely unauthorized non-owner admin;
- admin registrations coverage matches the current Traditional Chinese UI and V1-disabled event state;
- model validation assertions explicitly use the English locale instead of placing English copy under `zh-TW`;
- payment fixtures include required provider identity;
- cash-payment coverage verifies the durable ledger entry, completed payment, notes, admin audit metadata, and paid registration state;
- the durable return matches the final changed paths.

## Independent Verification

Wenfu Control ran:

- `cd rails && bin/rails test` -> `310 runs, 1748 assertions, 0 failures, 0 errors, 0 skips`;
- `git diff --check` -> pass;
- owned-path review against both Handoff packets -> pass.

The only observed noise is the pre-existing Rack deprecation warning for
`:unprocessable_entity`.

## Required Retry

None.

## Scope Boundary

This accepts the Rails full-suite repair only. It does not accept V1, the real
temple staff rehearsal, deployment, production readiness, payment-provider
state, secrets work, or production data changes.

## Handoff Lifecycle

The healthy bound Wenfu Handoff remains bound and returns to idle. It must not
be archived after this successful job.

## Promotion Allowed

No production promotion. Local Rails repair acceptance only.
