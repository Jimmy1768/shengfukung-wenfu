# ACCOUNT PORTAL REFINE LEDGER

## Purpose

- Running ledger for account-portal refinements discovered during QA.
- Keep scope focused on patron-facing behavior (not admin workflows).

## Active Tasks

### Gatherings Registration Parity

- [x] Extend dependent registrant flow to gatherings (same as offerings: self vs dependent).
- [x] Persist `metadata.registrant_scope` + `metadata.dependent_id` for gathering registrations.
- [x] Reuse duplicate-check behavior by registrant scope for gatherings (align with final product rule).
- [x] If duplicate exists, route to edit/show instead of creating a second active registration.

### Gatherings UX / Data Shape

- [x] Keep gathering registration form minimal (attendance-first, no offering-specific ritual/logistics sections).
- [x] Ensure per-registrant registration still creates one `TempleRegistration` row for attendance reporting.
- [x] Show actual registrant (self/dependent) clearly in account registration cards/history.

### Payments / Status Semantics

- [x] For free gatherings, show a non-confusing payment state (`no payment required`) rather than misleading unpaid/pending language.
- [x] For paid gatherings, keep normal payment flow and include in payments/history views.

### QA Checklist

- [x] Test account gathering registration for self.
- [x] Test account gathering registration for dependent.
- [x] Test duplicate guard behavior for both self and dependent.
- [x] Test free vs paid gathering status display in account pages.

### Profile Sync Guardrails

- [x] Keep registration creation non-blocking when profile fields are incomplete.
- [x] When registrant is `self`, sync non-blank registration contact values back to user profile metadata (`phone`, `notes`).
- [x] When registrant is `dependent`, sync non-blank registration contact values back to that dependent profile metadata (`phone`, `email`, `notes`) without overwriting main user profile contact metadata.
- [x] Never overwrite profile fields with blank values from registration input.

## Open Decisions

- [x] One active registration per registrant per gathering (duplicates route to existing registration edit flow).

## Deferred

- [ ] Online payment integration (LINE Pay callbacks + live payment reconciliation) is deferred due to current environment limits.
- [x] Add persistent header/nav `Email Us` CTA that opens the account contact-temple modal (paired with public Vue contact modal flow).
