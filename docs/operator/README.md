# Shengfukung Wenfu Operator Workflow

This folder holds Shengfukung Wenfu-local handoff records used by Wenfu Control
and Wenfu Handoff tasks.

SourceGrid remains the cross-repo and product coordinator of record. These files
coordinate Shengfukung Wenfu-internal Rails, Vue, Expo, deployment, and docs
work only.

These records support Codex collaboration only. Codex is not governed by
OperatorKit, and no OperatorKit kernel is installed into Codex for this repo.

## Folder Shape

- `docs/operator/workflows/`
  Active or durable local workflow packets.
- `docs/operator/handoffs/`
  Detailed Wenfu Control handoffs for Shengfukung Wenfu implementation,
  research, or docs tasks.
- `docs/operator/returns/`
  Detailed implementation or research returns from Wenfu Handoff tasks.
- `docs/operator/acceptances/`
  Wenfu Control acceptance, retry, rejection, blocked, or route-onward
  decisions.
- `docs/operator/execution_records/`
  Durable records of what happened after a return and acceptance decision.
- `docs/operator/friction_records/`
  Repeated or risky workflow gaps that should change future coordination.
- `docs/operator/eval_records/`
  Eval or verification evidence that should be preserved separately from a return.

## Pointer-Only Chat Rule

When a handoff, return, acceptance, execution record, friction record, or eval
record exists as a file, chat should only point to the file.

Required chat format:

```text
Done.

File:
<absolute path to handoff/return/acceptance/execution/friction/eval record>

Next:
<who should review or what should happen next>
```

Do not paste the full handoff or return in chat if the file exists.

Do not ask the receiving thread to infer the file path.

Do not let Handoff tasks decide acceptance. Acceptance belongs to Wenfu
Control only.

## Dispatch

Wenfu Control dispatches work only to an exact-idle Wenfu Handoff task. It does
not queue new work behind an active task.

## Control/Handoff Binding

The active Wenfu Control/Handoff binding is one-to-one:

- owner Control task: `019f5518-af59-74f3-af7f-a37241bf418d`;
- exclusive Handoff task: `019f55bd-3447-74f3-8225-eabfdc511e64`.

Wenfu Control must never target a Handoff owned by another Control. Retired
Control `019e5f01-c434-70c2-8225-5bc71dd83b8d` and retired Handoff
`019f5442-186d-7a61-8cf8-ebaf17ede89c` must never be targeted. Handoff
`019f5519-0f72-7273-b50e-65739e5a2a36` was archived after an interrupted,
unavailable job and must also never be targeted.

The Handoff writes its terminal return in its own task and stops. Return does
not deliver across tasks. After all mutations and checks, Handoff sends one
minimal terminal wake signal to its bound Control as its final tool action. The
signal contains only `handoff_thread_id`, terminal status, and the instruction
to read the Handoff terminal return once; it is not the return itself.

The explicit terminal wake signal is the primary continuation path. The
workload-sized Heartbeat remains fallback recovery if the wake fails or the
task becomes unreachable. Control never polls, reads an active transcript,
narrates Handoff progress, or sends status steering.

Control and Handoff are a long-lived pair. Completed, blocked, and failed end a
bounded job, not the Handoff task. After Control review, the healthy Handoff
returns to idle and is reused. Archive it only when the task itself is
unresponsive, unreachable, corrupted, retired, or in system error, and create
a replacement only after that archival.

Mirrored Codex Work Mode source truth: OperatorKit commits `5f011c4e`,
`9854262d`, `b5175f8d`, and `859bf872`.

Wenfu Control's requested repository-Control profile is GPT-5.6-sol / high.
Wenfu Control owns repo-local planning, readiness, Handoff construction,
acceptance review, approvals, and Git state. Kernel architecture,
cross-repository contracts, and authority-boundary analysis route
Control-to-Control to OperatorKit Control instead of increasing Wenfu Control
to xhigh. This requested profile is configuration evidence, not runtime
telemetry proof.

Handoff has no permanent model or reasoning classification. Control selects a
profile for every bounded job and records `requested_model`,
`requested_reasoning`, `execution_profile`, and `selection_reason` in both the
packet and dispatch override. The same bound Handoff may use different profiles
for serial jobs.

Profile baselines:

- mechanical docs, tests, and fixtures: GPT-5.4-mini / medium;
- ordinary bounded implementation: GPT-5.4 / medium;
- architecture, persistence, authority, security, or cross-contract-sensitive
  implementation: GPT-5.4 / high.

Requested model and reasoning are configuration evidence, not proof of actual
runtime telemetry.

## Authority

Shengfukung Wenfu uses manual Wenfu Control/Handoff coordination in this lane
unless a later owner decision upgrades the permission model.

This folder does not authorize automation, release promotion, deployment,
server changes, secret access, payment changes, account changes, destructive
actions, or production data changes.

## Return Requirements

Implementation returns should include:

- objective;
- completed work;
- repo path;
- branch role and branch name;
- latest commit hash and subject;
- staged, unstaged, untracked, committed, and pushed state;
- ahead/behind state if known;
- files changed;
- verification commands and pass/fail output;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation if touched;
- payment, auth, temple, or admin boundary confirmation if touched;
- deployment, server, OTA, or public-site impact;
- residual risk;
- production gaps;
- next owner.

## Acceptance

Wenfu Handoff tasks report evidence. They do not decide acceptance.

Acceptance records should use one of:

```text
accepted
accepted_with_gaps
retry_required
rejected
blocked
meeting_required
promote
watch
```

Do not accept production-readiness, deployment, payment, or public-site claims
from prototype evidence alone.

## Existing Ops Docs

This repo also has `ops/docs/` for operational commands, plans, references,
tickets, and deployment-oriented notes. Do not move that history into
`docs/operator/`.

Use `docs/operator/` only for OperatorKit handoff, return, acceptance,
execution, friction, eval, and workflow records.
