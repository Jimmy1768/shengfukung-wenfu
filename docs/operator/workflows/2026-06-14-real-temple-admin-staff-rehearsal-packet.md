# Workflow Packet: Real Temple Admin/Staff Rehearsal

Packet id: `shengfukung-2026-06-14-real-temple-admin-staff-rehearsal-packet`

Created: 2026-06-14

Owner: Shengfukung Wenfu coordinator/implementation thread

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Related acceptance threshold: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`

Related production boundary: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`

## Purpose

This packet prepares the first real temple admin/staff rehearsal required before V1 can be considered ready for broader temple rollout planning.

The rehearsal is not a sales demo and not a production launch. It is a structured usability and operational-readiness session proving whether ordinary temple staff can use the admin console to operate V1 without editing YAML or relying on an engineer-led interview for ordinary offering setup.

## Session Boundary

Allowed:

- use a local, staging, or explicitly approved non-production environment;
- use fake, sample, or approved rehearsal data;
- let temple staff drive the admin workflow while the observer watches;
- record friction, confusion, missing language, skipped fields, and support needs;
- stop the session if production/provider/payment risk appears.

Not allowed in this rehearsal:

- production data access;
- deployment;
- server, DNS, TLS, proxy, cron, queue, or systemd changes;
- secrets access or rotation;
- real ECPay merchant configuration changes;
- real payment-provider calls that can move money or alter merchant state;
- production account invitations or permission changes;
- manual YAML editing by temple staff;
- claiming production readiness.

## Roles

Temple staff/admin:

- performs the staff-facing tasks in the admin console;
- speaks aloud what they think each field/status/action means;
- asks for help only when blocked or confused;
- does not edit YAML or configuration files.

Observer:

- does not lead with explanations unless staff is blocked;
- records elapsed time, assistance level, friction, wrong turns, missing copy, and support burden;
- captures evidence for acceptance;
- decides nothing about production promotion.

Coordinator:

- reviews the observer record after the session;
- decides whether the rehearsal is accepted, accepted with gaps, retry required, or blocked for V1 acceptance purposes;
- creates the OperatorKit return/eval/acceptance/execution records.

## Preflight

Before scheduling the real session:

- confirm the environment is non-production or explicitly approved for rehearsal;
- confirm no real payment will be charged;
- confirm the staff user/account is a rehearsal account, or production account use has separate explicit approval;
- prepare one ordinary offering/service item the temple actually understands;
- prepare one deliberately simple paid registration/order scenario;
- prepare one cash receipt scenario;
- prepare one ECPay status explanation scenario using non-production or static data;
- prepare one previous-month export scenario;
- prepare screen recording or written notes if approved by the participant;
- prepare the friction log table below.

## Staff-Facing Task Script

The observer should hand the staff member one task at a time. Do not explain the next task until the current task is complete or blocked.

### 1. Admin Login And Orientation

Task:

- sign in to the admin console;
- identify the current temple;
- find the main navigation;
- say which page you would open first to review daily operations.

Success evidence:

- staff reaches the admin dashboard;
- staff can identify the current temple and navigation;
- staff does not require code, YAML, or developer help.

### 2. Temple Profile Review

Task:

- open the temple profile/admin profile page;
- identify where temple name, address/location, public contact, and public-facing text would be reviewed or changed;
- state what information you would ask the temple owner for if a field is missing.

Success evidence:

- staff can find the profile area;
- staff understands the difference between public temple information and internal admin/accounting information.

### 3. Offering Setup Draft

Task:

- open offering management;
- start a new offering setup/draft if the environment allows;
- create or review one ordinary offering/service item using admin-console fields;
- fill the fields staff can reasonably answer;
- leave unknown fields blank or mark them for owner review;
- submit/save the draft for review.

Required observation:

- whether staff can describe the offering without YAML;
- which fields are unclear;
- whether field names match temple language;
- whether staff needs a human interview to translate the offering into the system;
- whether staff can distinguish draft/review from live publication.

Success evidence:

- ordinary offering setup can be submitted through admin UI;
- no YAML editing is needed from staff;
- unknown details can be deferred without losing the whole draft.

### 4. Review/Apply Understanding

Task:

- explain what should happen after the draft is submitted;
- identify whether the item is live or still awaiting review;
- explain who should approve/apply the draft.

Success evidence:

- staff understands that submission is not automatically live unless the system says so;
- staff understands owner/operator review responsibility.

### 5. Registrations And Orders

Task:

- find registrations/orders;
- search or filter for the prepared order;
- identify patron/contact, offering, quantity, payment status, and next action;
- explain what should be done for unpaid, paid, failed, refunded, or cancelled records.

Success evidence:

- staff can find a registration/order without developer help;
- staff can identify payment status and next action correctly.

### 6. Cash Receipt

Task:

- find the prepared cash payment/order;
- mark or explain how cash would be recorded as received in the admin console;
- identify who recorded it and when.

Success evidence:

- staff understands cash is admin-attested;
- staff can find admin identity/timestamp evidence or knows where the system records it;
- staff does not believe the system independently controls cashflow.

### 7. ECPay Status Understanding

Task:

- inspect one ECPay/provider-backed payment example;
- explain the difference between pending, completed, failed/cancelled, and refunded;
- state which statuses count as received revenue in V1.

Success evidence:

- staff understands completed provider confirmation is trusted;
- staff understands pending is not received;
- staff understands failed/cancelled is not received;
- staff understands refunded is not completed revenue.

### 8. Previous-Month Accounting Export

Task:

- open payments;
- select the previous month/last month preset;
- explain why this should be done on the 1st day of each month for the previous calendar month;
- export or identify the CSV export action;
- identify which CSV fields are useful for external accounting handoff.

Success evidence:

- staff can select the previous-month preset;
- staff can identify the export action;
- staff understands V1 does not close/lock the month in-app;
- staff can explain that external accounting reviews the CSV.

### 9. End-Of-Session Reflection

Task:

- ask staff to name the three actions they could repeat tomorrow without help;
- ask staff to name the three places they would need help;
- ask staff what wording or field labels felt unfamiliar.

Success evidence:

- observer has enough evidence to decide whether product flow, copy, and support burden are acceptable for V1.

## Observer Evidence Checklist

Record:

- session date;
- participant role;
- environment used;
- whether production data was avoided;
- whether real provider/payment activity was avoided;
- tasks completed unaided;
- tasks completed with light prompting;
- tasks completed only with heavy assistance;
- tasks not completed;
- exact friction notes;
- fields/copy that confused staff;
- wrong assumptions staff made;
- whether staff could create/review an offering without YAML;
- whether staff understood draft/review/apply;
- whether staff understood cash admin attestation;
- whether staff understood ECPay status truth;
- whether staff completed previous-month export workflow;
- any screenshots or recordings produced with permission;
- recommendation: accepted, accepted with gaps, retry required, or blocked.

## Friction Log Template

Use this table during the session.

| Time | Task | Staff action | Expected action | Assistance level | Friction type | Exact words/label causing confusion | Impact | Proposed follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| HH:MM | Example: Offering setup | Staff paused at field | Fill display name | None / light / heavy / blocked | Copy / layout / missing field / policy / training | Field label or staff quote | Low / medium / high / blocker | Fix copy / add help / product change / training |

Assistance level definitions:

- `none`: staff completed without help;
- `light`: observer repeated the task or pointed to a page, but did not explain product policy;
- `heavy`: observer explained field meaning, payment policy, or operational policy;
- `blocked`: staff could not proceed without product change, unavailable data, account/config access, or engineer intervention.

## Acceptance Criteria

Pass:

- staff completes all core tasks with none or light assistance;
- ordinary offering setup does not require YAML editing or engineer-led interview;
- staff understands draft/review/apply responsibility;
- staff can find orders and payment status;
- staff can explain cash as admin-attested;
- staff can explain ECPay completed/pending/failed/refunded boundaries;
- staff can select previous month and identify CSV export;
- no production/provider/server/secret/data boundary is crossed.

Accepted with gaps:

- staff completes all core tasks, but needs training/help text for some labels;
- no blocker prevents ordinary operation;
- gaps can be addressed in the future help guide or small copy improvements.

Retry required:

- staff cannot complete one or more core tasks without heavy assistance;
- ordinary offering setup still depends on owner/engineer translation;
- payment/accounting status meaning is misunderstood in a way that could cause operational mistakes;
- previous-month export cannot be completed or explained.

Blocked:

- rehearsal cannot run without production data, real provider changes, secrets, deployment, or production account changes;
- admin workflow cannot represent an ordinary offering the temple needs;
- staff cannot proceed without YAML editing;
- required route/workflow is missing from the product.

## V1 Blocking Rules

The rehearsal blocks V1 acceptance if any of these occur:

- staff must edit YAML to onboard ordinary offerings;
- staff cannot submit or review an ordinary offering through admin UI;
- staff cannot find or interpret registrations/orders;
- staff treats pending/failed/refunded payments as received revenue after the rehearsal;
- staff cannot distinguish cash admin attestation from provider-confirmed payment;
- staff cannot run or identify the previous-month export process;
- the session requires production data/provider/secrets/deploy/server changes to proceed;
- the observer cannot produce evidence strong enough for an acceptance record.

## Post-Session Decision Path

After the session:

1. Create a return record with task-by-task evidence.
2. Create an eval record with the observer checklist and friction table.
3. Create acceptance record:
   - `accepted` only if all core tasks pass with no material gaps;
   - `accepted_with_gaps` if V1 remains usable but needs help-guide/training/copy follow-up;
   - `retry_required` if core task usability failed but is fixable;
   - `blocked` if product/environment boundaries prevent rehearsal.
4. Create execution record preserving who ran the rehearsal, environment, and boundary confirmations.
5. If retry is required, create the next implementation handoff from the specific friction, not from vague dissatisfaction.

## Help Guide Follow-Up

The comprehensive help guide remains a separate workflow after V1 behavior settles. The rehearsal should collect help-guide topics but must not delay the session waiting for the guide.

Minimum help-guide topics learned from this packet:

- temple profile;
- offering setup draft/review/apply;
- registrations/orders;
- cash received;
- ECPay statuses;
- failed/cancelled/refunded payment meaning;
- previous-month export;
- permission roles and owner/admin responsibility.
