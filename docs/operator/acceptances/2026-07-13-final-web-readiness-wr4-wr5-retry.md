# Retry Required: Final Web Readiness WR-4 And WR-5

Decision id: `shengfukung-2026-07-13-final-web-readiness-wr4-wr5-retry`

Created: 2026-07-13

Reviewer: Wenfu Control

## Decision

retry_required

## Accepted Work Pending Retry

The main implementation is coherent and within scope:

- durable synthetic human intake and operator-to-YAML mapping;
- clearly synthetic temple and service fixtures;
- bootstrap, draft ensure, idempotent rerun, metadata sync, transactional cleanup,
  admin order, and account payment-status coverage;
- local ECPay contract matrix and new audit-log secret-value regression;
- focused and full Rails suites reported green.

## Retry Reason

The new `SLUG=<slug>` safety option in both offering-config scripts silently
succeeds when the slug is misspelled or absent from the database.

Independent Control reproduction:

- `SLUG=definitely-missing-readiness-slug ruby ops/scripts/audit_offering_configs.rb`
  exited `0` with no output;
- `SLUG=definitely-missing-readiness-slug ruby ops/scripts/sync_offering_configs.rb`
  exited `0` with no output.

This can falsely signal that a temple was audited or synchronized when no
temple was selected. Because the option is documented as a safer isolated
workflow, silent success is not acceptable operational evidence.

## Required Retry

- When `SLUG` is present, both scripts must resolve exactly one existing temple.
- An unknown or blank-effective selected slug must exit non-zero with a concise,
  non-secret error naming the missing slug.
- Global behavior with no `SLUG` must remain unchanged.
- Valid single-temple audit/sync must still operate only on that temple.
- Add durable regression evidence where practical and run explicit negative
  CLI checks for both scripts.
- Preserve every existing WR-4/WR-5 change and rerun the required focused/full
  checks after the fix.

## Boundaries

No real temple, real ECPay, secrets, provider calls, production, deployment,
customer state, cross-repository work, or published offering activation.

## Handoff Lifecycle

The healthy replacement Handoff `019f55bd-3447-74f3-8225-eabfdc511e64`
remains exclusively bound and reusable.
