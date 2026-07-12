# Acceptance: Assisted Onboarding and ECPay Gap Policy Retry

Acceptance id: `shengfukung-2026-07-12-assisted-onboarding-ecpay-gap-policy-retry`

Created: 2026-07-12

Reviewer: Wenfu Control

## Decision

retry_required

## Decision Reason

The new assisted-onboarding/ECPay decision correctly records the two accepted
non-blocking gaps. One current-source wording conflict remains:

- the new model permits operator-side manual translation of offering intake into YAML;
- the older V1 threshold says onboarding works "without manual YAML editing" without limiting that statement to temple staff.

The intended product rule is that temple staff do not edit YAML. Operator-side
configuration remains an accepted service step.

## Required Retry

- Change the V1 threshold wording to say "without manual YAML editing by temple staff."
- Preserve operator-side intake-to-YAML work as accepted.
- Update the durable return to mention the clarified boundary.
- Run the required terminology and diff checks.

## Promotion Allowed

No production promotion. Docs remain pending the narrow retry.
