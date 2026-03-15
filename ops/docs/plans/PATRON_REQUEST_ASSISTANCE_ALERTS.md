# PATRON REQUEST ASSISTANCE ALERTS PLAN

## Purpose

- Add a one-tap urgent help signal from patrons to temple admins.
- Keep implementation intentionally simple (alert/ticket style, not messaging).

## Product Intent

- `Request Assistance` is a lightweight help signal from a patron to the current temple.
- V1 is not chat, not a helpdesk, and not real-time paging.
- In V1, "notify admins" means the request appears in the admin queue/dashboard for that temple.
- No long text thread required.

## Core Rules

- Patron can open an assistance request tied to their temple context.
- Request may optionally include `registration_id` when triggered from registrations.
- Request remains `open` until an admin closes it.
- Any temple admin can close it.
- V1 uses only two states:
  - `open`
  - `closed`
- V1 should dedupe open requests instead of creating alert spam.

## Scope

- Account portal button(s) to open alert.
- Backend model + endpoint to create/close alerts.
- Admin dashboard widget/list of open alerts.
- This is the only new support-request table in the initial rollout.

## Out of Scope

- Two-way chat.
- Complex assignment workflow.
- Rich ticket metadata and custom states.
- Push/email/SMS notifications.
- Contact Temple email persistence (handled as email-forward flow without DB table).

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
  - `message` (optional, short text only)
  - `metadata` (jsonb, optional)

Constraints:
- Index for open queue: `(temple_id, status, requested_at desc)`.
- V1 uniqueness guard: one open request per `(temple_id, user_id, temple_registration_id)`.
- If no registration is attached, one open request per `(temple_id, user_id, null-registration)`.

## Backend Flow

### Create

1. Patron taps `Request Assistance`.
2. Backend validates session + temple scope.
3. Backend creates a new open request or reuses the existing open request for dedupe.
4. Patron sees confirmation UI.

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
  - optional short message
  - quick links: patron profile, registrations list, request close action

## KPI Alignment

Replace weak/non-actionable KPI with:
- `Open assistance requests`
- `New registrations (7d)`
- `Unpaid registrations`
- `Revenue (MTD)` (optional)

## V1 Decision

Keep V1 narrow:

- creation from account portal
- open/closed admin queue
- dashboard visibility
- dedupe guard
- no push/email fan-out
- no assignment
- no extra states

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
- [ ] Allow optional short message only.
- [ ] Add clear confirmation state after submit.

### Phase C: Admin UX

- [ ] Add open queue widget to dashboard.
- [ ] Add dedicated admin list page if dashboard card alone becomes too cramped.
- [ ] Add links to patron + registrations context.
- [ ] Add close action with optimistic update.

### Phase D: Test Coverage

- [ ] Account create succeeds and is temple-scoped.
- [ ] Duplicate rapid taps do not create alert storms.
- [ ] Admin close updates status and audit fields.
- [ ] Dashboard shows only open requests for current temple.
- [ ] Authorization blocks cross-temple access.

## Open Decisions

- [x] V1 dedupe rule: reuse one open request instead of creating repeated open rows.
- [x] V1 close action does not require a reason code.
- [x] V1 any temple admin can close.

## Deferred

- [ ] Push/email/SMS fan-out.
- [ ] Full ticket lifecycle (assigned/in-progress/escalated).
- [ ] Patron-visible status timeline.
- [ ] Analytics dashboard for response time SLA.
