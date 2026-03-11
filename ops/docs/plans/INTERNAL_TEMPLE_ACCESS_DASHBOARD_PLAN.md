# Internal Temple Access Dashboard Plan

## Goal

Create an internal-only ops dashboard that lets the platform operator (`jimmy1768`) grant or revoke temple-scoped owner access for their own internal admin identity without introducing a global super-admin role.

This is an operations convenience tool, not a client-facing admin feature.

## Product rules

- Do **not** add a true global super-admin bypass.
- Keep temple access explicit and auditable through `AdminTempleMembership`.
- Use one internal platform admin identity that can hold memberships on many temples.
- The dashboard should help grant/revoke those memberships quickly.

## Why this exists

Current model:

- one `User`
- one `AdminAccount`
- one `AdminTempleMembership` per temple

This is the safer architecture, but it becomes tedious when onboarding many temples.

The internal dashboard solves the operations friction while preserving:

- least privilege
- per-temple auditability
- clear offboarding and revocation

## Scope

### In scope

- Internal-only page listing temples
- Per-temple action:
  - grant `owner` membership to internal platform account
  - revoke membership
- Simple visibility into current access state
- Audit logging for every grant/revoke

### Out of scope

- Global cross-tenant permission bypass
- Client-facing admin tooling
- Bulk-import automation for all staff
- Non-platform self-service role escalation

## Current gap

Today, the underlying access model is correct but the operator workflow is still manual:

- create or identify the internal `User`
- ensure `AdminAccount` exists
- add `AdminTempleMembership`
- optionally add `AdminPermission`

This is currently done through Rails console or ad hoc admin actions. That is workable for one temple, but it does not scale cleanly as more temples are onboarded.

## User story

As the platform operator, I want to click once on a temple and grant myself owner-level access for that temple so I can perform setup, debugging, and recovery work without manually using Rails console each time.

## Security model

- Dashboard must be internal-only.
- Only the platform operator account should be allowed to use it.
- Every change must create a `SystemAuditLog` entry.
- Granting access should create explicit temple membership rows, not hidden bypass logic.
- Revocation should remove or deactivate the corresponding membership cleanly.

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

- `Grant owner access`
- `Grant support access`
- `Revoke access`
- optional: `Open admin as this temple`

### Button behavior

- If no membership exists, `Grant owner access` creates one with role `owner`
- `Grant support access` does the same but with role `support`
- If membership exists, show current state and `Revoke access`
- Every destructive action should require confirmation

## Data model

No new cross-tenant authorization model is needed.

Expected behavior:

1. Find the internal platform `User`
2. Ensure it has an `AdminAccount`
3. Create or update `AdminTempleMembership` for selected temple with role `owner`
4. Optionally ensure matching `AdminPermission` defaults exist if required by current owner UX

Preferred role behavior:

- `owner` grant should also ensure `AdminPermission.manage_permissions = true`
- `support` grant should create the membership without owner-level permission management
- same `AdminAccount` is reused across all temples for the internal operator identity

## Routing / surface

Recommended:

- keep this under a clearly internal namespace, not the normal temple admin dashboard
- examples:
  - `/internal/temples/access`
  - `/ops/temples/access`

Do **not** place it in the normal client-facing `/admin` navigation for temple users.

Recommended implementation:

- controller namespace: `Internal::TempleAccessController`
- layout: reuse admin layout for speed, but brand it clearly as internal ops
- nav entry: none in client-facing admin

## Audit requirements

Every grant / revoke action should record:

- acting admin/user
- target temple
- target internal admin account
- action (`grant_owner_access`, `revoke_owner_access`)
- previous state
- resulting state

## Implementation phases

### Phase 1

- Define access policy for internal-only route
- Add list view of all temples
- Resolve internal platform account from env/config
- Decide internal env var name:
  - suggested: `INTERNAL_PLATFORM_OPERATOR_EMAIL`

### Phase 2

- Add grant action
- Create `AdminAccount` if missing
- Create/update `AdminTempleMembership(role: owner)`
- Write audit log
- Add support-role grant path at the same time to avoid owner overuse

### Phase 3

- Add revoke action
- Remove or deactivate temple membership
- Confirm temple no longer appears in accessible list for that account
- Define revocation behavior:
  - default recommendation: delete membership row, keep `AdminAccount`

### Phase 4

- Polish UI
- Add confirmation modal
- Add “open temple admin” shortcut if useful
- Add status badges:
  - no access
  - support
  - owner

## Suggested defaults

- internal operator account email comes from env, not hardcoded in code
- grants should be temple-scoped only
- revocation should delete membership rows rather than inventing another inactive state unless the existing schema already supports inactive memberships cleanly
- operator should be able to grant either:
  - `support`
  - `owner`

## First build target

Build the smallest useful slice first:

1. internal-only list of temples
2. detect current operator access state
3. one-click `Grant owner access`
4. one-click `Revoke access`
5. audit log for both actions

That is enough to remove the current console dependency.

## Open questions

- Should revoke remove only membership, or also clean `AdminPermission` rows for that temple?
- Should “open temple admin” just redirect into normal `/admin` with temple slug context, or also set temple session explicitly?
- Do we want a dev-only fallback operator email when env var is absent?

## Success criteria

- Platform operator can grant themselves owner access to a temple in one click
- Access still remains temple-scoped
- No global super-admin role is introduced
- Every change is auditable
- Revocation is equally easy
