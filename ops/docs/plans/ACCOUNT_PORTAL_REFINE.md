# ACCOUNT PORTAL REFINE LEDGER

## Purpose

- Running ledger for account-portal refinements discovered during QA.
- Keep scope focused on patron-facing behavior (not admin workflows).

## Active Tasks

### Gatherings Registration Parity

- [ ] Extend dependent registrant flow to gatherings (same as offerings: self vs dependent).
- [ ] Persist `metadata.registrant_scope` + `metadata.dependent_id` for gathering registrations.
- [ ] Reuse duplicate-check behavior by registrant scope for gatherings (align with final product rule).
- [ ] If duplicate exists, route to edit/show instead of creating a second active registration.

### Gatherings UX / Data Shape

- [ ] Keep gathering registration form minimal (attendance-first, no offering-specific ritual/logistics sections).
- [ ] Ensure per-registrant registration still creates one `TempleRegistration` row for attendance reporting.
- [ ] Show actual registrant (self/dependent) clearly in account registration cards/history.

### Payments / Status Semantics

- [ ] For free gatherings, show a non-confusing payment state (`no payment required`) rather than misleading unpaid/pending language.
- [ ] For paid gatherings, keep normal payment flow and include in payments/history views.

### QA Checklist

- [ ] Test account gathering registration for self.
- [ ] Test account gathering registration for dependent.
- [ ] Test duplicate guard behavior for both self and dependent.
- [ ] Test free vs paid gathering status display in account pages.

## Open Decisions

- [ ] One active registration per registrant per gathering vs allow multiple registrations for the same registrant.

