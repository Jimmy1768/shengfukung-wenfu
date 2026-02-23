# CROSS-SURFACE THEME POLICY UPGRADE PLAN

## Purpose

- Standardize how `layout` and `palette` are handled across `vue`, `rails`, and `mobile`.
- Preserve flexibility for the public Vue site while keeping Rails operational UIs stable and accessible.
- Align monorepo surfaces to one shared design-token and theme-policy model.

## Definitions

- `Layout` (template)
  - Structural presentation for the public Vue site.
  - Examples: page shell, hero composition, section arrangement.
- `Palette` (theme)
  - Color system/token set applied to a surface.
  - Examples: light, dark, high-contrast variants.

## Product Direction (Agreed)

- Vue (public site):
  - clients can choose `layout` + `palette`
- Rails (`account`, `admin`):
  - no layout choice exposed
  - palette/accessibility choice may be exposed
- Mobile (Expo):
  - consume the same palette ids/tokens as other surfaces
  - no client-facing layout choice concept

## Non-Goal Guardrail (Important)

- Cross-surface standardization in this plan is for `palette/theme` policy only.
- `layout/template` remains a Vue public-site concept only.
- Rails (`account`, `admin`) and `mobile` (Expo) must not implement layout/template switching or layout policy logic.
- Do not introduce shared `layout` ids/contracts for Rails/mobile as part of this plan.

## Why This Split Works

- Public site benefits from visual flexibility (branding + template selection).
- Admin/account portals prioritize usability, training consistency, and operational reliability.
- Older users benefit more from readability and contrast controls than layout customization.

## Theme Policy Model (Target)

### Shared Concepts

- `project default palette`
- `allowed palettes` per surface
- `user-selected palette` (optional override)
- `accessibility-oriented labels` for operational surfaces

### Suggested Priority Order (Runtime Resolution)

1. user preference (if authenticated and stored)
2. device/system preference (optional, where supported)
3. project default palette
4. hardcoded fallback palette

### Palette Scope Boundary (Important)

- `golden-*` palettes are demo/showcase palettes and are excluded from client production policy by default.
- Client production policy should use client-safe palette ids only (currently `temple-*`) unless a project explicitly opts into a `golden-*` palette.
- This keeps marketing/showcase experimentation separate from temple/client operations.

### Canonical Palette Inventory (Current)

- Client-safe palettes (default policy set):
  - `temple-1` (`Temple Red`)
  - `temple-2` (`Gold Lantern`)
- Demo/showcase palettes (excluded by default for clients):
  - `golden-default`
  - `golden-light`
  - `golden-dark`

### V1 Allowed Palette Matrix (Client Policy)

- `vue_public`
  - allowed: `temple-1`, `temple-2`
  - can expose palette selection to clients
- `rails_account`
  - allowed: `temple-1`, `temple-2`
  - expose as display/accessibility choices only
- `rails_admin`
  - allowed: `temple-1`, `temple-2`
  - expose as display/accessibility choices only
- `mobile` (Expo)
  - allowed: `temple-1`, `temple-2`
  - no layout concept; palette only

Notes:
- The allowed list can diverge later per surface, but v1 should start with the same client-safe set to avoid policy complexity.
- Human-facing labels may differ by surface (`Temple Red` vs `Standard`) while palette ids remain canonical and shared.

## Surface-Specific Policy

### Vue Public Site

- Support both:
  - `layout` selection
  - `palette` selection
- Continue using shared design tokens for visual consistency with Rails/mobile.
- Keep marketing/showcase routes and client-site routes separate.

### Rails Account/Admin

- Keep one stable layout per surface.
- Expose a small, curated palette selector focused on readability:
  - `Standard`
  - `High Contrast`
  - `Dark` (optional; only if tested for readability)
- Present these as accessibility/display options, not visual novelty themes.

### Mobile (Expo)

- Consume the same palette ids/tokens used by Vue/Rails.
- Support project default palette and (later) user preference sync.
- Keep platform-native handling for typography/spacing, but palette ids should map to the same design language.

## Data + Storage Strategy (Recommended)

### Phase 1 (Low-Risk)

- Vue:
  - keep current local persistence for palette/layout where applicable.
- Rails:
  - add palette preference via session/cookie per surface (`account`, `admin`).
- Mobile (Expo):
  - read project default palette from shared/app config and local mobile env.

### Phase 2 (Cross-Surface Consistency)

- Add backend-persisted user palette preference.
- Apply the same preference for:
  - account web
  - admin web (if same user has admin access)
  - mobile app (Expo)
- Keep project default palette as fallback for users without preferences.

## Technical Constraints / Guardrails

- Keep `layout` and `palette` independent in naming, code, and docs.
- Do not expose layout switching in Rails operational UIs.
- Avoid surface-specific forks of core design tokens.
- Palette ids must be stable across `vue`, `rails`, and `mobile`.
- Accessibility labels in Rails can map to branded internal palette ids.

## Implementation Phases

### Phase A: Policy + Inventory

- [ ] Inventory current palette sources and selectors across `vue`, `rails`, `mobile`.
- [x] Define demo-vs-client palette boundary (`golden-*` excluded from client policy by default).
- [x] Define canonical palette inventory buckets (client-safe vs demo/showcase).
- [x] Define v1 allowed palette matrix for `vue_public`, `rails_account`, `rails_admin`, and `mobile`.
- [ ] Define surface-specific label mapping (canonical ids -> user-facing labels per surface).

### Phase B: Rails Accessibility Palette Selector

- [ ] Add shared Rails palette policy helper/service (allowed ids, labels, fallback).
- [ ] Expose selector UI in `account` and `admin`.
- [ ] Persist preference (session/cookie first).
- [ ] Verify contrast/readability for older users in both portals.

### Phase C: Mobile (Expo) Alignment

- [ ] Confirm `/mobile` (Expo app) consumes canonical palette ids/tokens.
- [ ] Add fallback resolution order (user pref -> project default -> hardcoded fallback).
- [ ] Document mobile theme behavior in `ops/docs`.

### Phase D: Backend Preference Unification (Optional Next Step)

- [ ] Add persisted user palette preference in Rails data model/profile settings.
- [ ] Sync preference across account/admin/mobile for the same authenticated user.
- [ ] Add audit-safe updates for preference changes (if needed).

## Risks + Mitigations

- Risk: too many palette options confuse older users.
  - Mitigation: expose only 2-3 curated accessibility-focused choices in Rails.
- Risk: token drift between surfaces breaks visual consistency.
  - Mitigation: keep shared token source and palette ids canonical.
- Risk: palette behavior differs between unauthenticated vs authenticated flows.
  - Mitigation: define and document a clear resolution priority order.

## Acceptance Criteria

- Vue supports layout + palette without affecting Rails layout stability.
- Rails account/admin expose palette controls only (no layout switching).
- Mobile (Expo) uses the same palette ids/tokens as Vue/Rails.
- Theme policy is documented and understandable across all three surfaces.
