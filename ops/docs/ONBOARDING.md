# Temple Onboarding Runbook

This file documents how we bring a new temple onto the Shenfukung Wenfu stack. It supersedes the generic Golden Template `DEPLOYMENT_NOTES.md`—keep this repo-specific checklist up to date as the workflow evolves.

## Vocabulary

- **Profile YAML** – `rails/db/temples/<slug>.yml`. Source of truth for public copy (name, tagline, contact, service times, about text, metadata). Required before seeding anything.
- **Owner admin** – first administrator for the temple. Gets elevated privileges (manage admins, upload payment QR). Stored as a `User` + `AdminAccount` + `AdminTempleMembership(role: owner)`.
- **Placeholder QR** – temporary `media_assets` row pointing at a static file so the admin UI/API can render a LINE Pay QR until uploads are wired.

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
3. **Seed the owner admin (dev helper)**
   - Run the Rake task with shell quoting so zsh doesn’t glob the brackets:
     ```bash
     bin/rails "admin_controls:seed_owner[shenfukung-wenfu,admin@shenfukung-wenfu.local]"
     ```
   - The task creates a `User` with deterministic credentials, an `AdminAccount (role: owner)`, and an `AdminTempleMembership` linking the admin to the temple.
   - Credentials default to `admin@<slug>.local` / `GoldenTemplate!123` unless you pass overrides.
4. **Smoke test**
   - Sign in at `/admin`.
   - Use the email/password you passed to `admin_controls:seed_owner` (these accounts are stored in the `users` table; the marketing demo credentials no longer apply here).
   - Verify the temple profile shows the placeholder QR and owner-only panels.
   - Ensure audit logs are written when editing basic fields.
5. **Seed financial offerings + permissions (new subsystem)**
   - Preload the five legacy offerings (incense donation, family peace, lantern, ancestor ritual, pudu tables):
     ```bash
     bin/rails "temple_financial:seed_offerings[shenfukung-wenfu]"
     ```
   - Grant the owner or staffer financial permissions (repeat per admin):
     ```bash
     bin/rails "temple_financial:grant_permissions[shenfukung-wenfu,admin@shenfukung-wenfu.local]"
     ```
   - Cash-only pipeline: use `/admin/offerings/<id>/orders` to create registrations, then “Record cash payment” to log receipts + ledger entries. LINE Pay arrives after onsite validation.
   - Cash-only pipeline: use `/admin/offerings/<id>/orders` to create registrations, then “Record cash payment” to log receipts + ledger entries. LINE Pay arrives after onsite validation.
6. **Customize product lines / offerings per temple**
   - Each `TempleOffering` stores a JSONB `metadata` column. Use the `form_fields` key to describe which inputs should render for that offering (e.g., `sections`, `fields`, `required`, custom labels/hints).
   - During onboarding, create a config file under `rails/db/temples/offerings/<slug>.yml`. Suggested structure:
     ```yaml
     offerings:
       - slug: pudu-table
         form_fields:
           basics: [title, slug, offering_type, period, price_cents, currency]
           schedule: [starts_on, ends_on, available_slots, active]
           certificate: [certificate_prefix, certificate_hint]
           logistics: [ancestor_placard_hint, logistics_notes]
           description: true
     ```
   - Extend the seed task (or run a one-off script) to load this YAML and merge `form_fields` into each offering’s `metadata`. The admin `_form.html.erb` partial will read `@offering.metadata['form_fields']` and only render the listed sections/inputs, so each temple sees a tailored form without separate partials.
   - Store the YAML in Git so the config remains the source of truth. When a temple needs tweaks, edit the YAML, rerun the sync task, and the form will update automatically.
7. **In-tower workflow summary**
   - **Product line (template)** – defined in `rails/db/temples/offerings/<slug>.yml` + merged into `temple_offerings.metadata`. Requires dev support to add new slugs/sections.
   - **Offering (event instance)** – admins use `/admin/offerings/new` to create/edit/delete instances of those product lines (set price, dates, copy). No code change required.
   - **Registration / payment** – staff use `/admin/offerings/<id>/orders` to capture onsite registrations, then record payments. Ledger/history sits at this level.

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
