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

Decision note:

- do **not** map `support` to `owner`
- that would silently expand privilege for a legacy role we have already decided to remove
- owner remains the only elevated tier

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
- remove any remaining default-permission branches that special-case `support`

### Controllers / queries

- replace all role checks that explicitly reference `staff` or `support`
- preserve current behavior but with `admin` as the non-owner role

Confirmed hotspots from current code:

- `AdminAccount` enum + default permission helper
- `AdminTempleMembership` enum
- admin dashboard checks using `.staff_role`
- permissions management filters using `.staff_role`
- test helper defaults and integration fixtures that still create `role: "staff"`

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

### Risk: stale tests and fixtures

Many tests still instantiate admin users with `role: "staff"` or `membership_role: "staff"`.

Mitigation:

- update test helper defaults first
- then update direct fixture/setup calls in focused suites
- avoid leaving mixed-role strings in the tree after the refactor

## Implementation phases

### Phase 1

- [x] Audit all `staff` / `support` references
- [x] Identify which are product-facing vs internal/runtime
- [x] Decide migration mapping:
  - `staff -> admin`
  - `support -> admin`
- [x] Centralize role-default logic

### Phase 2

- [x] Add migration to remap legacy data
- [x] Change schema defaults to `admin`
- [x] Update enums in models

### Phase 3

- [x] Update controllers, queries, and internal dashboard
- [x] Update temple admin-management flow
- [x] Update UI labels/copy

### Phase 4

- [x] Update focused tests
- [x] Update docs
- [ ] Run production migration and verify existing admins still work

## Built and tested

- Added migration [`20260316000018_simplify_admin_roles.rb`](/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/migrate/20260316000018_simplify_admin_roles.rb)
- Persisted defaults now use `admin` in [`schema.rb`](/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/schema.rb)
- Runtime enums now only expose `owner` and `admin`
- Internal temple access grants `owner` or `admin` directly
- Legacy `support` special-casing was removed from permission defaults
- Admin login/internal UI copy no longer refers to `staff` access

Focused verification:

```bash
cd rails && bin/rails db:migrate
cd rails && bin/rails test test/integration/internal/temple_access_test.rb test/integration/admin/permissions_management_test.rb test/integration/admin/method_override_test.rb test/integration/admin/multi_temple_access_test.rb test/integration/admin/archives_access_test.rb
```

Result:

- `22 runs, 121 assertions, 0 failures, 0 errors`

## Success criteria

- Only `owner` and `admin` remain in persisted temple admin roles
- Existing admins continue to log in and operate correctly
- Only owners can manage permissions/admin roles
- Internal access dashboard grants `owner` or `admin` directly
- No temple-facing UI exposes `staff` or `support`
