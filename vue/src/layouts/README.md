# Layout Registry

Each layout (template) lives in its own folder under this directory. A layout is responsible for rendering the shell (`App.vue`), registering its route tree, and importing any unique page components it needs. The registry (`index.js`) picks the active layout at build time via `VITE_TEMPLE_LAYOUT`, so every compile ships exactly one layout.

## Authoring a Layout

```
layouts/
  classic/
    App.vue          # shared shell (header/footer/loading state/dev tools)
    pages/           # layout-specific pages (Home.vue, Events.vue, ...)
    routes.js        # exports createClassicRoute()
  lantern/
    App.vue
    pages/
    routes.js
```

Guidelines:

1. **Route factory** – Each layout exports `create<Layout>Route()` from `routes.js`. Return a Vue Router record with `path: '/'`, the layout `App.vue` as `component`, and child routes for every page. See `classic/routes.js` for the pattern.

2. **Shell contract** – `App.vue` must:
   - Render header/footer wrappers (usually shared components) so navigation stays consistent.
   - Handle loading/error states from `useTempleContent()` before showing `<router-view />`.
   - Remain theme-agnostic; never hardcode palette colors. Use CSS variables from `tokens.css`.
   - Gate dev-only helpers (`DevThemeToggle`, debug panels) behind `import.meta.env.DEV`.

3. **Page components** – Layouts can reorganize or rewrite pages entirely, but they must consume the shared composables (`useTempleContent`, `useTempleEvents`, etc.) so API data flows identically. Avoid duplicating API fetch logic; keep it in `src/app/siteContent.js` and helpers.

4. **Theme compatibility** – Themes only change palette tokens. Layout CSS should rely on variables (`var(--surface)`, `var(--spacing-lg)`, etc.) so any palette (Temple Red, Gold Lantern, future sets) renders correctly without overrides.

5. **Shared blocks** – When creating new structural pieces, consider placing them under `src/components/site/` so other layouts can reuse them. Layout-only components can live inside the layout folder if they’re not meant to be shared.

6. **Adding a layout** – After creating the folder, update `layouts/index.js` to import your route factory and map the new layout id. Set `VITE_TEMPLE_LAYOUT=<layout-id>` in `.env`/`.env.development` (or `/etc/default/<slug>-env` on server) to compile it.

Following this structure ensures new templates stay consistent, never miss data from the API store, and remain palette-agnostic.
