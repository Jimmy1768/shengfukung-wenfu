# Vue landing page

This directory holds the marketing SPA that ships separately from Rails. It is a small
Vite + Vue 3 project so you can iterate on hero copy, layouts, or animations without
touching the Rails asset pipeline.

`src/App.vue` intentionally stays empty except for the shell imports. Each client copies
a finished showcase template (for example `sourcegrid/templates/BistroNoir.vue`) into
`App.vue` when they decide on their launch layout, so keep it blank inside the base
Golden Template repo.

## Getting started

- `npm install` (or `yarn install` / `pnpm install`)
- `npm run dev` (or the equivalent for your package manager) to iterate locally.

## Build & deploy

1. Run `npm run build` to produce `dist/`.
2. Copy the dist output to the nginx root defined in `ops/nginx/Golden-Template.comf` via `ops/scripts/deploy_vue.sh`.
3. Reload nginx (`systemctl reload nginx`) so the marketing host or prefix starts serving the new bundle.

When you copy this template for a client, adjust `ops/nginx/Golden-Template.comf` to point the `marketing` server block at `/var/www/<new-slug>-vue` (or a different target as needed) and ensure `ops/scripts/deploy_vue.sh` copies to that same directory.
