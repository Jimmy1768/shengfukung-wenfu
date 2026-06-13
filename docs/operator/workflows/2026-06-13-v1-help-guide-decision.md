# Workflow Decision: V1 Help Guide Requirement

Decision id: `shengfukung-2026-06-13-v1-help-guide-requirement`

Created: 2026-06-13

Owner: Shengfukung Wenfu coordinator thread

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch context: `offering-setup-admin-workflow`

## Decision

After V1 is functionally complete, Shengfukung Wenfu needs a comprehensive help guide similar in intent and coverage to the DojoMate-Vue help guide.

This is a required V1 completion follow-up before broader temple rollout, not an optional polish task.

## Why

The product direction is shifting from one-off, owner-mediated temple setup toward repeatable temple onboarding through the admin console.

That only works if both audiences can understand the workflow without direct engineer assistance:

- temple patrons need help using each temple's public/marketing pages and registration/payment flows;
- temple admins need help managing temple profile, offerings, registrations, orders, payments, monthly export, and setup review/apply workflows.

The help guide is part of making the product scalable across multiple temples.

## Required Link Locations

Patron/user help:

- Each temple marketing/public page should expose a Help or Guide section/link for temple users.
- The patron-facing guide should explain registration, offerings/services, payment expectations, account/login flow if applicable, and what to do when payment is pending or failed.

Admin help:

- The admin console should expose a Help or Guide entry for temple admins.
- The admin guide should explain daily admin workflows, including temple profile, offering setup drafts, review/apply expectations, registrations/orders, cash receipt, ECPay payment status, refunds/cancellations, CSV export, and previous-month accounting export.

## Timing

Do not build the help guide before V1 behavior has settled.

Create the help guide after V1 functional acceptance so documentation matches the actual product.

The help guide should be treated as its own bounded workflow with handoff, implementation, review, acceptance, execution record, verification, and commit.

## Scope Guidance

The V1 help guide should include at least:

- patron-facing getting started;
- registration and payment flow;
- ECPay default payment behavior for Taiwan temples;
- cash payment expectations where enabled;
- pending/failed/refunded payment explanations;
- temple admin onboarding flow;
- offering setup draft/submission/review/apply flow;
- supported field catalog boundaries;
- admin orders and payments ledger usage;
- previous-month export on the 1st day of each month;
- CSV export handoff to external accounting;
- troubleshooting and support escalation.

## Non-Goals For Current Workflow

- Do not implement help-guide UI links from this decision record alone.
- Do not write the full help guide before V1 acceptance.
- Do not change public pages, admin navigation, routing, deployment, server config, secrets, payment provider config, or production data from this docs-only decision record.

## Related Product Decisions

- Accounting useful enough means an admin can identify payment owner, purpose, amount, method, status, next action, and audit trail without developer help.
- ECPay is the default online payment method for Taiwan temples.
- Cash is allowed as an admin-attested receipt event; the system trusts and audits the admin pressing Received.
- V1 monthly accounting export happens on the 1st day of each month for the previous calendar month's entries in the temple's local timezone.
- V1 does not add formal accounting close/lock state.
- Offering onboarding moves into the admin console through draft/submission/review/apply flow; temples do not edit YAML directly.
- V1 uses a controlled supported field catalog rather than an arbitrary schema builder.

## Future Handoff Trigger

Create the help-guide implementation handoff after V1 functional scope is accepted and before broader temple rollout.
