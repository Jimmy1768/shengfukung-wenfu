# Handoff: Admin Ledger Count Cues

Handoff id: `shengfukung-2026-06-13-admin-ledger-count-cues`

Created: 2026-06-13

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: local prototype implementation

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow`.

## Goal

Address the accepted-with-gaps finding from the accounting large-data admin QA sweep: orders and payments ledgers cap visible rows but do not clearly tell the operator how many matching records exist or when additional matching records are hidden beyond the cap.

Implement small admin UI count/cap cues for the existing orders and payments index pages.

## Context

The prior sweep accepted the local prototype with gaps:

- payments ledger rendered 200 rows under large filtered data;
- orders rendered 50 rows in needs-payment and recent sections;
- CSV exports preserved full filtered payments access;
- the main remaining usability gap was that capped ledgers did not expose total matching record count or hidden-row cues.

This workflow should reduce that operator ambiguity without introducing pagination or broader accounting changes.

## Required Implementation

For `/admin/payments`:

- Preserve current filtering, summary, breakdown, and CSV export behavior.
- Keep the existing visible cap of 200 payments.
- Compute the total matching payment count for the active filters.
- Show a localized note near the ledger title that states how many payments are visible out of how many matching payments.
- If more rows match than are visible, state that the visible table is capped and CSV export contains the full filtered set.

For `/admin/orders`:

- Preserve current filtering and two-section behavior.
- Keep the existing visible cap of 50 unpaid/needs-payment rows and 50 paid/recent rows.
- Compute total matching counts separately for unpaid/needs-payment and paid/recent sections.
- Show localized notes near each section title that state how many records are visible out of how many matching records.
- If more rows match than are visible, state that the visible table is capped and filters can narrow the list.

## Non-Goals

- Do not add pagination.
- Do not redesign the accounting UI.
- Do not change accounting totals or payment summary calculations.
- Do not change CSV export scope.
- Do not work on mobile or Expo.
- Do not deploy.
- Do not change server configuration.
- Do not rotate or access secrets.
- Do not change payment provider configuration.
- Do not call real payment providers.
- Do not touch production data.
- Do not move existing `ops/docs/` history.

## Verification

Run focused tests covering:

- payment ledger count/cap cue for more than 200 matching payments;
- order needs-payment and recent count/cap cues for more than 50 matching records;
- existing admin orders/payments access and gathering accounting tests.

Also run:

```bash
git diff --check
```

## Expected Return

Create a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Return must include:

- objective;
- files changed;
- implementation summary;
- localized copy added;
- verification commands and results;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation;
- payment/accounting/provider boundary confirmation;
- deployment/server/secrets/production-data impact;
- residual risk;
- next owner.

Also create matching acceptance, execution, and eval records if the workflow completes.

Do not paste full records in chat when files exist.
