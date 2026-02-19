# PATRON REQUEST ASSISTANCE ALERTS PLAN

## Purpose

- Add a one-tap urgent help signal from patrons to temple admins.
- Keep implementation intentionally simple (alert/ticket style, not messaging).

## Product Intent

- `Request Assistance` is for urgent callback/help situations.
- No long text thread required.
- Admin dashboard should surface open assistance requests with fast action links.

## Core Rules

- Patron can open an assistance request tied to their temple context.
- Request may optionally include `registration_id` when triggered from registrations.
- Request remains `open` until an admin closes it.
- Any temple admin can close it.

## Scope

- Account portal button(s) to open alert.
- Backend model + endpoint to create/close alerts.
- Admin dashboard widget/list of open alerts.
- Optional push/email fan-out hook (phase-gated).

## Out of Scope

- Two-way chat.
- Complex assignment workflow.
- Rich ticket metadata and custom states.

## UX Placement Decision

- Primary placement: `Account > Registrations` (list/detail), because issues are often registration-specific.
- Secondary fallback: `Account > Profile` generic request.

Rationale:
- Reduces ambiguity by capturing context when patron is already in registration flow.
- Still keeps a global fallback for non-registration issues.

## Data / Persistence

- Add `temple_assistance_requests` table (or equivalent):
  - `temple_id` (required)
  - `user_id` (required)
  - `temple_registration_id` (optional)
  - `status` (`open`, `closed`)
  - `requested_at` (required)
  - `closed_at` (nullable)
  - `closed_by_admin_id` (nullable)
  - `channel` (`profile`, `registration_list`, `registration_detail`)
  - `metadata` (jsonb, optional)

Constraints:
- Index for open queue: `(temple_id, status, requested_at desc)`.
- Optional uniqueness guard: one open request per `(temple_id, user_id, temple_registration_id)`.

## Backend Flow

### Create

1. Patron taps `Request Assistance`.
2. Backend validates session + temple scope.
3. Backend creates (or reuses) open request for dedupe window.
4. Backend emits notification event (email/push hook).
5. Patron sees confirmation UI.

### Close

1. Admin clicks close/resolve from dashboard.
2. Backend marks request closed with actor + timestamp.
3. Request removed from open queue.

## Admin Dashboard Integration

- Add `Open Assistance Requests` card/section.
- Each row should show:
  - patron display name
  - request time
  - optional linked registration
  - quick links: patron profile, registrations list, request close action

## KPI Alignment

Replace weak/non-actionable KPI with:
- `Open assistance requests`
- `New registrations (7d)`
- `Unpaid registrations`
- `Revenue (MTD)` (optional)

## Notifications (Phase-Gated)

Phase 1:
- In-app admin dashboard queue only.

Phase 2:
- Push/email fan-out to temple admins on create.
- No per-admin assignment yet.

## Security / Guardrails

- Auth required for create/close.
- Account can only create within bound temple slug context.
- Admin can only close requests for current temple.
- Rate limit repeated request spam.
- Minimal payload to reduce abuse surface.

## Implementation Phases

### Phase A: Domain + Endpoints

- [ ] Add assistance request model + migration.
- [ ] Add create endpoint for account portal.
- [ ] Add close endpoint for admin portal.
- [ ] Add dedupe guard for repeated quick taps.

### Phase B: Account UX

- [ ] Add button on registrations list/detail.
- [ ] Add fallback button on profile.
- [ ] Add clear confirmation state after submit.

### Phase C: Admin UX

- [ ] Add open queue widget to dashboard.
- [ ] Add links to patron + registrations context.
- [ ] Add close action with optimistic update.

### Phase D: Notifications

- [ ] Add notifier interface (push/email adapter).
- [ ] Send create-event alert to temple admins.
- [ ] Add retry/failure logging.

### Phase E: Test Coverage

- [ ] Account create succeeds and is temple-scoped.
- [ ] Duplicate rapid taps do not create alert storms.
- [ ] Admin close updates status and audit fields.
- [ ] Dashboard shows only open requests for current temple.
- [ ] Authorization blocks cross-temple access.

## Open Decisions

- [ ] Should create always open a new row, or reopen last closed within N minutes?
- [ ] Should close require a reason code (now vs later)?
- [ ] Which admin roles can close (owner only vs staff + owner)?

## Deferred

- [ ] Full ticket lifecycle (assigned/in-progress/escalated).
- [ ] Patron-visible status timeline.
- [ ] Analytics dashboard for response time SLA.
