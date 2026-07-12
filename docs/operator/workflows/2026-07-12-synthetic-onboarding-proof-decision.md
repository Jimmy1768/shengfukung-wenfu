# Workflow Decision: Synthetic Onboarding Proof

Decision id: `shengfukung-2026-07-12-synthetic-onboarding-proof`

Created: 2026-07-12

Owner: Shengfukung Wenfu coordinator thread

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Decision

Synthetic end-to-end onboarding proof satisfies the onboarding/rehearsal gate and is sufficient to accept the web onboarding flow.

Accepting web onboarding unblocks Expo work.

This proof replaces any requirement for a real temple, real offering, employee, marketing manager, or outside participant before Expo work can begin.

## Sufficient Evidence

The proof is sufficient when the project has:

- automated Rails coverage for the onboarding and accounting surfaces;
- a complete local browser or equivalent end-to-end walkthrough;
- a synthetic temple and a realistic fake offering;
- coverage of temple profile setup, offering draft/create, review/apply, registration, order, and payment-status behavior.

## Exclusions

The proof does not require:

- a real temple;
- a real offering;
- a real participant;
- a marketing manager;
- YAML editing by staff;
- production data;
- production deployment;
- real payment-provider calls.

## Sequence

Current sequence is:

1. amend acceptance criteria;
2. polish account/admin pages;
3. prove synthetic onboarding end-to-end;
4. accept web onboarding;
5. begin Expo work.

## Related Records

- Acceptance threshold: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- Superseded rehearsal packet: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md`
- Superseded session handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-14-real-temple-admin-staff-rehearsal-session.md`

## Boundary

This decision preserves production, payment-provider, secret, and production-data boundaries.
