# Acceptance: Assisted Onboarding And ECPay Gap Policy

Acceptance id: `shengfukung-2026-07-12-assisted-onboarding-ecpay-gap-policy-acceptance`

Created: 2026-07-12

Reviewer: Wenfu Control

## Decision

accepted

## Decision Reason

The policy and wording retry correctly establish the current operating model:

- temple onboarding is an operator-assisted trust and configuration service,
  not unrestricted public temple-account creation;
- temple staff submit one intake per offering and do not edit YAML;
- an operator may translate offering intake into temple-specific YAML/config;
- one realistic synthetic intake is sufficient to prove the remaining code path;
- refusal by the initial testing temple is not a product defect or blocker;
- local and stubbed ECPay evidence is sufficient for this web-code checkpoint;
- live ECPay merchant, callback, payment, and refund verification is deferred to
  the first approved temple rollout;
- the two deferred real-world validations are accepted rollout gaps, not bugs;
- neither gap blocks the final readiness scan, marketing-manager hiring after a
  `ready` decision, or Expo development;
- a future Guide agent and an onboarding fee remain optional operating choices.

## Independent Verification

Wenfu Control reviewed the changed policy, return, and Control-owned final
readiness plan and ran:

- `git diff --check` -> pass;
- the required terminology scan across the V1 threshold, assisted-onboarding
  decision, return, and readiness plan -> pass;
- `git status --short` -> only the intended documentation changes.

The wording retry resolves the prior ambiguity: automation is not required,
operator-side YAML translation is allowed, and temple staff are not expected to
edit YAML.

## Required Retry

None.

## Next Gate

Execute `ops/docs/plans/FINAL_WEB_READINESS_AND_EXPO_GATE_PLAN.md` and issue the
binary `ready` or `not_ready` decision from repository evidence.

## Handoff Lifecycle

The healthy bound Wenfu Handoff remains bound and idle for the next job.

## Promotion Allowed

No production promotion or live payment-provider action. Documentation policy
acceptance only.
