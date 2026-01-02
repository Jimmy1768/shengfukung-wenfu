# Template registry

Store future homepage templates here. Each layout should live in its own subfolder so the `/marketing/demo`
route can lazy-load it without touching the marketing landing page.

```
src/
 └─ sourcegrid/
      └─ templates/
          ├─ registry.js          # metadata + ids consumed by the template selector
          ├─ flashy-hero/
          │    └─ FlashyHero.vue  # default layout used today
          └─ circle-grid/
               └─ CircleGrid.vue  # 2x2 grid that collapses to 1x4 (the “four circle” design)
```

Guidelines:

1. Keep the same slot structure (hero, navigation, `content-area`, footer) so every marketing page
   works inside each template.
2. Import stock assets from `src/assets/media` to keep demo-friendly visuals.
3. Register new templates inside `registry.js` so `/marketing/demo` automatically exposes them in the selector.
