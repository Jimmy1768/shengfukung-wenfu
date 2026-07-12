# Acceptance: Synthetic Onboarding Acceptance Update Retry

Acceptance id: `shengfukung-2026-07-12-synthetic-onboarding-acceptance-update-retry`

Created: 2026-07-12

Reviewer: Wenfu Control

## Decision

retry_required

## Decision Reason

The update correctly removes all real-temple, real-offering, employee,
marketing-manager, and outside-participant dependencies. It also correctly
retires the old real-participant blocker.

One wording conflict remains: the new synthetic proof decision says synthetic
proof alone is sufficient for all V1 acceptance, while the V1 threshold still
contains other broader-rollout requirements such as the comprehensive help
guide and links.

The owner-directed milestone is narrower and clearer:

- synthetic proof accepts the web onboarding flow and unblocks Expo work;
- help documentation remains a later broader-rollout deliverable;
- neither milestone requires an external participant.

## Required Retry

- State that synthetic proof satisfies the onboarding/rehearsal gate and is sufficient to accept web onboarding.
- State that accepting web onboarding unblocks Expo work.
- Do not claim synthetic proof alone satisfies every broader-rollout V1 requirement.
- Keep help-guide work as a later broader-rollout deliverable, not an Expo prerequisite.
- Preserve the removal of all external-person dependencies.
- Correct the durable return to reflect this milestone distinction.

## Promotion Allowed

No production promotion. Docs remain uncommitted pending the bounded retry.
