# Handoff: Local Admin Agent QA Sweep

Handoff id: `shengfukung-2026-06-14-local-admin-agent-qa-sweep`

Created: 2026-06-14

Coordinator: Shengfukung Wenfu coordinator/implementation thread

Target: Shengfukung Wenfu coordinator/implementation thread

Mode: local browser QA and focused fix

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Take over local QA testing for the admin rehearsal path using the local review server and isolated `golden_template_review` database.

This is agent QA only. It does not replace the real temple admin/staff rehearsal required for V1 acceptance.

## Scope

Verify:

- admin login;
- dashboard navigation;
- temple profile;
- offering management;
- offering setup draft save/submit/review/apply;
- applied offering visibility;
- registrations/orders;
- cash/payment wording;
- previous-month payment export path;
- ECPay/payment settings visibility.

Fix small product issues found during the local QA sweep when they are clearly bounded and low risk.

## Non-Goals

- Do not contact a real temple.
- Do not use production data.
- Do not deploy.
- Do not change server/provider configuration.
- Do not access or rotate secrets.
- Do not call real payment providers.
- Do not open or submit to ECPay.
- Do not work on mobile/Expo.
- Do not treat this as real-staff acceptance.

## Expected Return

Create return, eval, acceptance, and execution records that include:

- local browser QA coverage;
- any findings;
- product/code changes;
- test commands/results;
- boundary confirmation;
- residual gap that real temple staff rehearsal remains pending.
