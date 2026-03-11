# Admin Role Model Simplification Plan

## Goal

Reduce the temple admin role model from three stored roles:

- `owner`
- `staff`
- `support`

to two roles only:

- `owner`
- `admin`

This should apply to both product language and persisted runtime state.

## Why this change is needed

Current product intent is simple:

- `owner` can operate and manage permissions/admins
- `admin` can operate but cannot manage permissions/admins

The current stored model does not reflect that. It still carries:

- `staff`
- `support`

This creates avoidable problems:

- confusing product language
- ambiguous behavior between `staff` and `support`
- more complex onboarding/admin-management logic than needed
- internal tools must translate product meaning back into legacy enum values

## Product rules

- Only two temple-facing roles should exist:
  - `owner`
  - `admin`
- `owner` is just `admin` plus permission-management authority.
- No product-facing UI should expose `staff` or `support`.
- Existing temple access and permission logic must continue to work during migration.

## Scope

### In scope

- Replace `staff` / `support` with `admin` in the stored role model
- Migrate existing records safely
- Update permission defaults and guards
- Update internal access dashboard to write `admin`
- Update temple admin-management logic to use `admin`
- Update tests/docs

### Out of scope

- Invitation/email workflow changes
- Rebuilding unrelated account-role language outside temple admin usage
- Global super-admin / cross-tenant bypass logic

## Current model

Persisted today:

- `AdminAccount.role`
- `AdminTempleMembership.role`

Both still include legacy values:

- `staff`
- `support`
- `owner`

Observed runtime behavior:

- `owner` gets `manage_permissions = true`
- `support` behaves like broad operator access but without owner authority
- `staff` is used widely as the default non-owner role

That means this refactor touches both schema defaults and application logic.

## Target model

Persisted roles should become:

- `owner`
- `admin`

Behavior:

### owner

- all operational permissions
- `manage_permissions = true`

### admin

- operational permissions
- `manage_permissions = false`

## Migration strategy

### Data migration

Map legacy roles into the new model:

- `staff` -> `admin`
- `support` -> `admin`
- `owner` -> `owner`

Apply this to:

- `admins.role`
- `admin_temple_memberships.role`

Then update schema defaults from `staff` to `admin`.

## Application updates

### Models

- update enums in:
  - `AdminAccount`
  - `AdminTempleMembership`
- remove `support_role?`
- replace `staff_role?` usage with `admin_role?`

### Permission logic

- centralize default permission behavior around:
  - `owner`
  - `admin`
- ensure only `owner` gets `manage_permissions`

### Controllers / queries

- replace all role checks that explicitly reference `staff` or `support`
- preserve current behavior but with `admin` as the non-owner role

### Internal tools

- `/internal/temples/access` should write:
  - `owner`
  - `admin`
- no legacy role mapping should remain after migration

## UI / copy updates

- Use only:
  - `Owner`
  - `Admin`
- Remove `staff` / `support` labels from:
  - internal tools
  - admin management screens
  - onboarding docs
  - command docs
  - plan docs where applicable

## Risks

### Risk: broad code impact

There are many existing references to `staff` in tests and admin flow logic.

Mitigation:

- perform this as a dedicated pass
- update tests alongside code
- avoid mixing this with unrelated feature work

### Risk: permission regression

If role/permission logic is updated inconsistently, temple admins could gain or lose permission-management authority incorrectly.

Mitigation:

- keep the rule explicit:
  - only `owner` gets `manage_permissions`
- add focused permission regression tests

### Risk: existing data mismatch

If migration runs but code still expects legacy enums, runtime errors will follow.

Mitigation:

- ship migration + enum changes together
- run focused tests before deploy

## Implementation phases

### Phase 1

- audit all `staff` / `support` references
- identify which are product-facing vs internal/runtime
- centralize role-default logic

### Phase 2

- add migration to remap legacy data
- change schema defaults to `admin`
- update enums in models

### Phase 3

- update controllers, queries, and internal dashboard
- update temple admin-management flow
- update UI labels/copy

### Phase 4

- update tests
- update docs
- run production migration and verify existing admins still work

## Success criteria

- Only `owner` and `admin` remain in persisted temple admin roles
- Existing admins continue to log in and operate correctly
- Only owners can manage permissions/admin roles
- Internal access dashboard grants `owner` or `admin` directly
- No temple-facing UI exposes `staff` or `support`
