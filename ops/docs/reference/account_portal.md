# Account Portal Reference

Snapshot of what the patron-facing account portal already delivers so future work plugs into the right layers.

## Theme & Layout

- `/account` uses the shared design-system palettes defined in `shared/design-system/themes.json`. `PROJECT_DEFAULT_THEME_KEY` (per temple) keeps marketing + account shells visually aligned.
- Developers can preview alternate palettes locally via the cookie-driven theme toggle exposed by `Account::BaseController` and `/dev/theme` endpoints.
- `layouts/account.html.erb` plus `app/stylesheets/account/account.scss` render a dedicated hero/nav shell while importing the shared tokens.
- Cross-surface theme/palette policy and preference sync contracts are documented in `ops/docs/reference/visual_preference_systems.md`.

## Account Shell & Auth Flow

- All `/account` controllers inherit from `Account::BaseController`, which resolves the active theme, enforces authentication, and injects temple context into layouts.
- `/account/temples` lists every temple from `rails/app/lib/temples/manifest.yml`. If patrons arrive without a slug, we redirect here so they can pick the correct temple before logging in.
- `/account/login` hosts the shared OAuth + email/password modal. Deep links from the marketing site pass `temple`, `account_action`, and `offering` params; the session stores these so the flow can resume post-login.

## Registration Handoff

- Vue “Register” buttons point to `/account/login?temple=<slug>&account_action=<event|service|gathering>&offering=<slug>`.
- After authentication, `Account::RegistrationsController` checks for an existing registration on that slug. If one exists, patrons land on the detail page; otherwise they see the new-registration form.
- The intake form begins with a "Who is this for?" selector (self vs. dependent). Selecting a dependent prefills contact fields from that profile and persists `dependent_id` + `registrant_scope` into the registration metadata for duplicate guardrails.
- The selector now renders as a set of cards (Myself + each dependent). Choosing a registrant with an existing entry loads the inline edit form for that registration; otherwise the new-registration form appears prefilled for the selected person.
- Personal info fields prefill from the `users` table and write back on save. Offering-specific fields (ancestor names, dedications, etc.) remain read-only outside the registration form; admins control edits.
- Registrations lock once fulfilled or past the start time. Cancel/refund actions surface only while the offering is open; otherwise we show guidance to contact the temple.
- Duplicate guardrails allow exactly one active registration per registrant scope (self or dependent), offering slug, and period key.

## Member Surfaces

- **Dashboard** shows the next registration, certificate list placeholder, and quick links to profile/payments. Registrant names display on cards to clarify whether the order is for self or a dependent.
- **Registrations** lists active orders with status pills, payment state, and cancel/help actions. **History** covers fulfilled orders with the same data helpers.
- **Payments** mirrors the registrations list and reserves room for future LINE Pay receipts. Today it shows placeholder buttons explaining digital receipts are coming.
- **Profile & Dependents** lets patrons edit their own contact info plus manage dependent cards (name, relationship, optional birthdate/contact). Dependents never receive credentials; registrations remain tied to the caregiver account but display the registrant name in tables.
- **Contact Temple / Email Us** is a persistent account action (header utility CTA) that opens a modal and submits to the shared contact-email delivery flow. See `ops/docs/reference/inquiry_support_workflows.md`.

## Rolling Offerings Hooks (Phase A + B parity)

- The account portal trusts the service metadata populated by the admin tooling. When Vue deep-links into `/account`, the offering slug + period key determine whether new registrations are allowed or if we redirect to an existing record.
- Certificates appear on dashboard/history lists with their numbers/status but no downloads yet; copy explains that the temple issues printed certificates until digital PDFs arrive.

## Workflow & Deployment

- Standard workflow: tweak design tokens → `node bin/sync_design_system.js` → rebuild account CSS → deploy Rails/Vue/Expo via the shared scripts. `ops/docs/COMMANDS.md` documents the sequence.
- Admin console + Expo stay on the Golden Template UI; only marketing/account surfaces respond to theme switches.

## Temple Context Enforcement

- Every session carries a `temple` slug (from deep links or `/account/temples`). If `/account/login` is hit while already authenticated and intent params exist, we skip the login modal and continue the registration flow immediately.
- Future work will let multi-temple patrons switch context in-app, but today they sign in per temple.

## Mobile Alignment

- Expo clients consume the same scoped payloads (`/account/api/...`) so we avoid divergent contracts. Mobile focuses on light interactions; anything heavy (dependents, payments, certificates) remains on the web portal for now.

## Next Steps / TODOs

- Connect OAuth provider configuration for production auth flows.
- Wire LINE Pay receipts once the payment pipeline lands; keep the placeholders in place to avoid UI churn.
