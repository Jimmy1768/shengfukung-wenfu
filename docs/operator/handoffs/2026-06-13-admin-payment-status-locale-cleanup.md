# Handoff: Admin Payment Status Locale Cleanup

Handoff id: `shengfukung-2026-06-13-admin-payment-status-locale-cleanup`

Created: 2026-06-13

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: local prototype implementation/QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Clean up the duplicate admin payment status locale definitions discovered during the admin accounting reconciliation-readiness pass.

The current Traditional Chinese admin locale has duplicate `admin.payments.statuses` blocks. The later block wins at runtime, so pending payment status renders as `待處理`. Make the status wording intentional and remove ambiguity without changing payment behavior.

## Required Review

Review:

- `rails/config/locales/admin.zh-TW.yml`;
- `rails/config/locales/admin.en.yml`;
- admin payments ledger/status filter rendering;
- focused tests that assert payment status labels.

If duplicate or ambiguous status locale keys exist, consolidate them in the smallest safe way and update focused tests to protect the chosen wording.

## Non-Goals

- Do not change payment status state machine behavior.
- Do not change payment filters or payment query semantics.
- Do not change accounting totals, CSV fields, provider flows, refunds, or cash-payment behavior.
- Do not call real payment providers.
- Do not change payment provider configuration.
- Do not deploy.
- Do not change server configuration.
- Do not access or rotate secrets.
- Do not touch production data.
- Do not work on mobile or Expo.
- Do not move existing `ops/docs/` history.

## Likely Acceptance Criteria

- `admin.payments.statuses` has one intentional definition per locale file.
- Admin payments ledger and filter status labels resolve consistently.
- Focused tests pass.
- `git diff --check` passes.
- No production-readiness or accounting-policy claim is made.

## Verification

Run focused admin payments/accounting tests:

```bash
RAILS_ENV=test bin/rails test test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/payments_flow_test.rb
```

Also run:

```bash
git diff --check
```

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- implementation summary;
- files changed;
- verification commands and results;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation;
- payment/provider/production-data boundary confirmation;
- residual risk;
- next owner.

Also create matching acceptance, execution, and eval records if the workflow completes.

Do not paste full records in chat when files exist.
