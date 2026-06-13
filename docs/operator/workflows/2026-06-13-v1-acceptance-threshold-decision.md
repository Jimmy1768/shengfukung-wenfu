# Workflow Decision: V1 Acceptance Threshold

Decision id: `shengfukung-2026-06-13-v1-acceptance-threshold`

Created: 2026-06-13

Owner: Shengfukung Wenfu coordinator thread

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch context: `offering-setup-admin-workflow`

## Decision

V1 is complete enough for broader temple rollout only after product behavior, local QA evidence, payment/accounting evidence, admin rehearsal, and help documentation meet the threshold below.

This is not production deployment approval by itself. It defines the evidence required before V1 can be considered ready for broader temple rollout planning.

## Required Evidence

V1 acceptance requires:

- focused Rails tests passing for onboarding, registrations, orders, payments, refund/cancel paths, and exports;
- large seeded admin QA passing for orders, payments, and accounting/admin reporting surfaces;
- browser/admin rehearsal passing for temple profile setup, offering setup draft, review/apply, registration, order, and payment flows;
- ECPay default path verified locally or in sandbox;
- cash `Received` flow verified as admin-attested, with admin identity and timestamp preserved;
- previous-month export flow working for the 1st-day-of-month accounting process;
- comprehensive help guide completed after V1 behavior settles;
- help guide linked from temple public/marketing pages for patrons and from the admin console for admins;
- at least one real temple admin or staff-assisted rehearsal completed without requiring YAML editing or engineer-led interview for ordinary offerings.

## Explicit Non-Requirements For V1

The following are not required for V1 acceptance:

- formal accounting close or lock state;
- provider settlement batch matching;
- full general ledger;
- arbitrary schema builder;
- mobile/Expo app;
- zero-support onboarding for every low-process temple;
- production deployment approval.

## Acceptance Meaning

V1 acceptance means:

- the admin console supports repeatable temple onboarding without manual YAML editing by temple staff;
- normal offering setup can be submitted, reviewed, and applied through the product workflow;
- admins can manage registrations, orders, payments, cash receipt, ECPay payment status, refunds/cancellations, and CSV export with enough clarity to operate;
- the system has enough evidence to start broader rollout planning.

V1 acceptance does not mean:

- production promotion is automatically allowed;
- accounting controls are final;
- all edge cases are automated;
- all temples can self-serve without assistance.

## Related Decisions

- ECPay is the default online payment method for Taiwan temples.
- Cash is allowed as an admin-attested receipt event.
- Monthly export happens on the 1st day of each month for the previous calendar month.
- V1 monthly close is external/manual and supported by filters plus CSV export; no in-app close/lock state yet.
- Offering onboarding moves into admin-console draft/submission/review/apply flow.
- V1 uses a controlled supported field catalog.
- A comprehensive help guide is required after V1 functional acceptance and before broader rollout.

## Future Handoff Trigger

Create a V1 acceptance review handoff after the remaining implementation and QA workflows are complete.
