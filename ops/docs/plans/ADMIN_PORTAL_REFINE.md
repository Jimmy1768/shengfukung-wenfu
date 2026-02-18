# ADMIN PORTAL REFINE LEDGER

## Purpose

- Running ledger for admin-portal refinements discovered during QA.
- Keep this file focused on admin operations, tooling, and staff UX.

## Active Tasks

### Gatherings Orders / Attendance Workflow

- [ ] Keep gathering orders form minimal (attendance-first) and avoid offering-template metadata sections.
- [ ] Confirm minimal gathering form behavior for both create and edit.
- [ ] Ensure gathering registration detail page also stays minimal and readable.
- [ ] Add attendance-oriented fields only if needed (avoid schema creep).

### Dependent Selection in Admin Registration

- [ ] Add a second selector after patron selection: `Registrant = Patron / Dependent`.
- [ ] Load selected patron dependents into that selector.
- [ ] Persist `metadata.registrant_scope` + `metadata.dependent_id` on admin-created registrations.
- [ ] Display registrant name (not only account owner) in admin orders/attendance tables.

### Existing Registration Resolution (Least Brittle)

- [ ] Add server-side lookup for existing registration by:
  `(registrable_type, registrable_id, user_id, metadata.registrant_scope, metadata.dependent_id)`.
- [ ] If existing record is found, route admin to edit/show instead of silently creating a duplicate.
- [ ] Reuse the same lookup logic service in both admin and account flows.

### Accounting / Reporting

- [ ] Keep gatherings clearly filterable/separable in orders and payment reporting.
- [ ] For free gatherings, surface `no payment required` state clearly in admin tables.
- [ ] For paid gatherings, keep standard payment lifecycle and ledger compatibility.

### QA Checklist

- [ ] Admin creates gathering registration for patron self.
- [ ] Admin creates gathering registration for a dependent.
- [ ] Existing-registration redirect/edit path works for both self and dependent.
- [ ] Orders list and registration detail show registrant clearly.
- [ ] Free vs paid gathering accounting states render correctly.

## Open Decisions

- [ ] Enforce one active registration per registrant per gathering, or allow multiple entries.

