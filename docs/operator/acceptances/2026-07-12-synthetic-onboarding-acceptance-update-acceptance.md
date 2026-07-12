# Acceptance: Synthetic Onboarding Acceptance Update

Acceptance id: `shengfukung-2026-07-12-synthetic-onboarding-acceptance-update-acceptance`

Created: 2026-07-12

Reviewer: Wenfu Control

## Decision

accepted

## Decision Reason

The combined update and retry correctly implement the owner direction:

- synthetic end-to-end proof satisfies the onboarding/rehearsal gate;
- synthetic proof is sufficient to accept the web onboarding flow;
- accepted web onboarding unblocks Expo work;
- no real temple, real offering, employee, marketing manager, or outside participant is required;
- Shengfukung is no longer a product-progress dependency;
- the old real-temple rehearsal packet and session handoff are superseded for this gate and retained only as optional future market-validation references;
- the previous awaiting-participant friction is resolved by policy change without claiming a real rehearsal occurred;
- help documentation remains a later broader-rollout deliverable, not an Expo prerequisite;
- production, payment-provider, secret, and production-data boundaries remain unchanged.

## Independent Verification

Wenfu Control reviewed all six changed policy/evidence paths and ran:

- `git diff --check` -> pass;
- the required `rg` milestone and dependency scan -> pass;
- `git status --short` -> only the intended documentation changes.

## Current Sequence

1. Polish account/admin pages.
2. Prove synthetic onboarding end-to-end.
3. Accept web onboarding.
4. Begin Expo work.

A future Guide onboarding agent may assist this flow, but it is not required to
prove or operate the current onboarding path.

## Required Retry

None.

## Handoff Lifecycle

The healthy bound Wenfu Handoff remains bound and idle for the next job.

## Promotion Allowed

No production promotion. Documentation policy acceptance only.
