# TEMPLATE SYSTEM OVERVIEW

This note tracks the plan for supporting multiple Vue layouts + themes per temple while keeping builds lightweight. Layout/template selection is baked into each temple’s Vue build so we avoid shipping unused bundles at runtime.

---

## Goals

- Let each temple pick a layout (structure) and theme (color palette) during onboarding.
- Keep the existing per-slug build pipeline: each `bin/deploy_vue <slug>` run compiles a bundle with that temple’s layout + theme baked in.
- Provide showcase builds for every layout using demo data (e.g., `demolotus`) so owners can preview options.

## Architecture Plan

1. **Layout registry**
   - Move the current `src/components/pages` implementation into `src/layouts/classic`.
   - Add `src/layouts/<name>/App.vue` for future templates.
   - Layouts compose shared building blocks (`EventList`, `HeroSection`, `FooterLinks`) so data + copy stay consistent.

2. **Theme mapping**
   - Reuse the existing `src/theme` system. Every layout accepts a theme token set so palettes remain interchangeable.
   - Give each theme a manifest entry (e.g., `theme: "lotus"`, `theme: "forest"`).

3. **Temple config**
   - Extend the per-temple YAML/env to include `layout` + `theme`. Example `etc/default/shenfukung-wenfu.env`:
     ```
     VITE_TEMPLE_SLUG=shenfukung-wenfu
     VITE_TEMPLE_LAYOUT=classic
     VITE_TEMPLE_THEME=lotus
     ```
   - Build scripts (`bin/deploy_vue <slug>`) load these env vars so the compiled bundle knows which layout/theme to import.

4. **Dev/devtools**
   - `.env.development` can swap `VITE_TEMPLE_LAYOUT`/`VITE_TEMPLE_THEME` to preview different combos via `npm run dev`.
   - Add a showcase script (future) that builds every layout using the demo temple data for marketing previews.

5. **Account/Admin surfaces**
   - Future work: expose layout/theme selection inside the account portal so owners can request a change. For now, we edit the env/YAML and redeploy.

## Open Tasks

- [ ] Refactor current pages into `src/layouts/classic` + shared components.
- [ ] Introduce `VITE_TEMPLE_LAYOUT`/`VITE_TEMPLE_THEME` support in the Vue entry point.
- [ ] Add per-temple layout/theme fields to YAML/env (seed defaults for existing temples).
- [ ] Document the onboarding flow: choose layout + theme, run `bin/deploy_vue <slug>`, capture screenshots.
- [ ] (Later) Build a showcase script + account portal UI for requesting layout/theme changes.

---

Layout changes remain a build-time decision; every temple keeps its own dist bundle, so there’s no runtime slug switching on the marketing site. This keeps payloads small while allowing curated experiences per client.
