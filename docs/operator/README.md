# Shengfukung Wenfu Operator Workflow

This folder holds Shengfukung Wenfu-local OperatorKit records.

SourceGrid remains the cross-repo and product coordinator of record. These files
coordinate Shengfukung Wenfu-internal Rails, Vue, Expo, deployment, and docs
work only.

## Folder Shape

- `docs/operator/workflows/`
  Active or durable local workflow packets.
- `docs/operator/handoffs/`
  Detailed coordinator handoffs for Shengfukung Wenfu implementation, research, or docs threads.
- `docs/operator/returns/`
  Detailed implementation or research returns from local threads.
- `docs/operator/acceptances/`
  Coordinator acceptance, retry, rejection, blocked, or route-onward decisions.
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

Do not let implementation threads decide acceptance.

## Authority

Shengfukung Wenfu uses manual OperatorKit Level 0/1 in this lane unless a later
owner decision upgrades the permission model.

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

Implementation threads report evidence. They do not decide acceptance.

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
