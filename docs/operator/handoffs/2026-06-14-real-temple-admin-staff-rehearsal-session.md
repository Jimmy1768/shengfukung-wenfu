# Handoff: Real Temple Admin/Staff Rehearsal Session

Handoff id: `shengfukung-2026-06-14-real-temple-admin-staff-rehearsal-session`

Created: 2026-06-14

Coordinator: Shengfukung Wenfu coordinator/implementation thread

Target: human session owner/observer, then Shengfukung Wenfu coordinator/implementation thread for records

Mode: real participant rehearsal evidence collection

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Run the first real temple admin/staff rehearsal required for V1 acceptance evidence.

This handoff does not authorize product implementation, deployment, production data access, server/provider configuration changes, payment-provider calls, secret access, or real ECPay merchant changes.

## Required Packet

Use this packet during the session:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md`

## Required Preconditions

Before the session starts, confirm:

- a real temple staff/admin participant is available;
- the participant understands this is a rehearsal, not production launch;
- the environment is local, staging, or explicitly approved non-production;
- no real payment will be charged;
- no real ECPay merchant configuration will be changed;
- no production data will be accessed unless separately and explicitly approved;
- account/invitation/permission changes are rehearsal-only or separately approved;
- screen recording or screenshots are approved before capture;
- one ordinary offering/service item is prepared from the temple's real vocabulary;
- one simple order/registration scenario is prepared;
- one cash receipt scenario is prepared;
- one ECPay status scenario is prepared from non-production/static data;
- one previous-month accounting export scenario is prepared.

## Session Instructions

The participant should drive the admin console. The observer should avoid explaining policy or field meaning unless the participant is blocked.

Run the packet tasks in order:

1. Admin login and orientation.
2. Temple profile review.
3. Offering setup draft.
4. Review/apply understanding.
5. Registrations and orders.
6. Cash receipt.
7. ECPay status understanding.
8. Previous-month accounting export.
9. End-of-session reflection.

## Evidence To Capture

Record:

- session date/time;
- participant role;
- environment used;
- whether production/provider/payment boundaries were avoided;
- tasks completed without help;
- tasks completed with light prompting;
- tasks completed only with heavy assistance;
- tasks blocked;
- exact confusing words, labels, or fields;
- wrong assumptions made by staff;
- whether ordinary offering setup worked without YAML;
- whether draft/review/apply responsibility was understood;
- whether cash admin attestation was understood;
- whether ECPay status truth was understood;
- whether previous-month export was found and explained;
- screenshots/recording links only if approved;
- observer recommendation: `accepted`, `accepted_with_gaps`, `retry_required`, or `blocked`.

## Required Return Records

After the session, create:

- return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-14-real-temple-admin-staff-rehearsal-session-return.md`
- eval: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-14-real-temple-admin-staff-rehearsal-session-eval.md`
- acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-14-real-temple-admin-staff-rehearsal-session-acceptance.md`
- execution: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-14-real-temple-admin-staff-rehearsal-session-execution.md`

If the session cannot run because participant/environment approval is unavailable, record the blocker in `docs/operator/friction_records/`.

## Acceptance Criteria

Accepted:

- staff completes all core tasks with no material assistance;
- ordinary offering setup does not require YAML editing or engineer translation;
- staff understands draft/review/apply responsibility;
- staff can find and interpret orders/payment status;
- staff can explain cash as admin-attested;
- staff can explain ECPay completed/pending/failed/refunded boundaries;
- staff can find previous-month export and explain external accounting handoff;
- no production/provider/server/secret/payment boundary is crossed.

Accepted with gaps:

- all core tasks are completed, but some help text, copy, or training follow-up is needed;
- gaps do not prevent ordinary V1 operation.

Retry required:

- one or more core tasks require heavy assistance;
- offering setup still depends on owner/engineer translation;
- payment/accounting status meaning is materially misunderstood;
- previous-month export cannot be found or explained.

Blocked:

- safe rehearsal environment or participant is unavailable;
- session needs production/provider/server/secret/payment changes to proceed;
- product cannot represent an ordinary offering without YAML;
- evidence is insufficient for acceptance.

## Non-Goals

- Do not implement product/code changes from this handoff.
- Do not deploy.
- Do not change server, DNS, TLS, proxy, cron, queue, or systemd configuration.
- Do not access or rotate secrets.
- Do not change payment provider configuration.
- Do not call real payment providers.
- Do not change real ECPay merchant state.
- Do not touch production data.
- Do not create automation.
- Do not work on mobile/Expo.
- Do not build the comprehensive help guide yet.

## Expected Chat Return

When records exist, return only:

```text
Done.

File:
<absolute path to return/acceptance/execution/friction record>

Next:
<who reviews or what should happen next>
```
