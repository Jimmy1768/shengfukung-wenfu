# Visual & Preference Systems Reference

Cross-surface visual/theme preference reference for Vue, Rails, and Mobile (Expo).

## Scope

- Shared design token flow
- Palette policy boundaries per surface
- User preference persistence + sync contracts
- Accessibility/display-mode direction

This file is intentionally namespace-agnostic and should hold future completed work in this area (new templates, mobile accessibility modes, cross-surface preference updates).

## Source of Truth

- Palette/token source: `shared/design-system/themes.json`
- Token sync command: `node bin/sync_design_system.js`
- Generated outputs:
  - Rails tokens: `rails/app/stylesheets/shared/_tokens.scss`
  - Vue tokens: `vue/src/styles/tokens.css`, `vue/src/theme/themes.js`
  - Mobile tokens: `mobile/theme/tokens.js`

## Surface Policy

- Vue public site:
  - Supports `layout` + branded `palette`.
  - Client-safe palettes: `temple-1`, `temple-2`.
- Rails account/admin:
  - No layout switching.
  - Display modes only: `standard`, `dark`.
  - Internal mapping via `Themes::Policy`:
    - `standard` -> `ops-standard`
    - `dark` -> `ops-dark`
- Mobile (Expo):
  - Palette-only (no layout concept).
  - Allowed theme IDs: `temple-1`, `temple-2`.

## Palette Boundary

- `golden-*` palettes are demo/showcase by default and excluded from client runtime policy unless explicitly opted in.
- `ops-*` palettes are operational/display palettes for Rails (and future mobile accessibility), not public branding choices.

## Preference Persistence

### Rails (Account/Admin)

- Cookie persistence (per surface):
  - `account_display_mode`
  - `admin_display_mode`
- Backed by persistent user preference in existing table:
  - `user_preferences.metadata["display_modes"]["account"]`
  - `user_preferences.metadata["display_modes"]["admin"]`
- No schema change required.

### Mobile (Expo)

- Local preference storage:
  - `expo-secure-store` key: `komainu.theme.preference`
- Resolver order:
  1. local mobile user preference
  2. project default (`expo.extra.defaultThemeId`)
  3. hardcoded fallback (`defaultThemeId`)
- Invalid/non-mobile IDs are sanitized out.

## Cross-Surface Preference API

- Endpoint: `GET /api/v1/account/preferences`
- Endpoint: `PATCH /api/v1/account/preferences`
- Payload supports:
  - `account_display_mode`
  - `admin_display_mode`
  - `mobile_theme_id`
- Validation guards:
  - Rails modes must be in `Themes::Policy.mode_ids(:account/:admin)`
  - Mobile theme must be in `Themes::Policy.allowed_mobile_theme_ids`
- Audit logging:
  - preference updates write `SystemAuditLog` (`preferences.theme_updated`)

## Accessibility Direction

- Rails v1 keeps two choices for clarity:
  - `Standard`
  - `Dark`
- Mobile roadmap owns richer accessibility options:
  - high-contrast mode
  - elderly-friendly content-text magnification
  - guardrail: magnify content text only; avoid breaking buttons/nav/menu layout

## Open Verification (Pending)

- [ ] Final cross-surface verification using first real Expo dev-client build:
  - Confirm `GET/PATCH /api/v1/account/preferences` works from mobile auth flow.
  - Confirm preference round-trip consistency across:
    - mobile app
    - account portal
    - admin portal

