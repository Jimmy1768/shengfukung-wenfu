# Temple Onboarding Runbook

This file documents how we bring a new temple onto the Shenfukung Wenfu stack. It supersedes the generic Golden Template `DEPLOYMENT_NOTES.md`—keep this repo-specific checklist up to date as the workflow evolves.

## Vocabulary

- **Profile YAML** – `rails/db/temples/<slug>.yml`. Source of truth for public copy (name, tagline, contact, service times, about text, metadata). Required before seeding anything.
- **Owner admin** – first administrator for the temple. Gets elevated privileges (manage admins, manage other admins, payment routing). Stored as a `User` + `AdminAccount(role: owner)` + `AdminTempleMembership`.
- **Events vs Services** – events (`TempleEvent`) are in-person programs with schedules/capacity; services (`TempleService`) cover proxy rituals (lanterns, placards, etc.). Both are configured from the per-temple YAML templates and seeded through `Seeds::TempleFinancials`. Each template must declare a `kind` (`event`/`service`) so the admin UI knows which controller/model to use.
- **TempleRegistration** – unified polymorphic registration model (table: `temple_registrations`). Every onsite order/payment flows through this table regardless of whether the source is an event, service, or gathering.
- **Gatherings** – `TempleGathering` records for non-offering community events (e.g., workshops). They share the registration/payment stack but are managed separately from offerings.

## Dev / Staging Flow

Use this when you need representative data locally or on staging:

> 🔐 **Per-temple env overrides**
>
> - Keep third-party credentials in `etc/default/<temple-slug>.env`. This folder is tracked via `.keep`, but the files themselves should not be committed.
> - Load a specific temple’s secrets by prefixing any command with `bin/load_temple_env <slug> -- <command>`. Example: `bin/load_temple_env shenfukung-wenfu -- (cd rails && bundle exec rails server -p 3001)`.
> - The loader sources `.env`, `.env.<env>`, then `etc/default/<slug>.env` (falling back to `.env.development`), so Vue/Expo builds and Rails share the exact same credential set for the active temple.

1. **Author profile YAML**
   - Copy `rails/db/temples/shenfukung-wenfu.yml` as a starting point.
   - Set `slug`, `name`, `contact`, `service_times`, and optional hero/about/meta copy.
   - Commit the file.
2. **Seed the temple**
   - Run `bin/rails temples:seed[slug]`.
   - The task creates/updates the `Temple`, `TemplePage`, and `TempleSection` records.
3. **Seed baseline accounts**
   - `bin/rails db:seed` now provisions:
     - Owner admin: `owner@<slug>.local`
     - Staff admin (promoted patron): `admin@<slug>.local`
     - Patron tester: `patron@<slug>.local`
     - Dev support admin: `dev@<slug>.local`
     - Demo client + guest operator for account portal flows
   - All default to `DemoPassword!23` (override via `PROJECT_*_EMAIL`/`PROJECT_PRIMARY_USER_PASSWORD` env vars).
4. **Smoke test**
   - Sign in at `/admin`.
   - Use the email/password you passed to `admin_controls:seed_owner` (these accounts are stored in the `users` table; the marketing demo credentials no longer apply here).
   - Verify the temple profile shows the placeholder QR and owner-only panels.
   - Ensure audit logs are written when editing basic fields.
5. **Seed financial events + services**
   - `Seeds::TempleFinancials` now hydrates `temple_events`, `temple_services`, `temple_gatherings`, and corresponding `temple_registrations` + payments. After editing the YAML or gathering seeds, run:
     ```bash
     bin/rails "temple_financial:seed_offerings[shenfukung-wenfu]"
     ```
   - Grant staff financial permissions (owner already has them):
     ```bash
     bin/rails "temple_financial:grant_permissions[shenfukung-wenfu,admin@shenfukung-wenfu.local]"
     ```
   - Cash-only pipeline: use `/admin/events/...`, `/admin/services/...`, or `/admin/gatherings/...` → Orders to capture registrations, then “Record cash payment” to log receipts + ledger entries. LINE Pay arrives after onsite validation.
6. **Customize product templates per temple**
   - Each offering entry stores its form definition in metadata. Use the `form_fields` key to describe which inputs should render for that offering (e.g., `sections`, `fields`, `required`, custom labels/hints).
   - During onboarding, create a config file under `rails/db/temples/offerings/<slug>.yml`. Every entry must include `kind:` (`event` or `service`) so the loader can route to the correct model. Suggested structure:
     ```yaml
     offerings:
       - slug: pudu-table
         kind: service
         form_fields:
           basics: [title, slug, offering_type, period, price_cents, currency]
           schedule: [starts_on, ends_on, available_slots]
           certificate: [certificate_prefix, certificate_hint]
           logistics: [ancestor_placard_hint, logistics_notes]
           description: true
     ```
   - Extend the seed task (or run a one-off script) to load this YAML and merge `form_fields` + `kind` into each offering’s `metadata`. The admin `_form.html.erb` partial reads `@offering.metadata['form_fields']` and only renders the listed sections/inputs, so each temple sees a tailored form without separate partials.
   - Store the YAML in Git so the config remains the source of truth. When a temple needs tweaks, edit the YAML, rerun the sync task, and the form will update automatically.
   - `registration_form.field_settings` unlocks richer controls:
     - `options` (array or `{ value: label }`) renders a `<select>` so staff pick from approved values instead of typing.
     - `allow_multiple: true` shows the “Save as additional option” toggle, letting admins append new defaults instead of overwriting prior ones.
     - Example:
       ```yaml
       registration_form:
         sections:
           contact:
             fields: [primary_contact, phone, email]
         field_settings:
           preferred_slot:
             options: ["Morning", "Afternoon", "Evening"]
           dedication_message:
             allow_multiple: true
       ```
7. **Rolling patron defaults (registration auto-fill)**
   - Patron selection now hydrates the form with values from `user.metadata` and `user.metadata.offerings[slug]` (see `Registrations::UserMetadataUpdater`).
   - When a registration saves, contact + non-transient logistics/ritual fields merge back into the user metadata so future registrations start pre-filled.
   - Fields flagged with `allow_multiple` append into arrays whenever the admin checks “Save as additional option”.
   - Date/time-ish logistics keys are treated as transient and skipped.
   - JSON endpoints (`/admin/patrons/:id/metadata_values`) exist for future UI that lists/removes multi-value entries; wire a modal when needed.
8. **In-tower workflow summary**
   - **Product templates** – defined in `rails/db/temples/offerings/<slug>.yml` under `events:` and `services:`. Devs sync them into each temple’s metadata via `Offerings::TemplateLoader`.
   - **Event/Service instances** – admins use `/admin/events` or `/admin/services` to create/edit/delete instances (set price, dates, copy). No code change required.
   - **Gatherings** – `/admin/gatherings` lets staff publish ad-hoc meetups (calligraphy class, volunteer briefing, etc.) without wiring a template. They still funnel into `TempleRegistration` + `/admin/offerings` order management, so reporting and payments stay unified.
   - **Media uploads** – Gatherings (hero image) and gallery entries (photos/video) can now upload files directly via the shared MediaAsset/S3 pipeline; the forms still accept manually pasted URLs as a fallback.
- **Registration / payment** – staff use `/admin/events/:id/orders`, `/admin/services/:id/orders`, or `/admin/gatherings/:id/orders` to capture registrations, then record payments. Ledger/history sits at this level.
- **Slugs** – admins no longer edit slugs manually; events/services/gatherings auto-generate and normalize slugs per temple, keeping URLs stable without exposing the field in forms.

## Production Flow

Production onboarding avoids creating real user passwords in seeds—only the temple record is automated.

1. **Author profile YAML** – same as dev (make sure secrets stay out of Git).
2. **Seed the temple** – `bin/rails temples:seed[slug]` on the droplet. Confirm the record exists via `rails console`.
3. **Owner self-signup**
   - Have the temple contact sign in via OAuth/password on `/account` to create their `User` row.
4. **Promote owner**
   - Run `bin/rails "admin_controls:promote_owner[slug,email]"` or use `rails console`:
     ```ruby
     temple = Temple.find_by!(slug: "slug")
     user = User.find_by!(email: "owner@example.com")
     admin = AdminAccount.find_or_create_by!(user: user) { |a| a.role = :owner }
     AdminTempleMembership.find_or_create_by!(temple: temple, admin_account: admin) { |m| m.role = :owner }
     ```
   - Email the owner once `/admin` access is ready.
   - Remind them to sign in with that email/password; the marketing demo credentials are only for `/marketing/admin`.
5. **Owner invites staff**
   - Inside the admin console (feature pending), the owner can invite additional admins scoped to their temple.
6. **Financial onboarding**
   - Gather LINE Pay channel ID/secret but keep them out of Git; store temporarily in `etc/default/<slug>.env` until vaulting is ready.
   - Decide which staff get financial permissions and run `bin/rails "temple_financial:grant_permissions[slug,email]"`.
   - Cash entries live under `/admin/offerings/...` while we finish LINE Pay.
7. **Mobile/API consumers**
   - Expo/mobile clients now call `/account/api/registrations`, `/account/api/payment_statuses/:reference`, `/account/api/certificates`, and `/account/api/guest_lists/:offering_id`.
   - Owner/staff roles determine what data comes back (guest lists additionally require `view_guest_lists`). When debugging, wrap Expo commands with `bin/load_temple_env <slug> -- ...` so the API and client agree on credentials.

## Owner Privileges

| Capability                 | Owner | Staff |
|---------------------------|:-----:|:-----:|
| Edit temple profile       |   ✓   |   ✓   |
| Upload/payment QR         |   ✓   |   ✗   |
| Manage temple admins      |   ✓   |   ✗   |
| Create events/content     |   ✓   |   ✓   |
| Messaging/respond emails  |   ✓   |   ✓   |

Keep this matrix in sync with UI checks (`current_admin.admin_account.owner?` / membership role) as features roll out.

## Checklist Summary

- [ ] YAML authored + committed.
- [ ] `bin/rails temples:seed[slug]` run (dev + prod).
- [ ] Payment onboarding planned (LINE Pay credentials collected, offerings TBD).
- [ ] Owner admin provisioned (dev task or manual promote).
- [ ] Admin UI tested (profile edit, audit log, QR display).
- [ ] Deployment notes updated only for template-level changes; keep temple-specific updates here.
