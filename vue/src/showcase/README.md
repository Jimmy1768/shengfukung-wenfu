# Showcase Pages

This folder contains the hidden Vue marketing/showcase pages used to promote the project template and demo the admin console flow.

## Purpose

- `MarketingLanding.vue` powers the hidden `/marketing` landing page.
- `DemoShowcase.vue` powers the hidden `/marketing/demo` template showcase.
- These pages are intentionally separate from the client site layout system in `vue/src/layouts/*`.

## Important Routing Notes

- Routes are defined in `vue/src/router/index.js`.
- Keep these paths available unless intentionally removing the showcase feature:
  - `/marketing`
  - `/marketing/demo`
  - `/demo` (redirect)
- Client site routes (`/`) and showcase routes must coexist.

## Do Not Accidentally Remove

- Do not delete these files during layout/template refactors for client sites.
- `vue/src/layouts/*` is for client websites.
- `vue/src/showcase/*` is for the hidden marketing/demo experience.

## Related Dependencies

- `vue/src/sourcegrid/*` (template showcase data/components)
- `rails` marketing admin demo console (`/marketing/admin`)
