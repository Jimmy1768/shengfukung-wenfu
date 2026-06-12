# Handoff: Accounting Large-Data Admin QA Sweep

Handoff id: `shengfukung-2026-06-12-accounting-large-data-admin-qa-sweep`

Created: 2026-06-12

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: local prototype QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Run a bounded local QA sweep of the admin accounting, orders, payments, registrations, and dashboard surfaces with realistic larger local data.

The purpose is to answer whether the accounting/admin reporting surfaces are usable beyond "the code works" and to preserve concrete evidence for the next product decision.

## Context

The offering onboarding/admin setup workflow has local prototype acceptance with gaps. The remaining product risk called out by the owner is accounting usefulness at larger data volume.

Mobile/Expo is explicitly out of scope because the Expo app has not been created yet.

## Required Review

Use only local development/review resources, preferably:

```text
RAILS_ENV=development
PGDATABASE=golden_template_review
RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session
```

Seed disposable local review data large enough to expose usefulness/performance issues without touching production. Include a mix of:

- event/service/gathering-like offerings;
- paid, pending, refunded, and no-payment-required records;
- multiple payment methods;
- enough records to test summary totals, table limits, filters, and exports;
- old and current-month records for date/preset behavior.

Verify:

- dashboard metrics render and remain useful;
- registrations page renders recent records;
- orders page renders recent and unpaid queues;
- orders filters isolate offering kinds/statuses where available;
- payments page renders summary totals, breakdowns, filters, and ledger table;
- payments CSV export respects current filters;
- archives page/export behavior remains usable for date ranges if applicable;
- local page response times are captured;
- no production, deploy, server, secret, or real payment-provider action occurs.

If a concrete bounded bug appears and can be safely fixed within this scope, fix it and rerun focused tests. If the issue is product/design usefulness rather than a clear bug, record it as residual risk or `retry_required` evidence instead of making broad changes.

## Non-Goals

- Do not work on mobile or Expo.
- Do not deploy.
- Do not change server configuration.
- Do not rotate or access secrets.
- Do not change payment provider configuration.
- Do not call real payment providers.
- Do not touch production data.
- Do not redesign accounting.
- Do not implement new product features unless a small bounded bug fix is required by the sweep.
- Do not move existing `ops/docs/` history.

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- review environment;
- seeded data volume and shape;
- exact workflow coverage;
- route, DB, browser, and test evidence gathered;
- response-time observations;
- usefulness findings;
- defects found or fixed;
- files changed;
- verification commands and results;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation;
- payment/accounting/admin/temple boundary confirmation;
- deployment/server/secrets/production-data impact;
- residual risk;
- next owner.

Also create matching acceptance, execution, and eval records if the sweep completes.

Do not paste full records in chat when files exist.
