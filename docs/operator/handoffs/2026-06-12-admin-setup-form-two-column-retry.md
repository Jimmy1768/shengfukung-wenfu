# Handoff: Admin Setup Form Two-Column Retry

Handoff id: `shengfukung-2026-06-12-admin-setup-form-two-column-retry`

Created: 2026-06-12

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: prototype

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Retry the admin layout regression fix after user review found the previous fix incomplete.

The prior checkpoint widened the outer title/card container, but the setup draft form sections still rendered in one column. The intended behavior is to match the approved droplet form pattern: outer admin stack sizing remains droplet-style, and offering/setup forms use a desktop two-column inner stage.

## Context

Prior incomplete checkpoint:

- Commit: `62bd799 Fix admin layout width regression`
- Acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-admin-layout-width-regression-acceptance.md`

User feedback:

- local layout still failed;
- the outer title container changed, but each section container remained single-column;
- approved droplet version had two-column form sections.

Droplet comparison:

- public deployed CSS at `https://shengfukung.com.tw/backend/assets/admin.css` preserves `fit-content(...)` outer stack sizing;
- deployed offering form CSS uses `.offering-form-stage` with two desktop columns at `min-width: 900px`.

## Required Work

- Restore droplet-style outer admin stack sizing.
- Make offering setup draft forms opt into the existing fluid/two-column offering form stage.
- Keep setup behavior unchanged.
- Rebuild committed admin CSS.
- Add focused tests for the actual setup form layout contract.

## Non-Goals

- Do not redesign the admin console.
- Do not change offering setup product behavior.
- Do not touch payments/accounting/deployment/server/secrets/production data.
- Do not write YAML from admin.
- Do not move `ops/docs/` history.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- what was wrong with the prior fix;
- droplet comparison result;
- files changed;
- verification commands and results;
- skipped checks and reasons;
- deployment/server/secrets/production-data boundary;
- residual risk;
- next owner.
