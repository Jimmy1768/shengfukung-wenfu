# Final Web Readiness And Expo Gate Plan

Status: ready_for_execution

Created: 2026-07-12

Owner: Wenfu Control

Repository: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Purpose

Establish one final, evidence-based checkpoint for the existing web product.

The checkpoint answers one question:

> Is the Shengfukung Wenfu web product technically ready for operator-assisted
> temple onboarding, so the owner can hire a marketing manager and begin Expo
> development without carrying unresolved web-product defects forward?

This is a local product-readiness decision. It is not production deployment
approval, live ECPay acceptance, legal/accounting certification, or proof that
a real temple has completed onboarding.

## First-Principles Product Model

Temple onboarding is operator-assisted, not unrestricted public self-service.

The intended process is:

1. A prospective temple contacts the operator or submits an application.
2. A human verifies temple legitimacy and the representative's authority.
3. The operator approves or rejects the relationship.
4. At least one temple representative creates a normal user account.
5. The operator creates the temple tenant and promotes that user to temple owner/admin.
6. The owner may promote additional existing users into temple admin roles.
7. The temple submits one intake form per offering.
8. The operator translates each intake into temple-specific YAML/configuration.
9. The onboarding/apply script validates and installs the temple and offering configuration.
10. The operator and temple review the configured result and activate it when ready.

Human verification and offering-specific configuration are expected service
work. They are not bugs or evidence that the product is broken.

An onboarding fee may cover verification, intake, configuration, training, and
launch support. Payment of the fee is not proof that a temple is legitimate.

## Current Proven State

The current repository evidence establishes:

- temple account/tenant bootstrap exists;
- normal user signup exists;
- normal-user promotion to temple owner/admin exists;
- owner/admin creation or promotion of additional admin users exists;
- account/admin presentation polish is accepted;
- the full Rails suite passes at the latest accepted checkpoint;
- the ECPay default path, pending/completed/failed/cancelled status behavior,
  callbacks/webhooks, and refund-related application contracts have local or
  stubbed coverage;
- the admin payment-method page explains ECPay setup and provides Merchant ID,
  HashKey, and HashIV fields;
- production, secrets, provider, and production-data boundaries remain gated.

Related accepted evidence:

- `docs/operator/acceptances/2026-07-12-rails-full-suite-repair-acceptance.md`
- `docs/operator/acceptances/2026-07-12-account-admin-final-polish-acceptance.md`
- `docs/operator/acceptances/2026-06-13-ecpay-default-path-local-verification-acceptance.md`
- `docs/operator/acceptances/2026-07-12-synthetic-onboarding-acceptance-update-acceptance.md`
- `docs/operator/workflows/2026-07-12-synthetic-onboarding-proof-decision.md`
- `docs/operator/workflows/2026-07-12-assisted-onboarding-ecpay-gap-decision.md`

## Accepted Non-Blocking Gaps

### 1. Real Temple Offering Intake

The initial testing temple declined to complete an offering intake form.

This does not block readiness. The code path can be proven with a realistic
synthetic intake because the remaining engineering question is whether intake
data can become valid configuration and a working offering.

There is intentionally no universal offering schema. Each temple may require a
different form shape. One intake form per offering plus manual YAML translation
by the operator is acceptable for the current service model; temple staff do
not edit YAML.

### 2. Live ECPay Merchant Verification

The owner is not a temple and has no real ECPay merchant account. Live merchant
configuration, callback reachability, payment, settlement, and refund tests
cannot currently be performed.

This does not block readiness. Local and stubbed application-contract evidence
is sufficient for the web-code checkpoint. Live ECPay validation is reserved
for the first approved temple rollout with explicit human approval and the
temple's own merchant account.

The owner's reported Combatives and DojoMate platform-payment/refund evidence
may guide future reuse. It is not runtime proof for this repository. Any
cross-repository comparison or code reuse must route Control-to-Control and
receive separate review.

### 3. Future Guide Agent

A future Guide agent may help collect intake, validate missing fields, translate
configuration, explain ECPay setup, and guide admins. Guide is an accelerator,
not a prerequisite for web readiness or assisted onboarding.

## Explicit Non-Blockers

The final readiness decision must not wait for:

- a real temple participant;
- a real offering submission;
- the initial testing temple's cooperation;
- a marketing manager to be hired;
- a Guide agent;
- a live ECPay merchant account;
- real ECPay credentials or transactions;
- fully automated YAML generation;
- unrestricted self-service temple creation;
- Expo implementation;
- production deployment.

## Blocking Defect Classes

Only concrete repository defects may block this checkpoint:

- failing required tests or builds;
- invalid, non-idempotent, or unsafe offering configuration application;
- broken account, admin, registration, order, payment-status, or export behavior;
- security or authority failure;
- cross-temple data leakage or tenant-isolation failure;
- incorrect payment/accounting state semantics;
- secret exposure in forms, docs, logs, fixtures, or source control;
- unreconciled migrations/schema state;
- missing rollback or unsafe mutation behavior in the onboarding/apply script;
- contradictory current-source documentation that changes runtime expectations;
- dirty or ambiguous Git state at final signoff.

## Readiness Work Packages

Execute these packages serially. Each package must preserve exact evidence and
end in `pass`, `pass_with_accepted_gaps`, or `fail`.

### WR-1 — Repository And Dependency Preflight

Goal: establish a reproducible starting point.

Checks:

- record branch, HEAD, upstream, ahead/behind, staged, unstaged, and untracked state;
- run `git diff --check`;
- verify Ruby, Bundler, Node, npm, and project dependency state without upgrading dependencies;
- verify migrations and test schema are current;
- identify the canonical CSS build command as repo-root `bin/build_rails_css`;
- verify no unexpected local processes or temporary artifacts affect tests.

Pass condition:

- repository state is understood and no unrelated ambiguity exists.

### WR-2 — Complete Automated Regression

Goal: prove the accepted web behavior remains green.

Required checks:

- repo-root `bin/build_rails_css`;
- `cd rails && bin/rails test`;
- focused account/admin integration tests;
- focused permissions, multi-temple access, owner/admin transition, and internal temple-access tests;
- focused registration, order, payment, refund/cancel, export, and archive tests;
- focused ECPay adapter, checkout, callback/webhook, status-mapping, and payment-method setup tests;
- `cd vue && npm run build`;
- `git diff --check` after generated asset builds.

Pass condition:

- all required commands exit successfully with no failures or errors;
- generated CSS and Vue build output are internally consistent;
- known deprecation warnings are documented and demonstrated non-blocking.

### WR-3 — Security, Authority, And Tenant Isolation Scan

Goal: ensure readiness does not hide an authority or data-boundary defect.

Review and test:

- temple owner/admin promotion rules;
- last-owner and self-demotion protections where applicable;
- unauthorized admin access behavior;
- cross-temple access denial;
- account and admin session boundaries;
- provider credential visibility and update authorization;
- payment and accounting records scoped to the correct temple;
- exports and archives scoped to the selected temple and dates;
- secrets absent from docs, logs, fixtures, source control, and returned HTML.

Pass condition:

- no known authority, tenant-isolation, or secret-handling defect remains.

If review discovers architecture, persistence, authority, security, or
cross-contract-sensitive implementation work, route a separate GPT-5.4/high
Handoff job. Do not widen a mechanical readiness job silently.

### WR-4 — Offering Intake To Configuration Proof

Goal: prove the only unverified onboarding code path without waiting for a real
temple.

Inputs:

- locate the existing V1 offering intake form or rebuild a bounded equivalent;
- complete it with a realistic synthetic temple offering;
- use public/non-secret offering information only;
- keep passwords, API keys, payment credentials, bank information, and secrets out of the intake.

Execution:

1. Translate the completed intake into the supported temple offering YAML/config.
2. Run existing configuration audit/validation tools.
3. Run the onboarding/apply script in a local or isolated review environment.
4. Confirm the temple and offering configuration is installed correctly.
5. Confirm the offering appears correctly on admin and patron-facing surfaces.
6. Confirm registration, order, payment-status, and export paths recognize the offering.
7. Rerun the script to prove idempotency or a clear safe duplicate rejection.
8. Demonstrate rollback, dry-run, or safe removal behavior appropriate to the script.
9. Add or preserve a regression fixture/example that future changes can replay.

Pass condition:

- one realistic synthetic intake becomes a valid working offering without
  direct database edits, unsafe mutation, secret exposure, or cross-temple impact.

This proof accepts the offering-configuration code path. It does not claim that
all temple offerings share one standardized schema.

### WR-5 — ECPay Local Contract And Setup Readiness

Goal: prove everything that can be proven without a real merchant account.

Review and test:

- ECPay remains the intended Taiwan online-payment default;
- admin setup instructions are present and understandable;
- Merchant ID, HashKey, and HashIV inputs are present and protected as credential fields;
- credential values do not render back into HTML or logs unexpectedly;
- local/stubbed checkout creates pending payment state;
- return/webhook confirmation transitions state correctly;
- failed/cancelled paths remain non-received;
- refund-related state and accounting/export semantics remain correct;
- callbacks are authenticated/validated according to the implemented contract;
- no real ECPay calls or credentials are used.

Pass condition:

- all local/stubbed contracts pass and limitations are recorded honestly.

Live merchant setup, public callback reachability, live transaction, and live
refund remain accepted first-temple rollout gaps.

### WR-6 — Account/Admin And Operational UX Review

Goal: confirm the operator-assisted workflow is usable enough to launch.

Review:

- account creation and login;
- temple owner/admin entry points;
- admin navigation and responsive behavior;
- temple profile and payment-method setup;
- offering configuration review surfaces;
- registrations, orders, payments, refunds/cancellations, CSV export, and archives;
- clear separation between pending, completed, failed/cancelled, and refunded states;
- empty states, errors, long notices, focus states, and mobile layout.

Use browser evidence when available. If the browser tool is unavailable, use
rendered HTML, compiled CSS, request/integration tests, and source inspection.
Tool unavailability alone is not a blocker.

Pass condition:

- no concrete UX defect prevents assisted onboarding or ordinary operation.

### WR-7 — Current-Source Documentation Reconciliation

Goal: leave one coherent account of readiness.

Reconcile:

- this plan;
- V1 acceptance threshold;
- synthetic offering/onboarding proof decision;
- assisted onboarding and ECPay gap decision;
- production boundary;
- ECPay local verification acceptance;
- account/admin polish acceptance;
- deployment readiness plan;
- help-guide decision.

Required language:

- assisted onboarding is the current operating model;
- real offering intake and live ECPay are accepted rollout gaps;
- neither gap is a bug or a blocker for Expo or hiring;
- help documentation is a broader-rollout deliverable;
- production promotion requires a separate approved workflow;
- historical records remain historical and must not override current decisions.

Pass condition:

- no current-source contradiction remains.

### WR-8 — Final Git And Evidence Closeout

Goal: produce the durable readiness decision.

Required evidence:

- exact commit(s) reviewed;
- exact changed paths;
- exact command results and counts;
- skipped checks and reasons;
- accepted gaps;
- residual risks;
- authority, tenant, payment, secret, deployment, and production boundaries;
- final staged, unstaged, untracked, ahead/behind, committed, and pushed state;
- rollback or revert guidance for readiness changes;
- final decision record and execution record.

Pass condition:

- Git state is clean and the evidence supports a binary decision.

## Final Decision

The final acceptance record must use exactly one of:

### ready

Use `ready` only when:

- every blocking defect class is cleared;
- every required build/test/check passes;
- the synthetic offering configuration proof passes;
- local ECPay contract/setup verification passes;
- documentation is coherent;
- remaining gaps are explicitly accepted rollout gaps;
- final Git state is clean and attributable.

Meaning:

- the web product is technically ready for operator-assisted temple onboarding;
- the owner may hire a marketing manager;
- Expo development may begin;
- the first approved temple can be onboarded together through the documented manual process.

`ready` does not authorize production deployment or live ECPay action by itself.

### not_ready

Use `not_ready` only when a concrete blocking defect remains.

The record must name:

- the exact defect;
- affected files/surfaces;
- failed evidence;
- user or business impact;
- required repair;
- verification needed to clear it.

Do not use `not_ready` merely because a real temple, marketing manager, Guide
agent, live merchant account, or production deployment is unavailable.

## Execution Order

1. Finish and accept the active assisted-onboarding/ECPay policy documentation job.
2. Execute WR-1 through WR-3.
3. Execute WR-4 as the remaining offering-configuration proof.
4. Execute WR-5 and WR-6.
5. Reconcile docs in WR-7.
6. Complete WR-8 and issue `ready` or `not_ready`.
7. On `ready`, allow marketing-manager hiring and start the Expo implementation plan.

## Post-Ready Work

After `ready`:

- hire and onboard the marketing manager;
- begin Expo implementation from existing mobile plans and stable API contracts;
- prepare the broader-rollout help guide;
- onboard the first approved temple through assisted verification and intake;
- complete live ECPay merchant setup and minimal payment/refund smoke testing
  only with the temple's credentials, explicit approval, and a separate
  production/provider-safe workflow;
- consider Guide-agent assistance for intake and provider setup.

## Production Boundary

This plan does not authorize:

- deployment or release promotion;
- DNS, TLS, proxy, server, queue, cron, or process-manager changes;
- production migrations or data access;
- secret access or rotation;
- real ECPay merchant changes, transactions, callbacks, or refunds;
- customer or temple production-state changes;
- claims of legal, tax, accounting, invoice, settlement, or regulatory finality.

Those actions require their own exact handoff and explicit human approval.
