# ADMIN PORTAL REFINE LEDGER

## Purpose

- Running ledger for admin-portal refinements discovered during QA.
- Keep this file focused on admin operations, tooling, and staff UX.

## Active Tasks

### Admin Dashboard KPI Refinement (Ops-Useful)

- [x] Remove low-value KPI (`Pending admin activation`) from primary dashboard KPI row.
- [x] Replace dashboard KPI row with registration/payment operations signals.
- [x] Change revenue KPI to month-to-date (`this month`) instead of all-time.
- [ ] Add `New patrons (this month)` to core KPI row.
- [ ] Keep core KPI row focused on daily operations:
  `New patrons (this month)`, `Pending registrations`, `Unpaid registrations`, `Revenue (this month)`.
- [ ] Add second dashboard KPI/queue row for operations alerts (phase-in as features land).
- [ ] Include `Expiring unpaid holds` in second row (required reminder, not optional).
- [ ] Add `Open assistance requests` in second row when Request Assistance workflow ships.
- [ ] Add `Unread contact inquiries` in second row when inquiry inbox/queue tracking exists.

Notes:
- `New registrations (7 days)` is currently useful during transition, but should not crowd out `New patrons (this month)` once the core row is finalized.
- Keep admin/staff counts out of the primary KPI row unless the screen is explicitly owner/admin-management focused.

### Gatherings Orders / Attendance Workflow

- [x] Keep gathering orders form minimal (attendance-first) and avoid offering-template metadata sections.
- [x] Confirm minimal gathering form behavior for both create and edit.
- [x] Ensure gathering registration detail page also stays minimal and readable.
- [x] Add attendance-oriented fields only if needed (avoid schema creep).

Notes:
- Gathering entry point now labels `View attendance` from gatherings index and routes to `/admin/gatherings/:gathering_id/orders`.
- Gathering-specific copy is used on list/form/detail pages (`attendance` wording) while preserving shared registration/payment internals.

### Admin IA (Ops-First Navigation)

- [x] Add dedicated `Registrations` screen as daily operations entry point.
- [x] Prioritize nav order for ops flow: `Dashboard -> Registrations -> Orders -> Payments`.
- [x] Keep `Offerings` focused on template CRUD and expose direct `New registration` action from each offering row.
- [x] Keep management/admin screens grouped after ops: profile, content, patrons, archives, permissions.

### Registration Edit Safety

- [x] Treat core registration identity/order fields as immutable after create (`patron`, `registrant scope/dependent`, `quantity`, `price/currency`).
- [x] Keep edit flow focused on offering metadata adjustments only.
- [x] Disable gathering attendance edit actions/routes (view-only after creation).

### Dependent Selection in Admin Registration

- [x] Add a second selector after patron selection: `Registrant = Patron / Dependent`.
- [x] Load selected patron dependents into that selector.
- [x] Persist `metadata.registrant_scope` + `metadata.dependent_id` on admin-created registrations.
- [x] Display registrant name (not only account owner) in admin orders/attendance tables.

### Existing Registration Resolution (Least Brittle)

- [x] Add server-side lookup for existing registration by:
  `(registrable_type, registrable_id, user_id, metadata.registrant_scope, metadata.dependent_id)`.
- [x] If existing record is found, route admin to edit/show instead of silently creating a duplicate.
- [x] Reuse the same lookup logic service in both admin and account flows.

### Accounting / Reporting

- [x] Keep gatherings clearly filterable/separable in orders and payment reporting.
- [x] For free gatherings, surface `no payment required` state clearly in admin tables.
- [x] For paid gatherings, keep standard payment lifecycle and ledger compatibility.

### QA Checklist

- [x] Admin creates gathering registration for patron self.
- [x] Admin creates gathering registration for a dependent.
- [x] Existing-registration redirect/edit path works for both self and dependent.
- [x] Orders list and registration detail show registrant clearly.
- [x] Free vs paid gathering accounting states render correctly.

## Open Decisions

- [x] Enforce one active registration per registrant per gathering (duplicates route to existing registration edit flow).

## Decision Notes

- Offerings can support repeat registrations across cycles using `registration_period_key` rollover (e.g., `2026-*` -> `2027-*`) without cloning offerings each year.
- Gatherings are one-off/time-bounded; keep strict duplicate prevention per registrant per gathering (no period-key cycle override needed).
