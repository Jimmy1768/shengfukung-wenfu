# Admin Role Transitions Plan

## Goal

Let a temple owner promote or demote existing temple admins between `admin` and `owner` without using Rails console.

This is temple-scoped admin management. It is separate from the internal operator dashboard at `/internal/temples/access`.

## Why this exists

Current workflow:

- user creates a normal patron account
- an existing owner or platform operator promotes that user into an admin
- after that, changing the role still requires ad hoc manual handling

This is not enough for real temple operations. Once the temple owner is active, they need a controlled way to:

- promote an admin to owner
- demote an owner back to admin
- recover from mistaken initial role assignments

## Product rules

- Role changes are temple-scoped.
- No role change should affect other temples.
- The acting user must already have temple-level authority to manage permissions.
- There must always be at least one owner on a temple.
- Role changes must be auditable.

## Scope

### In scope

- Change an existing admin membership role for the current temple
- Supported transitions:
  - `admin -> owner`
  - `owner -> admin`
- Update the temple-scoped `AdminPermission` row to match the new role defaults
- Guardrails to prevent removing the last owner
- Audit logging

### Out of scope

- Creating admin users from scratch
- Granting platform operator self-access
- Cross-temple bulk role changes
- Invitation/email flows

## Current model

- `AdminAccount` is the reusable admin identity
- `AdminTempleMembership` carries the temple-scoped role
- `AdminPermission` carries the temple-scoped capability flags

So the role transition should primarily update:

1. `AdminTempleMembership.role`
2. `AdminPermission` defaults for that temple

It should not rewrite unrelated memberships on other temples.

Implementation note:

- product/UI language should use `admin`
- current runtime enum may still persist that non-owner role as `staff`
- avoid exposing `staff` or `support` labels in temple-facing UI

## Recommended UX

Surface: temple admin console, likely under the existing admin permissions/admin management area.

For each admin row on the current temple:

- display current temple role
- show available role change actions
- confirm destructive changes

Suggested actions:

- `Promote to owner`
- `Change to admin`

If the row is already the current role, do not show a no-op action.

## Permission model

### Who can perform transitions

- temple `owner`
- admins with `manage_permissions = true`

### Who cannot

- normal temple admins without `manage_permissions`

## Guardrails

### Last owner protection

- If the current temple has only one owner membership left, block demotion or revocation of that owner.
- Error message should be explicit:
  - the temple must retain at least one owner

### Self-demotion

- Allow only if another owner still exists
- otherwise block it

### Cross-temple isolation

- Only mutate the membership and permission row for `current_temple`
- never touch the admin’s other temple memberships

## Permission defaults by role

### Owner

- full operational permissions
- `manage_permissions = true`

### Admin

- narrower daily-operations set
- no permission-management capability

Exact defaults should reuse the same logic already used by the internal temple access dashboard where possible.

## Audit requirements

Each role transition should write a `SystemAuditLog` with:

- acting admin/user
- target admin account
- target user email
- temple
- previous role
- resulting role
- previous relevant permission state
- resulting relevant permission state

Suggested actions:

- `admin.permissions.promote_owner`
- `admin.permissions.change_admin`

## Implementation phases

### Phase 1

- Decide canonical role-transition service object
- centralize temple-scoped role -> permission-default mapping
- define last-owner guard

### Phase 2

- add controller action(s) in normal admin namespace
- update membership role
- update temple-scoped permission row
- add audit logging

### Phase 3

- expose role actions in the admin permissions/admins UI
- add confirmation UX
- show clearer role badges

### Phase 4

- add tests for:
  - promote to owner
  - demote owner when another owner exists
  - block demotion of last owner
  - cross-temple isolation

## Success criteria

- Temple owner can change another admin’s temple role without Rails console
- Role changes only affect the current temple
- Last owner cannot be removed accidentally
- Permission rows stay in sync with the role
- Every transition is auditable
