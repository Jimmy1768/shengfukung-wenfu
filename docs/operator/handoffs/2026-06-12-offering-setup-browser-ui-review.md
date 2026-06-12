# Handoff: Offering Setup Browser UI Review

Handoff id: `shengfukung-2026-06-12-offering-setup-browser-ui-review`

Created: 2026-06-12

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: prototype

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Run a local browser/manual review of the offering setup admin workflow after registration intake authoring.

The purpose is to verify the real rendered admin screens remain usable after adding registration intake field groups to the setup draft form.

## Context

Recent accepted checkpoints:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-offering-setup-admin-ui-rehearsal-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-offering-setup-registration-intake-authoring-acceptance.md`

The request-level tests prove the logic, but the browser review should check rendered usability:

- page layout does not collapse;
- setup field groups and registration intake groups are visible and understandable;
- option rows remain usable;
- create/edit/submit/review/apply can be completed through the UI;
- applied draft service remains draft-only;
- no YAML writes occur.

## Required Review

Use a local-only Rails test/development server and in-app browser. Do not use production.

Review at least one realistic service setup through the browser:

- light/lamp service with more than three `lamp_type` options;
- selected registration intake fields across order/contact/logistics/ritual sections.

Verify:

- setup draft index/new/show/edit pages render without obvious layout breakage;
- selected admin setup fields persist after saving;
- option rows render all entered options after saving;
- selected registration intake fields persist after saving;
- reviewed drafts are locked from edit;
- apply creates a draft service target;
- no production, server, secret, payment, or deployment action occurs.

If a concrete UI defect appears and can be fixed safely within this bounded scope, fix it and rerun focused tests. If there is a larger product gap, stop with `retry_required` evidence.

## Non-Goals

- Do not deploy.
- Do not change server config.
- Do not rotate or access secrets.
- Do not touch payment provider configuration.
- Do not touch production data.
- Do not publish offerings.
- Do not write YAML files from admin.
- Do not implement event apply.
- Do not redesign accounting.
- Do not move existing `ops/docs/` history.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- browser/server environment used;
- pages/actions reviewed;
- defects found or fixed;
- repo path;
- branch name;
- latest commit hash and subject if committed, or uncommitted state if not;
- staged, unstaged, untracked, committed, and pushed state;
- ahead/behind state if known;
- files changed;
- verification commands and pass/fail output;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation;
- payment/accounting/admin/temple boundary confirmation;
- deployment/server/secrets/production-data impact;
- YAML-write confirmation;
- draft-only apply confirmation;
- event apply confirmation;
- residual risk;
- next owner.

Do not paste the full return in chat when the file exists.
