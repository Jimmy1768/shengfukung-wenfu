# Admin Accounting And Archives Workflow Plan

## Purpose

- Define the admin-side monthly accounting workflow that temple staff actually need to run.
- Close the gap between current CSV export tooling and the expected "monthly report" task.
- Refine Archives so staff can search by patron name without being forced to enter a date range first.

## Why This Needs A Dedicated Plan

Current repo reality:

- financial exports already exist, but they are export primitives, not a complete monthly reporting workflow
- exports are CSV, not true Excel-native `.xlsx`
- Archives currently require a date range to load results
- Archives lookup is year-based and not designed around "find one patron, then show everything"

Temple-admin expectation:

- complete a monthly accounting/reporting task with minimal friction
- export data into a spreadsheet-compatible format for bookkeeping handoff
- search Archives by patron name directly, especially when staff know the person but not the exact date window

## Scope

### In Scope

- Admin monthly accounting workflow design
- Monthly report filters/defaults
- Spreadsheet export format decision
- Archive search behavior for patron-name-first lookup
- Safe query rules when date range is omitted
- Audit/export logging expectations

### Out Of Scope

- Full accounting product redesign
- External government tax reporting integrations
- Advanced BI/dashboarding
- Non-admin public/account portal archive search

## Current System Reality

### Existing Exports

- `/admin/archives` already supports:
  - registrations export
  - payments export
  - certificates export
- export format is currently CSV
- payment reporting/export also exists in the payments/admin reporting layer

### Existing Archive Search Constraint

- archive detail results only load when both:
  - `start_date`
  - `end_date`
  are supplied
- if no range is selected, the page intentionally stays empty
- current archive lookup service is year-scoped, not patron-name-first

## Product Goals

### Goal A: Monthly Accounting Workflow

As a temple admin, I want to:

- choose a month quickly
- review that month’s registrations/payments totals
- export a spreadsheet that accounting staff can open directly

without manually composing large date ranges or using multiple screens unnecessarily.

### Goal B: Archives Name-First Lookup

As a temple admin, I want to:

- search by patron name alone
- if that search clearly identifies one patron, see that patron’s archive history even without date filters

because staff often remember the person, not the exact date.

## Monthly Accounting Workflow

### Required Admin Task Shape

Primary workflow should support:

1. choose a reporting month
2. view matching payments/registrations summary
3. optionally narrow by offering / payment method / status
4. export the report

### Recommended UX

Add a dedicated monthly reporting mode under existing finance/admin surfaces:

- primary entry point:
  - `/admin/payments`
- supporting lookup/history surface:
  - `/admin/archives`

- default filter preset:
  - current month
- quick presets:
  - this month
  - last month
  - custom range
- summary row/cards:
  - total paid amount
  - paid count
  - unpaid count
  - refunded count

### Export Format Decision

Phase 1:

- keep CSV as the backend truth because it already exists and is reliable
- improve naming/column shape for accounting handoff
- explicitly label the export action as spreadsheet-compatible if needed

Phase 2:

- add real `.xlsx` export only if temple staff confirm CSV is not sufficient in practice

Reason:

- Excel can open CSV directly
- true `.xlsx` adds implementation weight and formatting decisions
- the first gap is workflow/shape, not file format sophistication

## Archives Name-First Search

### Requested Behavior

If the admin enters a patron name and no date range:

- if one patron is clearly found, return all archive records for that patron
- do not force date selection first

### Recommended Safe Rule

When no date range is present:

1. run a patron lookup by name/email/phone
2. if zero matches:
   - show no archive rows
   - show "no patron found"
3. if more than one likely match:
   - do not load all archives
   - require the admin to refine the query or choose a patron
4. if exactly one patron is matched:
   - load archive results for that patron across all dates

This prevents accidental broad unbounded archive queries while matching staff workflow.

### Date-Range Rule After This Change

- Date range remains supported and should continue to work as it does now.
- If a date range is provided, use the existing filtered archive behavior.
- Patron-specific lookup without dates is an exception path, not a full removal of date filtering.

## Search Inputs

### Minimum Useful Inputs

- patron name
- email
- phone

### Preferred Matching Behavior

- exact and partial name match
- case-insensitive email match
- normalized phone match

## Data Access / Performance Guardrails

- Never load "all archives for everyone" when no filters are present.
- Only allow date-less archive loading when the query resolves to exactly one patron.
- Keep result caps/pagination for very large patron histories if needed.
- Ensure exports from patron-specific archive view only include that patron’s records.

## Audit / Permissions

- Existing archive access permissions remain:
  - `view_financials`
  - `export_financials`
- Export actions must continue to create `SystemAuditLog` entries.
- Name-first patron lookup should not bypass temple scope.

## Implementation Phases

### Phase 1 — Workflow Definition

- [x] Define the exact monthly report screen entry point:
  - primary monthly reporting lives in `/admin/payments`
  - `/admin/archives` remains the history / troubleshooting surface
- [ ] Confirm the minimum monthly summary metrics.
- [ ] Confirm whether CSV is acceptable for v1 monthly handoff.

### Phase 2 — Monthly Report UX

- [x] Add month presets (`this month`, `last month`, `custom`).
- [x] Add month-first filtering without manual date typing.
- [x] Show summary totals above the report table.
- [ ] Keep offering/payment/status filters compatible with this flow.

### Phase 3 — Export Refinement

- [x] Normalize exported column order/labels for bookkeeping.
- [x] Use month-aware filenames.
- [x] Ensure exports match visible filters exactly.
- [ ] Decide whether `.xlsx` is needed after v1 staff validation.

### Phase 4 — Archives Name-First Search

- [x] Add patron lookup input(s) to `/admin/archives`.
- [x] Implement exact-one-patron resolution rule for date-less search.
- [x] Show resolve/refine UI when multiple patrons match.
- [x] Load full cross-date archive history only for the resolved patron.

### Phase 5 — Regression Coverage

- [x] Monthly preset returns correct date window.
- [x] Export respects active month/filter state.
- [ ] No-date archive search with zero patron matches returns empty state.
- [x] No-date archive search with multiple patron matches requires refinement.
- [x] No-date archive search with one patron match returns that patron’s full archive history.
- [ ] Temple scope and export permissions remain enforced.

## Open Decisions

- [x] Monthly reporting lives under `Payments`; `Archives` is the lookup/history surface.
- [ ] Is CSV sufficient for temple accounting handoff, or is `.xlsx` required?
- [ ] Should patron resolution show a picker list when 2-5 matches exist, or force search refinement?
- [ ] For one matched patron, should archive history include:
  - registrations
  - payments
  - certificates
  - all of the above by default?

## Recommended First Build Order

1. Implement patron-name-first archive lookup.
2. Add monthly date presets + summary row to the existing reporting screen.
3. Refine CSV output shape.
4. Defer true `.xlsx` unless staff explicitly reject CSV.

## Completed In Repo

- `/admin/archives` now supports patron-name-first lookup with no date range when the query resolves to exactly one temple patron.
- `/admin/archives` now supports month presets, a summary row, and filter-scoped exports for payments, registrations, and certificates.
- `/admin/payments` export now respects active filters and uses accounting-friendly CSV columns:
  - processed time
  - payment reference
  - patron
  - patron phone
  - offering type
  - offering
  - registration period key
  - payment method
  - status
  - amount
  - currency
  - recorded by

## Product Direction Confirmed

- `Payments` is the monthly reporting entry point because monthly reporting is normal operating work.
- `Archives` is the historical lookup surface used to dig up past records, especially when staff are investigating an issue.

## Regression Coverage Implemented

- `bin/rails test test/integration/admin/archives_access_test.rb`
  - month preset path
  - one-patron no-date archive lookup
  - ambiguous patron no-date archive lookup
  - patron-scoped archive payments export
- `bin/rails test test/services/reporting/payments_csv_exporter_test.rb test/integration/admin/orders_and_payments_access_test.rb`
  - accounting CSV column shape
  - payments export filter scoping
