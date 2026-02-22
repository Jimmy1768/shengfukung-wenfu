# EXPO MULTI-ROLE MODE SWITCH PLAN

## Purpose

- Define how a single Expo app can support both patron and admin workflows safely.
- Establish a server-driven role/capability model for mobile UX.
- Prepare for future `api/v1/admin/*` endpoints without mixing patron/admin behavior.

## Problem Statement

- A user may be:
  - patron only
  - admin only (rare)
  - patron + admin (same account upgraded with admin permissions)
- The app must avoid mixing patron/admin actions in one confusing UI.
- The server must remain the source of truth for permissions.

## Product Direction (Agreed)

- One Expo app supports both audiences.
- App shows a mode switch when the authenticated user has admin capability.
- Default mode after login should be `Patron` (safer, simpler).
- Admin mode is conditional and server-authorized.

## Core Concepts

### Modes

- `Patron mode`
  - self-service registrations, payments, certificates, profile/history
- `Admin mode`
  - operational/admin workflows allowed by server permissions

### Roles vs Capabilities

- Do not rely only on a single role string in the app UI.
- Prefer a capability payload returned by the server.
- Examples:
  - `account.read`
  - `account.registrations.read`
  - `admin.dashboard.read`
  - `admin.registrations.read`
  - `admin.payments.manage`

## Authentication + Role Resolution (Target Flow)

1. User authenticates via mobile auth endpoint (future `api/v1/auth/*`).
2. Server returns token/session.
3. App fetches current session/user capabilities (for example `api/v1/account/me` or `api/v1/session`).
4. App determines available modes from server payload:
   - patron only -> patron mode only
   - patron + admin -> show mode switch
5. App renders navigation and screens for the active mode.
6. Server enforces permissions on every admin endpoint regardless of UI mode.

## API Direction (Future)

- Patron/mobile account endpoints:
  - `api/v1/account/*`
- Admin/mobile endpoints (future):
  - `api/v1/admin/*`
- Auth/session endpoints (future):
  - `api/v1/auth/*` and/or `api/v1/session`

### Important Rule

- Expo is a client, not a namespace owner.
- Do not create `expo/*` controller namespaces for role handling.

## Mode Switch UX (Recommended)

### Visibility Rules

- Hide admin mode entirely when user lacks admin capability.
- Show admin mode only when server payload indicates active admin access.

### Default Behavior

- After login: land in `Patron mode`.
- Preserve last selected mode locally (if still authorized).
- Revalidate mode availability after token refresh / app launch.

### UI Cues

- Clear persistent mode indicator (`Patron` / `Admin`).
- Different nav sets per mode.
- Optional visual accent difference to reduce mistaken actions.

## Security Requirements

- UI mode is not authorization.
- All `api/v1/admin/*` endpoints must perform server-side admin auth + permission checks.
- Re-check capabilities after token refresh and app resume (as appropriate).
- If admin capability is revoked, app must:
  - remove admin mode
  - redirect out of admin screens

## Multi-Temple Admin Considerations (Future)

- Some admins may manage multiple temples.
- Capability/session payload should include temple scope metadata.
- Admin mode may require:
  - temple selector
  - persisted selected temple
  - server-validated temple context on admin endpoints

## Data Contract (Suggested Session Payload Shape)

- `user`
  - id, display name
- `modes`
  - `patron: true/false`
  - `admin: true/false`
- `capabilities`
  - list of capability keys
- `admin_context` (optional)
  - active status
  - role
  - temple ids/slugs in scope

## Implementation Phases

### Phase A: Mobile Auth + Session Payload Contract

- [ ] Define auth/session endpoints and response payload for Expo.
- [ ] Include server-driven mode availability + capabilities.
- [ ] Document token refresh and role revalidation behavior.

### Phase B: Expo Navigation + Mode Switch

- [ ] Add mode-switch UI and state management.
- [ ] Build patron-mode navigation shell.
- [ ] Add admin-mode shell placeholder (gated by capability).
- [ ] Persist last selected mode locally.

### Phase C: Admin Mobile Endpoints

- [ ] Introduce `api/v1/admin/*` endpoints needed by Expo.
- [ ] Enforce admin permissions server-side.
- [ ] Add tests for unauthorized access and mode/capability changes.

### Phase D: Hardening

- [ ] Handle admin revocation mid-session gracefully.
- [ ] Add telemetry/audit for admin mobile actions (as needed).
- [ ] Validate UX for older users and staff with minimal training.

## Risks + Mitigations

- Risk: mixing patron/admin actions confuses users.
  - Mitigation: explicit mode switch + separate nav shells.
- Risk: client-side role assumptions become stale.
  - Mitigation: server-driven capabilities + refresh revalidation.
- Risk: elevated actions exposed accidentally.
  - Mitigation: strict server-side checks on all admin endpoints.

## Acceptance Criteria

- Expo app supports patron-only users without admin UI noise.
- Expo app supports patron+admin users with a clear mode switch.
- Admin endpoints are protected server-side independent of UI mode.
- Future `api/v1/admin/*` work can proceed without namespace ambiguity.
