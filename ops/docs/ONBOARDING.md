# Temple Onboarding Runbook

This file documents how we bring a new temple onto the Shenfukung Wenfu stack. It supersedes the generic Golden Template `DEPLOYMENT_NOTES.md`—keep this repo-specific checklist up to date as the workflow evolves.

## Vocabulary

- **Profile YAML** – `rails/db/temples/<slug>.yml`. Source of truth for public copy (name, tagline, contact, service times, about text, metadata). Required before seeding anything.
- **Owner admin** – first administrator for the temple. Gets elevated privileges (manage admins, upload payment QR). Stored as a `User` + `AdminAccount` + `AdminTempleMembership(role: owner)`.
- **Placeholder QR** – temporary `media_assets` row pointing at a static file so the admin UI/API can render a LINE Pay QR until uploads are wired.

## Dev / Staging Flow

Use this when you need representative data locally or on staging:

1. **Author profile YAML**
   - Copy `rails/db/temples/shenfukung-wenfu.yml` as a starting point.
   - Set `slug`, `name`, `contact`, `service_times`, and optional hero/about/meta copy.
   - Commit the file.
2. **Seed the temple**
   - Run `bin/rails temples:seed[slug]`.
   - The task creates/updates the `Temple`, `TemplePage`, `TempleSection`, and placeholder QR `MediaAsset`.
3. **Seed the owner admin (dev helper)**
   - Run `bin/rails admin_controls:seed_owner[slug,email]`.
   - Command creates a `User` with deterministic credentials, an `AdminAccount (role: owner)`, and an `AdminTempleMembership` linking the admin to the temple.
   - Credentials default to `admin@<slug>.local` / `GoldenTemplate!123` unless you pass overrides.
4. **Smoke test**
   - Sign in at `/admin`.
   - Verify the temple profile shows the placeholder QR and owner-only panels.
   - Ensure audit logs are written when editing basic fields.

## Production Flow

Production onboarding avoids creating real user passwords in seeds—only the temple record is automated.

1. **Author profile YAML** – same as dev (make sure secrets stay out of Git).
2. **Seed the temple** – `bin/rails temples:seed[slug]` on the droplet. Confirm the record exists via `rails console`.
3. **Owner self-signup**
   - Have the temple contact sign in via OAuth/password on `/account` to create their `User` row.
4. **Promote owner**
   - Run `bin/rails admin_controls:promote_owner[slug,email]` or use `rails console`:
     ```ruby
     temple = Temple.find_by!(slug: "slug")
     user = User.find_by!(email: "owner@example.com")
     admin = AdminAccount.find_or_create_by!(user: user) { |a| a.role = :owner }
     AdminTempleMembership.find_or_create_by!(temple: temple, admin_account: admin) { |m| m.role = :owner }
     ```
   - Email the owner once `/admin` access is ready.
5. **Owner invites staff**
   - Inside the admin console (feature pending), the owner can invite additional admins scoped to their temple.

## Placeholder QR Policy

- Seeds now drop `rails/public/system/placeholders/line-pay-qr.png` (copied from the favicon pack) and create a `MediaAsset` with `role: line_pay_qr` for every temple.
- Until real uploads ship, the admin profile shows this asset with explanatory text.
- When LINE Pay credentials arrive, the owner admin can swap the QR via the upcoming upload flow; the API will continue to return the `media_assets` array so Vue/Expo clients stay stable.

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
- [ ] Placeholder QR present (`temple.media_assets.line_pay_qr`).
- [ ] Owner admin provisioned (dev task or manual promote).
- [ ] Admin UI tested (profile edit, audit log, QR display).
- [ ] Deployment notes updated only for template-level changes; keep temple-specific updates here.
