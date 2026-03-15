# Internal Temple Access Dashboard Plan

## Goal

Create an internal-only ops dashboard that lets the platform operator (`jimmy1768`) bootstrap temple access without introducing a global super-admin role.

This is an operations console, not a client-facing admin feature.

## Product rules

- Do **not** add a true global super-admin bypass.
- Keep temple access explicit and auditable through `AdminTempleMembership`.
- Use one internal platform admin identity that can hold memberships on many temples.
- Keep role elevation for temple people centralized in the internal ops surface.

## Why this exists

Current model:

- one `User`
- one `AdminAccount`
- one `AdminTempleMembership` per temple

This is the safer architecture, but onboarding still requires manual steps:

- give the operator access to the new temple
- identify the first real temple owner/admin after they sign up
- promote those users into temple admins

This is currently done through Rails console or ad hoc admin actions. That does not scale cleanly as more temples are onboarded.

## Scope

### In scope

- Internal-only page listing temples
- Per-temple operator actions:
  - grant `owner` access to the platform operator account
  - grant `admin` access to the platform operator account
  - revoke the operator’s temple access
- Internal temple bootstrap actions:
  - inspect temple patrons/admins
  - promote an existing patron to temple `owner`
  - promote an existing patron to temple `admin`
  - revoke temple admin access when needed
- Simple visibility into current access state
- Audit logging for every grant/revoke/promotion action

### Out of scope

- Global cross-tenant permission bypass
- Client-facing admin tooling
- Bulk-import automation for all staff
- Temple-owner self-service role escalation inside normal `/admin`

## Current gap

Today, the access model is correct but the workflow is split awkwardly:

- operator self-access is manual without the internal page
- bootstrap promotion of the first owner/admin is still manual or ad hoc

The internal dashboard should be the single place for platform-run bootstrap actions.

## User story

As the platform operator, I want to:

- grant myself temple access
- inspect a temple’s people
- promote the first owner/admin

without using Rails console.

## Security model

- Dashboard must be internal-only.
- Only the platform operator account should be allowed to use it.
- Every change must create a `SystemAuditLog` entry.
- Access should be temple-scoped only.
- Promotion actions should update only the selected temple’s membership/permission rows.

Recommended guard:

- gate the namespace by a fixed internal operator email configured in env
- do not expose the route in normal temple admin navigation
- fail closed when the configured operator account is missing

## Proposed UX

### Page: Internal Temple Access

For each temple row show:

- temple name
- slug
- published / onboarding status
- whether the internal platform admin already has access
- current membership role for that temple

Actions:

- `Grant owner`
- `Grant admin`
- `Revoke`
- `Manage temple people`

### Page: Internal Temple Access Detail

For the selected temple show:

- temple name / slug
- whether the operator currently has access
- current temple admins and their roles
- current patrons eligible for promotion

Actions:

- `Promote to owner`
- `Promote to admin`
- `Revoke temple admin access`

## Role model

Temple-facing product roles should be:

- `owner`
- `admin`

Meaning:

- `owner` can operate and manage permissions/admins
- `admin` can operate but cannot manage permissions/admins

Current runtime may still map non-owner to the legacy stored role `staff` until the role-model simplification refactor lands. Internal UI should still present `admin`.

## Data model

No new cross-tenant authorization model is needed.

Expected behavior:

1. Find the internal platform `User`
2. Ensure it has an `AdminAccount`
3. Create or update `AdminTempleMembership` for selected temple
4. Ensure matching `AdminPermission` defaults exist for that temple
5. For temple bootstrap promotions, create or update the selected user’s temple membership and temple permission row only

Preferred role behavior:

- `owner` grant/promotion should ensure `manage_permissions = true`
- `admin` grant/promotion should ensure `manage_permissions = false`
- same `AdminAccount` is reused across all temples for the internal operator identity

## Routing / surface

Recommended:

- keep this under a clearly internal namespace, not the normal temple admin dashboard
- route:
  - `/internal/temples/access`

Do **not** place these controls in the normal client-facing `/admin` navigation for temple users.

## Ownership model clarification

- Temple owners should not receive a separate owner-promotion console inside normal `/admin` for now.
- Owner/admin bootstrap and role assignment remains centralized in `/internal/temples/access`.
- Normal temple admins operate inside `/admin`; platform-controlled role elevation stays inside the internal ops surface.

## Audit requirements

Every self-access grant/revoke should record:

- acting admin/user
- target temple
- target internal admin account
- previous state
- resulting state

Every temple bootstrap promotion/revocation should record:

- acting admin/user
- target temple
- target user/admin account
- previous role
- resulting role

## Implementation phases

### Phase 1

- Define access policy for internal-only route
- Add list view of all temples
- Resolve internal platform account from env/config
- Decide internal env var name:
  - `INTERNAL_PLATFORM_OPERATOR_EMAIL`

Status:

- Built.

### Phase 2

- Add operator self-access actions:
  - grant `owner`
  - grant `admin`
  - revoke
- Persist explicit temple permission defaults
- Write audit log

Status:

- Built.
- `/internal/temples/access` now supports:
  - `Grant owner`
  - `Grant admin`
  - `Revoke`
- Grant actions create/update the operator membership and persist explicit `AdminPermission` rows.
- `owner` grants include `manage_permissions = true`.
- `admin` grants keep operational permissions but explicitly leave `manage_permissions = false`.
- Revoke deletes both the temple membership and temple-scoped permission row for that operator/temple pair.
- Every grant/revoke writes a `SystemAuditLog`.

### Phase 3

- Add per-temple detail page
- List current temple admins
- List eligible patrons for promotion
- Add bootstrap promotion actions:
  - patron -> owner
  - patron -> admin
- Add revoke/demotion path as needed
- Audit those actions

Status:

- Built.
- `/internal/temples/access/:temple_id` now exists as a per-temple detail page.
- The detail page lists temple admins and eligible patrons for promotion.
- Internal ops can promote a patron into temple `admin`.
- Internal ops can promote a patron or existing admin into temple `owner`.
- Internal ops can revoke/demote temple admin access as needed.
- Role changes update only the selected temple membership/permission rows.
- Promotion/revoke actions write `SystemAuditLog` entries.

### Phase 4

- Polish UI
- Add confirmation modal
- Add “open temple admin” shortcut if useful
- Add clearer role/status badges

Status:

- Built.
- Internal access screens include the confirmation modal flow used for sensitive actions.
- The temple detail page includes the temple-admin management shortcut/navigation path needed for ops workflow.
- Role/status presentation has been polished enough for production use.

## Validation status

- Validated on production.
- Confirmed working in production:
  - operator self-access grant/revoke
  - temple detail page access
  - eligible patron visibility
  - patron -> admin promotion
  - admin/patron -> owner promotion
  - revoke/demotion flow
  - audit-backed temple bootstrap workflow without Rails console

## Suggested defaults

- internal operator account email comes from env, not hardcoded in code
- grants should be temple-scoped only
- revocation should delete membership rows rather than inventing another inactive state unless the existing schema already supports inactive memberships cleanly
- operator should be able to grant either:
  - `admin`
  - `owner`

## First build target

Build the smallest useful slice first:

1. internal-only list of temples
2. detect current operator access state
3. one-click `Grant owner`
4. one-click `Revoke`
5. audit log for both actions

That is enough to remove the current console dependency for operator self-access.

## Open questions

- Should revoke remove only membership, or also clean `AdminPermission` rows for that temple?
- Should “open temple admin” just redirect into normal `/admin` with temple slug context, or also set temple session explicitly?
- For the temple detail page, should the operator see all patrons or just a filtered subset with no admin membership yet?

## Success criteria

- Platform operator can grant themselves temple access in one click
- Platform operator can promote the first temple owner/admin without Rails console
- Access still remains temple-scoped
- No global super-admin role is introduced
- Every change is auditable
- Revocation is equally easy

Status:

- Met.
