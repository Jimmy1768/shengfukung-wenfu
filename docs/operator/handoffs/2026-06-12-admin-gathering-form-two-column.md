# Handoff: Admin Gathering Form Two-Column Layout

Handoff id: `shengfukung-2026-06-12-admin-gathering-form-two-column`

Created: 2026-06-12

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: prototype

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Fix the admin gathering create/edit form layout after manual browser review confirmed that offering setup now renders correctly but gatherings still render as one long narrow column.

The intended result is a desktop two-column gathering form that uses the same admin form stage conventions as the repaired offering setup flow, while preserving the current gathering behavior and params.

## Context

User review evidence:

- Offering setup form now renders in the expected desktop two-column layout.
- Gathering create form remains constrained inside a narrow card and appears as one long column.
- The gathering form already has a `.gathering-form` grid rule, but the later `.form-stack` CSS rule overrides its `display: grid`, so the form effectively behaves as a stacked flex column.

Relevant local files:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/gatherings/new.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/gatherings/edit.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/gatherings/_form.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/stylesheets/admin/_components.scss`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/public/backend/assets/admin.css`

## Required Work

- Move the gathering form out of the narrow header card on new/edit pages.
- Make the gathering form render as a fluid admin stack item.
- Organize gathering fields into desktop two-column form sections/stages.
- Preserve existing form param names, free/paid toggle behavior, date range behavior, media upload behavior, and create/update controller behavior.
- Rebuild committed admin CSS.
- Add focused tests for the rendered gathering layout contract and CSS.

## Non-Goals

- Do not redesign the whole admin console.
- Do not change gathering publishing, registration, order, payment, accounting, or media upload behavior.
- Do not touch deployment, server config, secrets, payments, or production data.
- Do not move `ops/docs/` history.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- files changed;
- implementation notes;
- verification commands and results;
- skipped checks and reasons;
- deployment/server/secrets/production-data boundary;
- residual risk;
- next owner.
