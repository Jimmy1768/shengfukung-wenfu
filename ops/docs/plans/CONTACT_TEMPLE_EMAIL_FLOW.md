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

- Account portal only (patron-facing submit action).
- Rails backend endpoint + mailer delivery.
- Basic anti-abuse controls and structured app logging.
- No admin reply UI, no threaded conversations, no inbox module.

## Out of Scope

- Full support ticket system.
- In-app chat.
- File attachments.
- SLA/routing engine.

## UX Placement

- Primary CTA: Account `Profile` page (`Contact Temple`).
- Optional secondary CTA: Account dashboard quick action.
- Keep copy explicit: this is email-based and may not be immediate.

## Data / Persistence

- No database table in initial version.
- Request is processed synchronously/asynchronously through mail delivery only.
- Keep structured logs with temple slug, user id, and request id for traceability.

Notes:
- Keep message body length-limited and sanitized.

## Backend Flow

1. Patron submits form (`subject`, `message`).
2. Backend validates request payload and temple context.
3. Backend resolves recipient temple email:
   - current temple (slug-bound account context)
   - fallback temple profile contact email
4. Send two emails via mailer:
   - to patron: receipt/thank-you
   - to temple: new contact request summary + patron callback info
5. Log delivery outcome (success/failure) with request metadata.

## API / Controller Draft

- `POST /account/contact_temple_requests`
- Params:
  - `subject`
  - `message`
- Response:
  - success toast/flash
  - generic failure message (no internal error details)

## Security / Guardrails

- Require authenticated account session.
- Rate limit by `user_id` + IP (e.g., N requests per hour).
- Minimum/maximum length validation.
- Strip HTML; plain-text only.
- Add spam honeypot field (optional).

## Observability

- Log request lifecycle with request id.
- Track counters from logs/metrics:
  - submitted
  - delivered
  - failed
- Add DB persistence later only if operations require retry queue or audit UI.

## Implementation Phases

### Phase A: Domain + Persistence

- [ ] Add endpoint/service validation for `subject` + `message`.
- [ ] Add policy scope to ensure account can only create for own temple context.
- [ ] Add structured logging payload (request id, temple slug, user id, result).

### Phase B: Delivery

- [ ] Add mailer templates (patron acknowledgment + temple notification).
- [ ] Add delivery service wrapper with clear success/failure logging.
- [ ] Add fallback behavior when temple email is missing.

### Phase C: Account UI

- [ ] Add `Contact Temple` form in profile.
- [ ] Show success/error flash states.
- [ ] Add clear expectation copy on response time.

### Phase D: Test Coverage

- [ ] Request create success path.
- [ ] Invalid payload rejects with validation errors.
- [ ] Email fan-out sends to both patron and temple.
- [ ] Missing temple email fallback behavior.
- [ ] Rate limiting blocks abusive request bursts.

## Open Decisions

- [ ] Should duplicate submissions within a short window be deduplicated?
- [ ] Should temple notification include direct links to patron records?
- [ ] Keep category dropdown (billing/registration/other) now or defer?

## Deferred

- [ ] Add `temple_contact_requests` table if retry queue/audit UI becomes necessary.
- [ ] Admin-side ticket board for contact requests.
- [ ] Webhook integration (Slack/LINE/Discord) for temple teams.
