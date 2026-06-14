# Handoff: Real Temple Admin/Staff Rehearsal Readiness

Handoff id: `shengfukung-2026-06-14-real-temple-admin-staff-rehearsal-readiness`

Created: 2026-06-14

Coordinator: Shengfukung Wenfu coordinator/implementation thread

Target: Shengfukung Wenfu implementation thread

Mode: repo-local rehearsal packet and local dry-run

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Prepare the real temple admin/staff rehearsal packet required by the V1 acceptance threshold, without contacting a real temple, touching production data, deploying, changing server/provider configuration, or creating automation.

This workflow should make the next human rehearsal executable:

- staff task script;
- observer script;
- success criteria;
- friction log template;
- V1 blockers;
- local dry-run evidence that the rehearsal path maps to existing admin console surfaces.

## Required Context

Read before implementation:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-help-guide-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-14-previous-month-accounting-export-rehearsal-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-ecpay-default-path-local-verification-return.md`

## Required Review

Review the existing local admin/rehearsal evidence for:

- temple profile;
- offering setup draft/review/apply;
- registrations and orders;
- cash receipt/admin-attested payment;
- ECPay status understanding;
- previous-month accounting export;
- help guide follow-up boundary.

## Implementation Scope

Create a durable rehearsal packet under `docs/operator/workflows/` that can be used by the owner/observer during the real temple staff session.

The packet must include:

- session preflight;
- staff-facing task script;
- observer evidence checklist;
- success criteria;
- V1 blocker criteria;
- friction log template;
- post-session decision path;
- explicit production/provider/data boundaries.

Run a local dry-run against the review admin console where useful to confirm the packet maps to current admin surfaces. This can be browser-based or request-stack based, but must use local review data only.

## Non-Goals

- Do not contact a real temple.
- Do not invite or change real admin accounts.
- Do not use production data.
- Do not deploy.
- Do not change server configuration.
- Do not access or rotate secrets.
- Do not change payment provider configuration.
- Do not call real payment providers.
- Do not change real ECPay merchant configuration.
- Do not create automation.
- Do not implement product code unless a tiny doc/test-only correction is needed to make the rehearsal packet accurate.
- Do not work on mobile or Expo.
- Do not build the comprehensive help guide yet.
- Do not move existing `ops/docs/` history.

## Acceptance Criteria

- Rehearsal packet exists and is specific enough to run without asking the receiving thread to infer scope.
- Packet covers ordinary offering onboarding without manual YAML editing by temple staff.
- Packet covers registrations/orders, cash receipt, ECPay status interpretation, and previous-month export.
- Packet defines what counts as pass, accepted gap, retry required, or blocked.
- Packet includes a friction log template.
- Local dry-run confirms the packet maps to existing admin routes/surfaces.
- Verification includes `git diff --check`.
- No production/provider/server/secret/payment/data action occurs.

## Verification

Run:

```bash
git diff --check
```

Use local browser or request-stack dry-run for admin route/surface evidence.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- reviewed decision/context records;
- packet summary;
- local dry-run evidence;
- files changed;
- verification commands and results;
- skipped checks and reasons;
- production/provider/secret/data boundary confirmation;
- residual risk;
- follow-up gaps;
- next owner.

Also create matching eval, acceptance, and execution records if the workflow completes.

Do not paste full records in chat when files exist.
