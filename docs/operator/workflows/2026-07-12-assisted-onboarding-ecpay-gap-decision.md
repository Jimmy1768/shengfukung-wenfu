# Workflow Decision: Assisted Onboarding and ECPay Gap Policy

Decision id: `shengfukung-2026-07-12-assisted-onboarding-ecpay-gap`

Created: 2026-07-12

Owner: Shengfukung Wenfu coordinator thread

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch context: `main`

## Decision

Temple onboarding is an operator-assisted business process, not unrestricted public temple-account creation.

Temple legitimacy and representative authorization are business trust boundaries that require human approval. They are not code defects, and they do not belong in this docs workflow as a product bug or blocker.

The remaining onboarding proof is now narrow:

- completed offering intake;
- temple-specific YAML or configuration;
- onboarding/apply script execution;
- working offering after apply.

The first realistic synthetic intake is sufficient. Refusal by the initial testing temple to complete a form is not a bug, a blocker, or a reason to reopen the acceptance gate.

The current model allows one intake form per offering and manual translation into YAML because temple configurations are not standardized yet.

An onboarding fee may cover verification, configuration, training, and launch support. That is a business model decision, not legitimacy proof.

No live ECPay merchant account is available in this repo context because the owner is not a temple. Real ECPay merchant, refund, and callback testing therefore cannot currently be performed here.

The existing local and stubbed ECPay checkout, return, webhook, status, and refund evidence remains sufficient for current code acceptance. That evidence does not claim live ECPay production acceptance.

The owner-provided payment/refund behavior observed in Combatives and DojoMate is a reusable implementation reference only. It is not runtime proof for this repository and it must not be treated as cross-repository authority.

Any future cross-repository code reuse or contract comparison must route Control-to-Control and receive a separate implementation review.

The current admin payment-method page already explains ECPay setup and exposes Merchant ID, HashKey, and HashIV fields. No product-code change is authorized by this docs-only workflow.

Live ECPay merchant setup, callback reachability, and a minimal payment/refund smoke test are reserved for the first approved temple rollout with explicit human approval.

The two accepted gaps are non-blocking:

- temple-specific offering intake is acceptable as a realistic synthetic intake plus manual YAML translation for now;
- live ECPay merchant verification is deferred until a first approved temple rollout.

Those gaps do not block web onboarding acceptance, Expo work, or continued product development.

Future Guide or bot assistance may help with intake and ECPay setup, but it is optional support only. It is not a prerequisite.

This decision preserves production, payment-provider, secret, and production-data boundaries.

## Related Decisions

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-help-guide-decision.md`

## Future Handoff Trigger

Create a follow-up implementation or rollout handoff only when the first approved temple rollout is explicitly authorized.
