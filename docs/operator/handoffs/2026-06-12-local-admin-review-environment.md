# Handoff: Local Admin Review Environment Isolation

Handoff id: `shengfukung-2026-06-12-local-admin-review-environment`

Created: 2026-06-12

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: local workflow

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Stabilize local browser QA for the admin console so Rails test runs no longer log out the browser session or delete the disposable reviewer account.

## Problem

The current manual/browser review server has been run with `RAILS_ENV=test` against `golden_template_test`. Focused Rails test commands also use that same database. Rails test setup can purge/reload the database, which deletes the reviewer user and invalidates the browser session.

There is also a cookie collision risk: the app session key currently defaults to `_initial_session`, which can collide with other local Rails apps on `127.0.0.1` because cookies are scoped by host, not port.

## Required Work

- Add a local-only workflow for admin browser review that does not use `RAILS_ENV=test`.
- Use an isolated local review database, separate from `golden_template_test`.
- Use a distinct local review session cookie key.
- Provide a repeatable way to create/reset the disposable reviewer admin account.
- Keep production defaults unchanged unless explicit local environment variables are set.
- Add focused verification for the new local workflow helpers.

## Non-Goals

- Do not deploy.
- Do not change production server config.
- Do not rotate or access secrets.
- Do not change payment/accounting behavior.
- Do not touch production data.
- Do not change product UI behavior.
- Do not move `ops/docs/` history.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- implementation summary;
- files changed;
- verification commands and results;
- local usage instructions;
- skipped checks and reasons;
- deployment/server/secrets/production-data boundary;
- residual risk;
- next owner.
