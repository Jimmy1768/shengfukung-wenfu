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
- exclusive Handoff task: `019f5519-0f72-7273-b50e-65739e5a2a36`.

Wenfu Control must never target a Handoff owned by another Control. Retired
Control `019e5f01-c434-70c2-8225-5bc71dd83b8d` and retired Handoff
`019f5442-186d-7a61-8cf8-ebaf17ede89c` must never be targeted.

The Handoff writes its terminal return in its own task and stops. Return does
not deliver across tasks. Heartbeat is the sole Handoff wakeup path for Wenfu
Control.

Every executable handoff should declare the worker model and reasoning profile
explicitly. The current accepted default is GPT-5.4 with medium reasoning for a
bounded Handoff unless Wenfu Control records a different profile in the Handoff
itself.

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
