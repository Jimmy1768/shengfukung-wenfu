# Handoff: Admin Layout Width Regression

Handoff id: `shengfukung-2026-06-12-admin-layout-width-regression`

Created: 2026-06-12

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: prototype

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Fix the admin console layout regression visible in manual browser screenshots from 2026-06-12.

The current local admin UI shrink-wraps page cards and forms into narrow columns, leaving a large unused lavender workspace. This differs from the approved/deployed admin layout and makes the offering setup form difficult to review.

## Evidence

User-provided screenshots showed:

- dashboard cards constrained to a narrow left column;
- offerings index header constrained to a narrow card with large empty right side;
- gathering and offering setup forms constrained to narrow cards;
- admin setup form fields not using the available desktop workspace.

Inspection found the served admin CSS uses `fit-content(...)` for `.admin-stack__row > .stack-item`, causing content cards to shrink-wrap.

## Required Work

- Remove or override the shrink-wrap behavior for admin stack items.
- Make normal admin cards and wide/form cards use the available admin main width on desktop while preserving responsive behavior.
- Keep narrow form/card variants intentionally constrained where explicitly marked.
- Rebuild the committed admin CSS asset.
- Add a cheap regression check if practical.

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
- layout defect fixed;
- files changed;
- verification commands and results;
- skipped checks and reasons;
- deployment/server/secrets/production-data boundary;
- residual risk;
- next owner.
