# Admin Portal Build Plan

Progress tracking: fill in each `Completed:` line once the section is implemented and tested.

## Phase 1 – Content & Data Foundations

- Extend the Temple profile schema + `/admin/temple/profile` so admins can manage hero copy, shared imagery (single hero or per-tab), and any marketing copy surfaced on the Vue site.
- Introduce `TempleNewsPost` and `TempleGalleryEntry` (or equivalent) scoped by temple slug to store news updates, event recaps, and gallery assets.
- Ensure offerings endpoints clearly separate future vs. past events and expose the necessary metadata for Vue/Expo.
- Add Active Storage + S3 plumbing for hero images, archive galleries, and news thumbnails (placeholders acceptable until uploads are ready).

Completed:

## Phase 2 – Admin UX Enhancements

- Polish `/admin/temple/profile` to label hero image slots per tab, preview uploads, and keep copy + metadata editing intuitive.
- Build `/admin/news` CRUD for `TempleNewsPost`, including publish toggles and optional “push to Expo” flags.
- Build `/admin/galleries` (or similar) that lists past offerings and lets admins upload recap photos + text per event.
- Lock down permissions so only authorized owner/staff accounts can access the new sections.

Completed:

## Phase 3 – Public API Surface

- Expose `/api/v1/temples/:slug/profile` returning hero copy, imagery, and marketing text for Vue and Expo.
- Add `/api/v1/temples/:slug/news` (latest 10 posts) and `/api/v1/temples/:slug/archives` (past offerings with recap assets).
- Ensure offerings endpoints already used by the events page include all required fields (status, schedule, CTA URLs).
- Add request specs covering all new endpoints and enforce slug scoping.

Completed:

## Phase 4 – Vue Frontend Integration

- Update the Vue app to read `VITE_TEMPLE_SLUG`, fetch the profile/news/archive endpoints on boot, and hydrate a shared store.
- Build dynamic hero + tab components that reuse the fetched imagery/copy rather than hardcoded placeholders.
- Wire the Events page to the offerings endpoint, Archives page to the archive API, and News page to the news API (with loading/error states).
- Ensure routing + SEO tags use per-temple data and that all assets gracefully fallback if optional fields are missing.
- Keep cache payload generation on the Rails side for admin/account flows where larger datasets need preprocessing; Vue’s footprint is small enough to call APIs directly for now.

Completed:

## Phase 5 – Deployment & Onboarding

- Document the per-temple `.env` (Rails + Vue + Expo) requirements and update `bin/deploy_vue <slug>` to read them automatically.
- Update nginx templates so every new domain/slugs shares the same Rails upstream while serving the correct Vue dist.
- Capture a runbook for seeding temples, syncing offering YAML, uploading baseline imagery, and verifying each surface.
- Add smoke tests (system + frontend) to confirm the full stack works for a given slug before flipping DNS.

Completed:

## Mobile Alignment Notes

- Keep the slug-driven framework authoritative; Expo should reuse the same APIs and cache payloads as Vue so no new endpoints or business logic drift.
- Treat Expo as a convenience client (push notifications, quick updates) while leaving heavy admin tasks (accounting, large tables) to the web portals.
- When designing payloads for Vue, ensure the cache serialization can also satisfy Expo so future mobile work is purely UI.
- Expo endpoints should mirror Rails cache payloads 1:1, omitting only the datasets intentionally excluded from mobile to keep screens lightweight.

Completed:
