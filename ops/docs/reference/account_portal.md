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
- Personal info fields prefill from the `users` table. Since 2026-08-28 a registration's contact answers write back to a **separate namespace** (`user.metadata["registration_contact"]`), never to the patron's own profile keys — a temple is authoritative over "what number did we reach them at for this registration", not over "what is this person's phone number". `Registrations::ReusableContact` restores prefill by precedence (most recent registration value, then the profile), so nobody is asked twice. Only `Account::ProfileForm` writes the profile itself. Offering-specific contact/logistics fields (ancestor names, dedications, etc.) can now be saved as **reusable defaults** and reused across registrations by both patrons and admins — see "Reusable Registration Defaults" below; they are no longer read-only outside the registration form.
- Registrations lock once fulfilled or past the start time. Cancel/refund actions surface only while the offering is open; otherwise we show guidance to contact the temple.
- **Online payment is gated behind admin review** for every registrable type, gatherings included since 2026-08-28 (a gathering is a sub-type, not a separate flow — it simply carries no offering data to fill in, so the admin action there is review-and-publish): a fresh self-registration shows an "awaiting temple review" state on the payment page instead of a checkout button, and `start_checkout` itself redirects back with the same message if attempted directly. The gate clears the moment an admin marks the registration ready from the admin console — see `ops/docs/reference/admin_portal.md`. Patrons can still be told to pay cash in person before that happens; only the *online* checkout path is gated.
- **Patron-facing copy is deliberately vague wherever the patron cannot act.** Awaiting admin review, blocked on the temple's billing, and paid-cash-not-yet-recorded all render one identical message (「已收到您的報名，廟方正在處理中。」). The patron is not owed a status report on the temple's internal state, the earlier wording leaked it ("付款開放後", "廟方正在確認"), and one of those states could make a specific claim that was flatly wrong. States where the patron *can* act keep specific copy and a CTA. The asymmetry with the admin side is intentional.
- Duplicate guardrails allow exactly one active registration per registrant scope (self or dependent), offering slug, and period key.

## Reusable Registration Defaults

- `Registrations::ReusableDefaults` (`rails/app/services/registrations/reusable_defaults.rb`) lets patrons and admins save offering-specific contact/logistics field values once and reuse them across future registrations for the same offering, instead of retyping them each time.
- **Each field declares a `reuse:` policy in the offering's own yml**, per (offering, field): `prefill` (a durable fact — ancestors recur), `offer_as_options` (remember, but choose afresh — a blessing message), or `never` (a purchase decision, e.g. incense items). Per-(offering, field) rather than per field name because the same canonical field legitimately differs across offerings: `dedication_message` is a temple-authored incense-item picker on 香油錢 and freeform blessing text on the other three Shengfukung offerings, under one shared 祈福語 label.
- The runtime default when a yml is silent is the **constant** `offer_as_options` — never shape-derived, because deriving it from `allow_multiple` would move policy as a side effect of editing a different field and would leave nobody able to read a yml and know the behavior. Only a wrong `prefill` can cause harm (a stale answer carried into a registration the temple physically acts on); `offer_as_options` prevents that while still remembering. The shape heuristic lives in the `offerings:annotate_reuse` generator, which proposes a policy per field once at authoring time for a human to override.
- A cached multi-value field is **never** handed to a single-value control as its value. That was the original defect: an accumulated list rendered as this year's answer. `prefill` is scalarized to the most recent entry; `offer_as_options` surfaces past values as a datalist or as appended select options without preselecting them.
- Keyed by exact `(temple.id, registrable_type, registrable.id)` — never by slug alone, because a bare slug is not tenant-safe (two temples can reuse the same offering slug).
- A fixed set of fields can never enter reusable storage even if the offering's form schema would otherwise render them: quantity, price, currency, certificate number, offering/service slugs, registrant scope, dependent ID, and any payment/lifecycle data.
- The legacy unscoped `metadata["offerings"][slug]` storage path is preserved byte-for-byte for old records but is dead code going forward — nothing reads or writes it anymore.
- Registrations that already have payment, refund, cancellation, or fulfillment recorded never write back to reusable defaults.
- Admins can view/add/edit/clear a patron's reusable defaults directly from the offering-orders screen (`rails/app/controllers/admin/patron_metadata_values_controller.rb`), not just via raw API calls.

## Member Surfaces

- **Dashboard** shows the next registration, certificate list placeholder, and quick links to profile/payments. Registrant names display on cards to clarify whether the order is for self or a dependent.
- **Registrations** lists active orders with status pills, payment state, and cancel/help actions. **History** covers fulfilled orders with the same data helpers.
- Expiring unpaid holds now trigger reminder notifications before cancellation, then an expiration notification after cancellation (deduped per registration lifecycle event).
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

- Expo clients use a dedicated native API under `/api/v1/account/native/*` (43 routes). It deliberately does *not* reuse the browser account JSON: `Api::V1::Account::NativeBaseController` skips `Account::BaseController` precisely to avoid inheriting cookie-session and admin-aware scope helpers. Contracts are kept aligned by sharing the same forms, services, and policies underneath — not by sharing the controller surface. See `ops/docs/reference/templemate_native_account_api.md`.
- TempleMate mobile ships full dependent CRUD and full registration create/edit natively, with Rails remaining sole authority for offering identity and price/fee resolution (patrons pick from a Discover catalog of admin-defined offerings rather than typing one in; registrant is restricted to self or an owned dependent). This is no longer a "light interactions only" surface for those two flows.
- Certificates are readable natively (`GET /api/v1/account/native/certificates`). Payments remain web-portal-only: there is no native checkout start or browser-return endpoint, and the Expo adapter has no payment method.

## Next Steps / TODOs

- Connect OAuth provider configuration for production auth flows.
- Wire LINE Pay receipts once the payment pipeline lands; keep the placeholders in place to avoid UI churn.
