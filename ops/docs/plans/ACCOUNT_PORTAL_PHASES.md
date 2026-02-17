# ACCOUNT PORTAL FOLLOW-UP NOTES

Current work:

1. [x] The top nav (`rails/app/views/layouts/account.html.erb`) now includes “Registrations,” giving a persistent link to `/account/registrations`.

2. [x] The events page (`rails/app/views/account/events/index.html.erb`) renders per-card “Register” CTAs wired to the correct offering intent for both offerings and gatherings.

3. [x] CSS/styling refinements (gallery thumbnails/lightbox tuning, registration form widths, button sizing) keep the new pages visually consistent.

## Phase 5 — Dependent + Rolling Offering Rules (pending temple input)

1. **Define offering seasons**  
   - Add a `registration_period_key` (or similar) to services/offerings so the portal knows which cycle is open (e.g., “2026-ghost-month”).  
   - Expose this in admin tooling so staff can roll the season forward as needed.

2. **Caregiver / dependent selector**  
   - During registration, prompt the patron to choose “Registrant: self or dependent” before the form.  
   - Prefill contact info from the selected profile and store `metadata["dependent_id"]` when applicable.  
   - Limit each submission to one registrant (caregiver repeats the flow for multiple dependents).

3. **Duplicate guardrails**  
   - Replace the current “one per slug per user” rule with “one per registrant (user or dependent) per `registration_period_key`”.  
   - Ensure historical registrations remain intact when dependents are edited/deleted (store snapshots as needed).
