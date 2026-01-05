# Account Portal & Theme Guide

## Overview

The `/account` namespace powers the member-facing experience (profile, events, payment history). It now supports multiple visual themes so each temple can pick a look while sharing the same backend.

- Theme palettes live in `shared/design-system/themes.json`; run `node bin/sync_design_system.js` after editing to regenerate Vue/Rails/Expo tokens.
- The per-temple default theme key is stored in `shared/app_constants/project.json` (`defaultThemeKey`). Override it per environment via `PROJECT_DEFAULT_THEME_KEY`.
- A dev-only toggle writes the `temple_theme` cookie so designers can preview alternate templates across Rails `/account` and the Vue marketing site. Production hides the toggle; prod users see the configured theme only.
- Sections: Dashboard (quick links + upcoming cards), Profile (read/edit form), Events (upcoming grid + past timeline), Payments (LINE Pay history placeholder).

## Rails account layout

- `Account::BaseController` resolves the active theme by reading the cookie (dev only) or the project default. It injects `@active_theme_key` into `layouts/account`.
- The layout now renders a hero/header shell styled via `rails/app/stylesheets/account/account.scss` and the shared CSS variables.
- Dev toggle buttons post to `/dev/theme` (only available in development), which sets the cookie and reloads the page.

## Vue marketing site

- `src/app/theme.js` coordinates theme resolution. It reads the same cookie, applies the `data-theme` attribute to `<html>`, and, in dev, POSTs to `/dev/theme` so Rails sees the same override.
- `DevThemeToggle.vue` is injected only in dev builds; production builds ignore it.
- Marketing layouts can branch on the current theme via `document.documentElement.dataset.theme`.

## Workflow

1. Edit or add palettes in `shared/design-system/themes.json`.
2. Run `node bin/sync_design_system.js` to regenerate tokens + theme metadata.
3. Set the default theme for the temple via `shared/app_constants/project.json` (or `PROJECT_DEFAULT_THEME_KEY`).
4. In dev, use the toggle (Rails `/account` header or Vue widget) to preview another theme. The toggle is disabled automatically outside development.
5. Deploy as usual; both Vue and Rails `/account` now render with the chosen theme.
6. Replace the placeholder profile/events/payments data with real services when offerings + LINE Pay pipelines are ready.

## Notes

- The admin console + Expo app continue to share the Golden Template UI; theme switching currently targets the marketing and account surfaces only.
- Future backend work (offerings/events) should rely on the same theme helper so new pages inherit the correct chrome automatically.
