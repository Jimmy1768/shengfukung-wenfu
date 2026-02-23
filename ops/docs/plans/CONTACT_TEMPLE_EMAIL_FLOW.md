# CONTACT TEMPLE EMAIL FLOW PLAN

## Purpose

- Provide a lightweight support channel from account portal to temple staff.
- Avoid building full messaging/chat while still giving patrons a reliable contact path.

## Product Intent

- `Contact Temple` is for general questions (non-urgent, non-transactional).
- Patron submits a short form in account portal.
- System sends:
  - acknowledgment email to patron
  - notification email to temple contact inbox (resolved by temple slug / current temple context)

## Scope

- Shared contact-email delivery foundation (usable by account and public-site entry points).
- Rails backend endpoint + mailer delivery.
- Brevo-backed outbound delivery (transactional sender).
- Basic anti-abuse controls and structured app logging.
- No admin reply UI, no threaded conversations, no inbox module.

## Out of Scope

- Full support ticket system.
- In-app chat.
- File attachments.
- SLA/routing engine.

## UX Placement (Revised)

- Public site (Vue):
  - `Contact Temple` / `Email Us` CTA opens a modal form.
  - Supports non-patrons and patrons who cannot sign in.
- Account portal (Rails):
  - Always-visible `Email Us` CTA in account header/nav area.
  - Opens a modal form (not hidden inside `Profile`).
  - Prefills signed-in patron identity/contact info when available.
- Keep copy explicit: this is email-based and may not be immediate.

Note:
- Current Rails implementation may temporarily render on profile during backend rollout, but target UX is header CTA + modal.

## Data / Persistence

- No database table in initial version.
- Request is processed through mail delivery only (Phase 1: synchronous send in request cycle).
- Keep structured logs with temple slug, user id, and request id for traceability.

Notes:
- Keep message body length-limited and sanitized.

## Backend Flow

1. Patron submits form (`subject`, `message`).
2. Backend validates request payload and temple context.
3. Backend resolves recipient temple email:
   - current temple (slug-bound account context)
   - fallback temple profile contact email
   - fallback global support email (if temple email missing)
4. Send two emails via mailer:
   - to patron: receipt/thank-you
   - to temple: new contact request summary + patron callback info
5. Log delivery outcome (success/failure) with request metadata.

Development mode note:
- In local development, allow a dev-only email override so both patron + temple emails route to one test inbox (for example `DEV_EMAIL`).
- Production must always use real resolved recipients.

## API / Controller Draft

- `POST /account/contact_temple_requests`
- Params:
  - `subject`
  - `message`
- Response:
  - success toast/flash
  - generic failure message (no internal error details)

Implementation note:
- Controller should not talk to Brevo directly.
- Use service orchestration (`controller -> service -> email/mailer adapter -> Brevo client`).

## Security / Guardrails

- Require authenticated account session.
- Rate limit by `user_id` + IP (initial target: 3/hour/user + IP guard; tune later).
- Minimum/maximum length validation.
- Strip HTML; plain-text only.
- Add spam honeypot field (optional).

Notes:
- Phase 1 may use a local/service-level throttle for speed.
- Long-term, this should plug into the generalized request-protection system (`api_usage_logs`, `api_request_counters`, `blacklist_entries`) so abuse controls are consistent across the project.

## Observability

- Log request lifecycle with request id.
- In development, when email sink override is active, log both:
  - intended recipients
  - actual sink recipient
- Track counters from logs/metrics:
  - submitted
  - delivered
  - failed
- Add DB persistence later only if operations require retry queue or audit UI.

## Implementation Phases

### Phase A: Domain + Persistence

- [x] Add endpoint/service validation for `subject` + `message`.
- [ ] Add policy scope to ensure account can only create for own temple context.
- [x] Add structured logging payload (request id, temple slug, user id, result).
- [x] Add simple local throttle guard (Phase 1) pending generalized system-wide throttling rollout.

### Phase B: Delivery

- [x] Add mailer templates (patron acknowledgment + temple notification).
- [x] Add delivery service wrapper with clear success/failure logging.
- [x] Reuse existing Brevo transport stack (`Notifications::BrevoClient`) via service/email adapter boundary.
- [x] Add fallback behavior when temple email is missing.
- [x] Add development-only email override (`DEV_EMAIL`) for local testing.

### Phase C: Account UI

- [x] Add account header/nav `Email Us` CTA (persistent across account screens).
- [x] Open `Contact Temple` modal from header CTA (do not keep this feature buried in profile page).
- [x] Prefill signed-in user identity/contact info in modal.
- [x] Show success/error flash states.
- [x] Add clear expectation copy on response time.

### Phase C2: Vue Public UI (Follow-up)

- [ ] Add Vue `Contact Temple` / `Email Us` CTA + modal for public site.
- [ ] Reuse demo-showcase contact/modal interaction pattern where practical.
- [ ] Submit to a public endpoint backed by the same shared delivery service.

### Phase D: Test Coverage

- [x] Request create success path.
- [x] Invalid payload rejects with validation errors.
- [x] Email fan-out sends to both patron and temple.
- [ ] Missing temple email fallback behavior.
- [ ] Rate limiting blocks abusive request bursts.

## Integration Roadmap (Beyond Phase 1)

- Generalized request protection / throttling:
  - Move feature-specific throttles into the shared abuse-protection framework.
  - Apply endpoint-class rules consistently across API and selected HTML POST endpoints.
  - See: `SYSTEM_WIDE_ABUSE_PROTECTION_RATE_LIMITING_PLAN.md`.
- Email queue + dedupe:
  - Move synchronous send to Sidekiq/worker delivery.
  - Add dedupe/idempotency controls at dispatch/enqueue layer.
  - See: `EMAIL_DELIVERY_QUEUE_AND_DEDUPE_PLAN.md`.

## Open Decisions

- [ ] Should duplicate submissions within a short window be deduplicated?
  - Decision deferred to queued email delivery phase (Sidekiq / dispatch layer).
- [x] Should temple notification include direct links to patron records?
  - No for Phase 1; defer until temples request inbox-to-admin handoff shortcuts.
  - Rationale: this flow is email-inbox-first, not an in-app ticket workflow.
- [ ] Keep category dropdown (billing/registration/other) now or defer?
- [x] Email template strategy for Phase 1 (Rails vs Brevo templates)?
  - Use simple Rails-rendered email templates (HTML + plain text) in repo.
  - Do not use Brevo template IDs for Phase 1.
  - Rationale: no-reply/utility emails, low design churn, easier template/project maintenance across deployments.

## Delivery Provider Notes (Brevo + Zoho)

- Brevo is the outbound transactional sender API used by Rails.
- Zoho (or similar mailbox host) is where temple staff receive and reply to inbox mail (for example `help@temple-name.org.tw`).
- For TempleMate (multi-temple project), Phase 1 can use one project-level Brevo API key with multiple temple-specific sender/reply-to identities.
- Temple-specific mailbox/domain hosting cost (for example Zoho domain/email setup) is separate from Brevo API usage.
- Keep Brevo API key in the project env file (for example `/etc/default/<slug>-env`), not in code.

## Agreed Implementation Defaults (Current)

- Delivery mode (Phase 1): synchronous send in request cycle
  - keep service boundary so background job delivery can be introduced later without controller/API changes
- Temple recipient resolution:
  - temple-specific contact/support email
  - fallback temple profile contact email
  - fallback global support email
- Patron acknowledgment:
  - confirmation email only (no complex reply handling in Phase 1)
- Template strategy:
  - Rails-rendered email templates first (not Brevo template IDs in Phase 1)
- Development testing:
  - optional dev-only recipient override via `DEV_EMAIL`
  - routes both patron + temple emails to one test inbox locally
  - production ignores this override behavior
  - verified end-to-end in local development on February 23, 2026 (Brevo recent activity showed both temple + patron emails delivered to `DEV_EMAIL`)
- UX direction:
  - use modal-based entry points (public Vue + account header CTA)
  - avoid hiding contact email in a single account screen like profile

## Deferred

- [ ] Add `temple_contact_requests` table if retry queue/audit UI becomes necessary.
- [ ] Admin-side ticket board for contact requests.
- [ ] Webhook integration (Slack/LINE/Discord) for temple teams.
