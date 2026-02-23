# Inquiry / Support Workflows Reference

Snapshot of inquiry/troubleshooting/support request workflows and their current implementation status.

This document intentionally groups multiple related workflows under one topic instead of mirroring individual planning docs 1:1.

## Contact Temple / Email Us (Implemented)

### Scope (Current)

- Shared email delivery flow used by:
  - Rails account portal (`/account`)
  - Vue public site footer CTA
- Delivery is synchronous in the request cycle (no Sidekiq queue yet).
- No DB persistence table for contact requests in Phase 1.

### Entry Points

#### Account Portal (Rails)

- Persistent `Email Us` CTA appears in the account header utility actions area.
- CTA opens a modal form (not a profile page section).
- Form displays signed-in patron identity/contact context and submits to `POST /account/contact_temple_requests`.
- Success redirects back to the originating account page via `return_to` (safe-account-path fallback behavior).

#### Public Site (Vue)

- Footer `Email Us` CTA lives in the footer contact block near phone/contact links.
- CTA opens the reusable Vue `ContactDrawer` modal.
- Submit target: `POST /api/v1/temples/:slug/contact_temple_requests`
- Success closes the modal and shows a lightweight footer confirmation message.

### Request Payloads

#### Account (authenticated)

- `subject`
- `message`
- `website` (honeypot)

#### Public Vue (guest)

- `name`
- `email`
- `subject`
- `message`
- `website` (honeypot)

### Delivery Flow

- Shared service: `Contact::TempleInquirySender`
- Sends two emails:
  - temple notification
  - patron/guest acknowledgment
- Temple recipient resolution:
  - temple-specific contact/support email (intended production default)
  - fallback temple profile contact email
  - fallback global support email (`support@sourcegridlabs.com`)

### Development Behavior

- `DEV_EMAIL` overrides both patron + temple recipients in development.
- Use this as a sink inbox for local testing to avoid sending to real addresses.
- Verified end-to-end on February 23, 2026 (Brevo activity + inbox receipt).

### Branding / Sender Identity (Current)

- Infrastructure sender display name is project-configured (`TempleMate` in this repo).
- Contact Temple emails now use a dynamic display name in the format `<Active Temple Name> via <Infrastructure Sender Name>` (for example `竹南鎮聖福宮 via TempleMate`).
- Sender email remains shared infrastructure sender (`no-reply@sourcegridlabs.com`) unless ops config changes it.
- Email body content remains contextual to the active temple (temple name included in body copy).

### Alias / Inbox Configuration Locations (Ops)

- Temple/client recipient aliases (where notifications should go) should be entered in temple profile contact/support email fields:
  - production/admin UI temple profile (preferred once configured)
  - or seed/source data for temple profile content (for example `rails/db/temples/<slug>.yml`) before deploy/seed
- Shared infrastructure sender email alias (Brevo sender) is configured in the droplet env file:
  - `BREVO_SENDER_EMAIL` in `/etc/default/<slug>-env` (or your configured `PROJECT_SYSTEMD_ENV_FILE`)
- Dev recipient sink override is configured locally via:
  - `DEV_EMAIL` in `.env.development`

### Email Copy (Current)

- Contact Temple email bodies are currently zh-TW only (Phase 1 choice).
- Temple notification wording is channel-neutral (no account/public technical source wording).
- Future multilingual support should move copy to I18n without changing controller/service contracts.

### Security / Guardrails

- Account flow requires authenticated account session.
- Public flow is guest-capable and slug-scoped.
- Local throttle is enforced via `Contact::TempleInquiryRateLimiter`.
- Honeypot field is present on both account and public forms.

### Tests (Implemented)

- Account integration tests:
  - success
  - invalid payload
  - `DEV_EMAIL` recipient override
- Public API integration tests:
  - success
  - invalid payload
  - fallback recipient behavior
  - throttle block behavior

### Deferred Follow-ups

- Generalized throttling integration
- Queue + dedupe (Sidekiq)
- Admin-side inbox/ticket UI
- Webhook notifications (Slack/LINE/Discord)
- Optional per-context sender email (domain-specific `From` address) after domain DNS/SPF/DKIM + Brevo sender validation is operationally ready

## Request Assistance (Placeholder / Not Implemented Yet)

These UI affordances exist but do not yet use a dedicated email delivery pipeline:

- Account dashboard quick action (`Contact temple`) is still placeholder/legacy UI in some surfaces.
- Account dependents section `Request assistance` action is a placeholder (`turbo_confirm`) and does not submit an email request.

When implemented, this section should document:

- entry points
- payload shape
- recipient routing
- email templates
- fallback behavior
- tests

## Related Docs

- `ops/docs/reference/account_portal.md`
- `ops/docs/reference/deployment_notes.md`
