# TEMPLATE SYSTEM OVERVIEW

This note tracks the plan for supporting multiple Vue layouts + themes per temple while keeping builds lightweight. Layout/template selection is baked into each temple’s Vue build so we avoid shipping unused bundles at runtime. The rollout is organized into four phases so the work can be reviewed, tested, and adopted incrementally.

---

## Phase 1 – Foundation

### Purpose & Scope

- Provide a shared vocabulary for “layout”, “theme”, and “template” so engineering, design, and onboarding refer to the same primitives.
- Document the current-state guardrails: build-time selection only, per-temple bundles, and no runtime switching on the marketing site.
- Capture the minimum configuration surface needed today (`VITE_TEMPLE_*` env vars + YAML) so Phase 2+ can focus on mechanics instead of intent.

### Audience & Responsibilities

- **Frontend** – owns the layout registry (`src/layouts/<name>`), shared building blocks, and ensures the entry point reads the correct env vars at build time.
- **Ops/Onboarding** – maintains per-temple env/YAML defaults and runs `bin/deploy_vue <slug>` when a temple requests a new layout/theme combo.
- **Design/Marketing** – curates the palette and template catalog, supplies demo data (`demolotus`) for showcase builds, and reviews screenshots before handoff.

### High-Level Architecture

1. **Layout registry**
   - Move the current `src/components/pages` implementation into `src/layouts/classic` and add `src/layouts/<name>/App.vue` for future templates.
   - Layouts compose shared building blocks (`EventList`, `HeroSection`, `FooterLinks`) so data + copy stay consistent even as structure changes.

2. **Themes vs. Templates**
   - Theme palettes now cover **color only** (e.g., `temple-1` “Temple Red”, `temple-2` “Gold Lantern”). Marketing/demo palettes (`golden-*`) stay in the file but are hidden from the temple selector.
   - Layout tokens (spacing, radius, typography) move into a “template” registry so structure can evolve without touching colors. Templates (e.g., `classic`, `lantern`) compose the shared components and spacing scale.
   - Build outputs load both: `VITE_TEMPLE_THEME` chooses the palette; `VITE_TEMPLE_TEMPLATE` (future) sets spacing/radius/typography.

3. **Temple config**
   - Extend per-temple YAML/env to include `layout`, `theme`, and eventually `template`. Example `etc/default/shenfukung-wenfu.env`:
     ```
     VITE_TEMPLE_SLUG=shenfukung-wenfu
     VITE_TEMPLE_LAYOUT=classic
     VITE_TEMPLE_THEME=lotus
     ```
   - Build scripts (`bin/deploy_vue <slug>`) load these env vars so the compiled bundle knows which layout/theme to import.

4. **Dev/devtools**
   - `.env.development` can swap `VITE_TEMPLE_LAYOUT`/`VITE_TEMPLE_THEME` to preview different combos via `npm run dev`.
   - Dev theme toggle now filters to `temple-*` palettes so demo palettes aren’t exposed in real builds.
   - A showcase script (future) will build every layout using the demo temple data for marketing previews.

5. **Account/Admin surfaces**
   - Future work: expose layout/theme selection inside the account portal so owners can request a change. For now, edits happen directly in env/YAML followed by a redeploy.

### Phase 1 Checklist

- [ ] Refactor current pages into `src/layouts/classic` + shared components.
- [ ] Introduce `VITE_TEMPLE_LAYOUT`/`VITE_TEMPLE_THEME` support in the Vue entry point.
- [ ] Add per-temple layout/theme fields to YAML/env (seed defaults for existing temples).
- [ ] Document the onboarding flow: choose layout + theme, run `bin/deploy_vue <slug>`, capture screenshots.
- [ ] (Later) Build a showcase script + account portal UI for requesting layout/theme changes.
- [ ] Split template tokens from palette tokens so spacing/typography is reusable across themes.

---

Layout changes remain a build-time decision; every temple keeps its own dist bundle, so there’s no runtime slug switching on the marketing site. This keeps payloads small while allowing curated experiences per client.
