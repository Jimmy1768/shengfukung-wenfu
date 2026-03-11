# Temple Onboarding Runbook

This file documents how we bring a new temple onto the Shengfukung Wenfu stack. It supersedes the generic Golden Template `DEPLOYMENT_NOTES.md`—keep this repo-specific checklist up to date as the workflow evolves.

## Vocabulary

- **Profile YAML** – `rails/db/temples/<slug>.yml`. Source of truth for public copy (name, tagline, contact, service times, about text, metadata). Required before seeding anything.
- **Owner admin** – first administrator for the temple. Gets elevated privileges (manage admins, manage other admins, payment routing). Stored as a `User` + `AdminAccount(role: owner)` + `AdminTempleMembership`.
- **Staff admin** – temple-scoped operator for daily work. Staff should not manage other admins or permissions. Stored as the same core records as owner admin, but with a lower temple role/permission set.
- **Temple membership** – admin access is granted per temple through `AdminTempleMembership`. One user/admin identity can hold memberships for many temples.
- **Events vs Services** – events (`TempleEvent`) are in-person programs with schedules/capacity; services (`TempleService`) cover proxy rituals (lanterns, placards, etc.). Both are configured from the per-temple YAML templates and seeded through `Seeds::TempleFinancials`. Onboarding configs must use top-level `events:` and `services:` sections so entries are classified by section (not by per-entry `kind` flags).
- **TempleRegistration** – unified polymorphic registration model (table: `temple_registrations`). Every onsite order/payment flows through this table regardless of whether the source is an event, service, or gathering.
- **Gatherings** – `TempleGathering` records for non-offering community events (e.g., workshops). They share the registration/payment stack but are managed separately from offerings.

## Admin access model

- Use a temple-scoped split:
  - `staff` handles daily operations
  - `owner` can manage admins and permissions for that temple
- Do not introduce a global super-admin role for client temples by default.
- Operational platform access should use:
  - one internal admin identity
  - plus one `AdminTempleMembership` per temple
- This is intentionally more explicit than a global admin switch:
  - lower blast radius if an account is compromised
  - clearer audit trail for who had access to which temple
  - simpler per-temple offboarding
- During initial spin-up, it is acceptable for the platform operator (`jimmy1768`) to hold an `owner` membership on the temple until the real temple owner is promoted.

## Dev / Staging Flow

Use this when you need representative data locally or on staging:

> 🔐 **Per-temple env overrides**
>
> - Use `ops/env/template.temple.env` as your non-secret checklist template.
> - Keep third-party credentials out of git: local goes in `.env.development`; production goes in `/etc/default/<slug>-env`.
> - Load a specific temple’s secrets by prefixing any command with `bin/load_temple_env <slug> -- <command>`. Example: `bin/load_temple_env shengfukung-wenfu -- (cd rails && bundle exec rails server -p 3001)`.
> - The loader sources `.env`, `.env.<env>`, then `/etc/default/<slug>-env` when readable (falling back to `.env.development`), so Vue/Expo builds and Rails share the same credential set for the active temple.

### Generate + Deploy Env Files

Use this workflow whenever you onboard a new temple slug.

1. Copy values from `ops/env/template.temple.env` into the target env file and fill real values (API keys, origins, payment provider credentials):
   - local: `.env.development`
   - production: `/etc/default/<slug>-env`
2. Validate the app can boot with that env:
   ```bash
   bin/load_temple_env <slug> -- (cd rails && bundle exec rails runner "puts ENV.fetch('PROJECT_SLUG')")
   ```
3. Restart services that read the env file (for example Puma/Sidekiq) after updating production env values.

Slug convention:

- `PROJECT_SLUG` is the app/deploy slug. Follow the temple-client naming convention here (for example `shengfukung-wenfu`). Use it for repo naming, env filenames, systemd service names, and deploy scripts.
- `AUTH_TENANT_SLUG` is the central auth tenant identifier. Keep it client-level and stable (for example `shengfukung`) unless central auth explicitly needs a more granular split.
- Do not assume `PROJECT_SLUG == AUTH_TENANT_SLUG`. They may match for simple cases, but they serve different scopes and should be configured deliberately.

### Template + Theme selection

- Ensure env values are set in your active file (`.env.development` locally or `/etc/default/<slug>-env` on server) before any build:
  ```
  VITE_TEMPLE_SLUG=<slug>
  VITE_TEMPLE_LAYOUT=classic
  VITE_TEMPLE_THEME=temple-1
  ```
  Layout defaults to `classic` until new templates are shipped; themes map to palette IDs defined in `shared/design-system/themes.json`.
- Run Vue/Rails/Expo commands through `bin/load_temple_env <slug> -- …` so the same env file powers every surface. Example: `bin/load_temple_env shengfukung-wenfu -- (cd vue && npm run build)`.
- When onboarding a new temple, confirm the slug + theme combo works locally:
  1. `bin/load_temple_env <slug> -- (cd vue && npm install && npm run dev)`
  2. Visit `http://localhost:5173` and verify copy/assets match the expected temple.
  3. Repeat with another palette (`VITE_TEMPLE_THEME=temple-2`) to capture approval screenshots. Layout should remain identical; only tokens change.
- Document the chosen layout/theme in the temple’s YAML or ops checklist so future deploys keep the same combo.

1. **Author profile YAML**
   - Copy `rails/db/temples/shengfukung-wenfu.yml` as a starting point.
   - Set `slug`, `name`, `contact`, `service_times`, and optional hero/about/meta copy.
   - Commit the file.
2. **Bootstrap the temple row**
   - Run `bin/rails temples:bootstrap[slug]`.
   - This creates or updates the minimal `Temple` row used for real onboarding:
     - `slug`
     - `name`
     - `metadata.registration_periods`
   - Existing admin-edited profile fields are preserved on rerun.
   - Use `bin/rails temples:seed[slug]` only when you explicitly want the broader placeholder profile/pages/news/gallery seed data.
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
   - `Seeds::TempleFinancials` now hydrates `temple_events`, `temple_services`, `temple_gatherings`, and corresponding `temple_registrations` + payments. Services also expect a `registration_period_key` (e.g., `"2026-ghost-month"`) so duplicate guardrails and reports know which cycle the registration belongs to. Define these keys per temple by adding `registration_periods` to the temple YAML (see `rails/db/temples/shengfukung-wenfu.yml` for examples). After editing the YAML or gathering seeds, run:
     ```bash
     bin/rails "temple_financial:seed_offerings[shengfukung-wenfu]"
     ```
   - Grant staff financial permissions (owner already has them):
     ```bash
     bin/rails "temple_financial:grant_permissions[shengfukung-wenfu,admin@shengfukung-wenfu.local]"
     ```
   - Cash-only pipeline: use `/admin/events/...`, `/admin/services/...`, or `/admin/gatherings/...` → Orders to capture registrations, then “Record cash payment” to log receipts + ledger entries. LINE Pay arrives after onsite validation.
6. **Customize product templates per temple**
   - Each offering entry stores its form definition in metadata. Use `form_fields` + `registration_form` to describe which inputs render and how registration payloads are structured.
   - Keep `rails/db/temples/offerings/working-draft.yml` as the reusable onboarding scratch file. Paste each new temple's raw offerings config there first, then convert it into the finalized per-temple file at `rails/db/temples/offerings/<slug>.yml`.
   - Do not delete `working-draft.yml`. Overwrite it during each new temple onboarding cycle as the current staging draft.
   - During onboarding, create `rails/db/temples/offerings/<slug>.yml` with a strict split shape:
     ```yaml
     schema_version: 2
     events:
       - slug: ancestor-ritual
         label: "祖先拔薦"
         defaults:
           offering_type: "ritual"
           currency: "TWD"
         attributes:
           price_cents: 1500
           currency: "TWD"
           description: "為祖先超薦的法事，含誦經、牌位供奉與證書備註。"
         form_fields:
           ritual:
             title: "作業備註"
             fields: [fulfillment_method, certificate_hint, logistics_notes]
         registration_form:
           sections:
             order:
               fields: [quantity, unit_price_cents, currency, certificate_number]
             contact:
               fields: [primary_contact, phone, email, dependents_notes, notes]
             logistics:
               fields: [preferred_date, preferred_slot, arrival_window, ceremony_location]
             ritual_metadata:
               fields: [ancestor_placard_name, dedication_message, incense_option, certificate_notes]

     services:
       - slug: pudu-table
         label: "普渡供桌"
         registration_period_key: "2026-ghost-month"
         defaults:
           offering_type: "table"
           currency: "TWD"
         attributes:
           price_cents: 3000
           currency: "TWD"
           description: "含供桌佈置與供品，提供春祭/中元普渡專用桌位。"
         form_fields:
           schedule:
             title: "供桌內容"
             fields: [table_items, table_size]
           logistics:
             title: "作業方式"
             fields: [fulfillment_method]
         registration_form:
           sections:
             order:
               fields: [quantity, unit_price_cents, currency]
             contact:
               fields: [primary_contact, phone, email]
             logistics:
               fields: [preferred_date, ceremony_location]
             ritual_metadata:
               fields: [ancestor_placard_name, dedication_message]
     ```
   - Section constraints (must follow during DOCX -> YAML conversion):
     - `events:` entries must not include `registration_period_key`.
     - `services:` entries must include `registration_period_key`.
     - `events:` must carry schedule/location fields in built-in columns and/or registration form mappings.
     - `services:` should model proxy/fulfillment flows and should not require gathering-style time/location attendance data.
     - Do not include per-entry `kind` when the entry already lives under `events` or `services`.
   - Keep this file YAML-first and deterministic: no ad-hoc keys and no free-form section names. If a temple needs a new structure, update this contract first, then regenerate.
   - Each `form_fields` section may include an optional `title:` (as shown above). When present, that string becomes the card heading in the admin form; otherwise the UI falls back to the generic "Offering details" label. This keeps the YAML non-technical while still letting a temple insist on a specific term when needed.
   - Use the optional `attributes` block to pre-fill core event/service columns (e.g., `price_cents`, `currency`, `description`). These values only apply when the field is blank, so admins can still override them before saving.
   - Loader behavior: `Offerings::TemplateLoader` reads `events:` + `services:` and syncs `form_fields`, `defaults`, `options`, `registration_form`, and labels into offering metadata. The admin `_form.html.erb` partial reads `@offering.metadata['form_fields']`, so each temple sees a tailored form without separate partials.
   - Store the YAML in Git so the config remains the source of truth. When a temple needs tweaks, edit the YAML, rerun the sync task, and the form will update automatically.
   - After editing `rails/db/temples/offerings/<slug>.yml`, run `ruby ops/scripts/sync_offering_configs.rb` to push the latest metadata (`form_fields`, defaults, registration schema, attributes) into each offering’s `metadata` column. Without this sync, the admin UI will keep rendering the stale metadata from the DB.
   - Validation checklist before committing onboarding YAML:
     - Every slug is unique within a temple.
     - Every service `registration_period_key` exists in `rails/db/temples/<slug>.yml` `registration_periods`.
     - No event entry defines `registration_period_key`.
     - Form keys referenced in YAML map to supported admin/registration fields.
   - Keep `form_fields` focused on metadata that doesn’t already have a dedicated column on the base form (e.g., certificate hints, lamp locations). Core fields like `description`, `price_cents`, `starts_on`, etc. already appear in the built-in cards, so duplicating them in metadata results in redundant UI.
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
   - **Product templates** – defined in `rails/db/temples/offerings/<slug>.yml` under `events:` and `services:`. Devs sync them into each temple’s metadata via `Offerings::TemplateLoader`. Active temple slugs + deploy metadata now live in `rails/app/lib/temples/manifest.yml`, which deploy scripts and runbooks reference when iterating over multiple clients.
   - **Unified offerings index** – `/admin/offerings` is now the primary list for events *and* services. Each row renders a card with title/subtitle, type, price, status, and last update plus inline “View” / “Orders” buttons. Draft + published offerings show by default; the archived toggle flips `status` to `archived` for historical reference without deleting data.
   - **Event/Service instances** – editing still occurs under `/admin/events/:id` or `/admin/services/:id`, but creation always starts from `/admin/offerings` so the template picker can auto-select the correct form partial based on whether the template came from `events:` or `services:`.
   - **Gatherings** – `/admin/gatherings` now mirrors the same card layout (schedule, location, price, status) so staff have a consistent experience whether they manage templated offerings or one-off community meetups. They still funnel into `TempleRegistration` + `/admin/offerings` order management, keeping reporting and payments unified.
   - **Media uploads** – Gatherings (hero image) and gallery entries (photos/video) can now upload files directly via the shared MediaAsset/S3 pipeline; the forms still accept manually pasted URLs as a fallback.
- **Registration / payment** – staff use `/admin/events/:id/orders`, `/admin/services/:id/orders`, or `/admin/gatherings/:id/orders` to capture registrations, then record payments. Ledger/history sits at this level. The Orders list now labels each entry’s “Source” with `Event`, `Service`, or `Gathering`, and free gatherings automatically show the “No payment required” badge next to the status pill.
- **Slugs** – admins no longer edit slugs manually; events/services/gatherings auto-generate and normalize slugs per temple, keeping URLs stable without exposing the field in forms.

## Production Flow

Production onboarding avoids creating real user passwords in seeds—only the temple record is automated.

1. **Author profile YAML** – same as dev (make sure secrets stay out of Git).
2. **Bootstrap the temple** – `bin/rails temples:bootstrap[slug]` on the droplet. Confirm the record exists via `rails console`.
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
   - Gather LINE Pay channel ID/secret but keep them out of Git; store in `.env.development` locally and `/etc/default/<slug>-env` on server until vaulting is ready.
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
- [ ] `bin/rails temples:bootstrap[slug]` run (dev + prod).
- [ ] Payment onboarding planned (LINE Pay credentials collected, offerings TBD).
- [ ] Owner admin provisioned (dev task or manual promote).
- [ ] Admin UI tested (profile edit, audit log, QR display).
- [ ] Deployment notes updated only for template-level changes; keep temple-specific updates here.
