# ROLLING OFFERINGS & DEPENDENT REGISTRATION PLAN

## Background

- Existing portal allows a single registration per patron/offering slug. This breaks for recurring temple services (lanterns, tables, donations) and prevents caregivers from booking on behalf of dependents who lack accounts.
- We added `registration_period_key` to `temple_services` so each cycle (e.g., `2026-ghost-month`) can be tracked, but we still need UX + guardrails around it plus dependent tooling.

## Phase A — Period Keys & Admin Controls

- [x] Extend each temple YAML (`rails/db/temples/<slug>.yml`) with a `registration_periods` array of `{ key, label_zh, label_en }`.
- [x] `TempleFinancials` seed loader writes the key for demo data/services.
- [x] `/admin/services/:id` form shows a select populated from the YAML list (plus optional “Other” text field).
- [x] Persist `registration_period_key` and expose it on service cards/orders list.
- [x] Registrations copy the service’s key into `metadata["period_key"]`.
- [x] Duplicate detection enforces one registration per `(registrant_scope, service.slug, period_key)`.
- [x] Admin filters/exports accept `period_key`.

## Phase B — Caregiver / Dependent Flow

- [ ] Add a “Who is this for?” selector (self vs. dependent) in the account registration flow.
- [ ] Store `dependent_id` in registration metadata and prefill contact info when a dependent is chosen.
- [ ] Allow one active registration per `(dependent/user, slug, period_key)`; caregivers repeat the flow for multiple dependents.
- [ ] Update orders list + filters to display/search by dependent.

## Phase C — Rolling Offering UX polish

- [ ] Show the selected period label on services index/payment screens (so patrons know the season).
- [ ] Add helper copy about renewals / IRL support.
- [ ] Consider a rake task or script that bumps all services to the next `registration_period_key`.

## Open Questions

- Should “Other” period keys entered via admin automatically append to the YAML (or just live in DB)?
- Do temples require automatic reminders when a period is ending?
- Should we allow bulk period updates (e.g., update all services to `2027-ghost-month`)?
