# Handoff: Admin Onboarding QA Sweep

Handoff id: `shengfukung-2026-06-12-admin-onboarding-qa-sweep`

Created: 2026-06-12

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: local prototype QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Run a bounded local QA sweep of the admin onboarding surfaces after the offering setup, registration intake, local review environment, and layout fixes.

This sweep should preserve evidence about what works now, what remains risky, and whether a focused retry handoff is needed.

## Context

Recent checkpoints added:

- offering setup admin workflow;
- apply-draft-to-db-offering prototype;
- supported field catalog;
- registration intake authoring;
- admin layout width restoration;
- offering setup two-column restoration;
- gathering form two-column restoration;
- isolated local admin review server.

The user reported that offering setup now matches the approved two-column layout and that gatherings was fixed after the retry. The next need is a broader local sweep, not a new product feature.

## Required Review

Use only local development/review resources. Prefer the isolated local review workflow:

```text
bin/review_admin_server
```

Verify as much as possible through direct local evidence:

- admin login with the disposable review account;
- dashboard and admin navigation render;
- offering setup index/new/edit/show/review/apply flow is reachable;
- setup field selections and registration intake selections persist;
- option rows remain usable after save;
- reviewed drafts are locked from edit;
- apply creates only a draft service target;
- no YAML file is written from admin actions;
- gatherings new form keeps the desktop two-column layout;
- basic gathering create/list flow still works;
- focused request/layout tests still pass.

If authenticated in-app Browser automation is available, capture browser geometry or screenshot evidence for the main offering setup and gathering forms. If Browser text entry or policy blocks authenticated review, continue with HTTP, DB, rendered HTML, route, and test evidence, then record the Browser limitation as residual risk.

## Non-Goals

- Do not deploy.
- Do not change server configuration.
- Do not rotate or access secrets.
- Do not change payment provider configuration.
- Do not touch production data.
- Do not publish offerings.
- Do not write YAML files from admin.
- Do not implement event apply.
- Do not redesign accounting.
- Do not change unrelated app behavior.
- Do not move existing `ops/docs/` history.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- review environment;
- exact workflow coverage;
- HTTP, DB, browser, and test evidence gathered;
- defects found or fixed;
- files changed;
- verification commands and results;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation;
- payment/accounting/admin/temple boundary confirmation;
- deployment/server/secrets/production-data impact;
- YAML-write confirmation;
- draft-only apply confirmation;
- event apply confirmation;
- residual risk;
- next owner.

Also create matching acceptance, execution, and eval records if the sweep completes.

Do not paste full records in chat when files exist.
