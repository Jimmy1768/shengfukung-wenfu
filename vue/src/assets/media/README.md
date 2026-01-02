# Media staging area

Drop placeholder photography, textures, and hero videos here so `/marketing/demo` and future templates can
import them without pulling from production buckets.

Suggested structure:

```
src/assets/media/
 ├─ heroes/       # MP4 / WebM loops or hero JPGs
 ├─ logos/        # partner logos or watermark variants
 └─ gallery/      # stock lifestyle shots used across templates
```

Name files after the template that consumes them (for example,
`heroes/flashy-hero-loop.webm` or `gallery/circle-grid-01.jpg`) so designers know which assets are
safe to replace when cloning Golden Template into a client project.

## Brand media catalog

Each client demo can keep its assets inside a dedicated folder. Document the contents here so
designers know what to swap when cloning Golden Template.

### Boutique Hotel (`src/assets/media/hotel`)

| File | Dimensions | Ratio | Suggested usage |
| --- | --- | --- | --- |
| `hotel_suite_golden.png` | 1456×816 | 16:9 | Hero or carousel slide showing premium rooms |
| `hotel_courtyard_evening.png` | 1456×816 | 16:9 | Secondary hero background (Parallax, Magazine) |
| `hotel_gradient_sand.png` | 1456×816 | 16:9 | Soft gradient overlay/background texture |
| `hotel_pool_twilight.png` | 1456×816 | 16:9 | Gallery card or CTA backdrop |
| `hotel_balcony_sunrise.png` | 1456×816 | 16:9 | Storytelling split image |
| `hotel_lobby_natural.png` | 1344×896 | 3:2 | Magazine carousel secondary card |
| `hotel_spa_terrace.png` | 1344×896 | 3:2 | Feature block for amenities |
| `hotel_breakfast_tray.png` | 1232×928 | 4:3 | Lifestyle detail tile |
| `hotel_texture_linen.png` | 1232×928 | 4:3 | Background accent (behind text) |
| `hotel_exterior_corner.png` | 928×1232 | 3:4 vertical | Sticky nav thumbnail or mobile hero |
| `hotel_towels_spa.png` | 928×1232 | 3:4 vertical | Spa-focused CTA card |
| `hotel_detail_ceramic.png` | 1024×1024 | 1:1 | Circle grid tile or icon background |
| `hotel_texture_plaster.png` | 1024×1024 | 1:1 | Texture overlay |
| `hotel_texture_pool.png` | 1024×1024 | 1:1 | Background for stat cards |
