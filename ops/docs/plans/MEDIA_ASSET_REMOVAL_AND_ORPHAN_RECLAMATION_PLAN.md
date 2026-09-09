# Media Asset Removal And Orphan Reclamation Plan

Status: **Phase 0 complete 2026-09-05. Phase 1 implemented 2026-09-02**
(Director authorized, chose to keep the MediaAsset row). **Phase 2's premise
changed 2026-09-08** -- S3 objects are now reclaimed when their MediaAsset row
is destroyed, so the sweep covers historical orphans rather than an ongoing
leak; see the scope note on Phase 2. Phase 2 remains unauthorized.

Two separable pieces of work with different risk profiles; Phase 1 is additive
and reversible, Phase 2 can permanently destroy customer files and is
deliberately gated behind a dry run.

Owner: Wenfu Planning / Director

Created: 2026-09-02

## Purpose

Two problems found while the Director was checking the eight hero image slots.
He asked for one thing — a way to remove an image — and the investigation found
that the storage layer has never deleted anything.

His own framing, close to verbatim: temple profile heroes are a few files, so
unlinking makes sense; gallery albums are expensive, so those should actually
delete. And then the question this plan exists to answer — *if unlinked, do we
need a runner to remove orphaned files?*

The answer is that the runner is needed regardless, because orphans already
accumulate today from a completely different path.

## Confirmed current state

Verified in this session, not assumed.

### An uploaded hero image cannot be removed

Each hero tab has **two** storage paths, and the admin exposes only one:

- `temple.hero_images[tab]` — the "paste URL" box, inside a collapsed
  `<details>`
- a `MediaAsset` row with `role: hero_image` and `metadata["hero_tab"]`

`MediaAssets::HeroImageUploader#call` writes **both** (`update_temple_hero_map`
plus `upsert_media_asset`). `Temple#hero_image_for` reads the map first, then
the media asset, then falls back to the home image.

So clearing the URL box leaves the media asset in front of the fallback:

```text
after upload:    events -> https://cdn.real/UPLOADED-EVENTS.jpg
after clearing:  events -> https://cdn.real/UPLOADED-EVENTS.jpg
```

There is no Remove control anywhere in `_hero_image_slot.html.erb`. An image
can be replaced, never removed — and the one apparent workaround silently does
nothing, which is how this presents to the Director.

### Nothing in this application has ever deleted an S3 object

| Thing | State |
| --- | --- |
| `Storage::S3Service.delete` | exists, **zero call sites** |
| `Admin::GalleryEntriesController#destroy` | destroys the row, invalidates cache, never touches S3 |
| `Admin::MediaUploadsController` | has `create`, no `destroy` |
| `Maintenance::CleanupWorker` | stub, raises `NotImplementedError` |

Every gallery photo ever deleted is still in the bucket and still billed. This
predates anything in this plan.

### Orphans are computable, which is what makes a sweep safe

There are exactly two upload paths and both persist a `MediaAsset` carrying the
S3 key:

- `MediaAssets::ManagedUploader#create_asset!` — `file_uid: storage_key`
- `MediaAssets::HeroImageUploader#upsert_media_asset` — `asset.file_uid = storage_key`

`Storage::S3Service.upload` returns the **already-namespaced** key, so
`file_uid` matches what a bucket listing returns with no URL parsing. And
`namespaced_key` is idempotent (returns `raw` when the prefix is already
present), so `delete(key: file_uid)` is correct on a stored value without
double-prefixing.

Orphans are therefore a set difference: objects under the prefix, minus
`MediaAsset.pluck(:file_uid)`.

## Phase 1 — Remove control for temple hero images

Additive, reversible, no deletion. Safe to authorize on its own.

**Behaviour.** A Remove control on each hero slot clears both storage paths for
that tab: the `hero_images` entry and the tab's `MediaAsset` link. The tab then
inherits the 首頁 image, which is what the admin already promises. Lands on the
shared `_hero_image_slot.html.erb`, so it covers all seven page tabs plus
活動預設圖片 at once.

**Unlink, not delete.** Per the Director: few files, and a mis-click stays
recoverable. The S3 object survives and becomes an orphan for Phase 2 to
reclaim.

**Answered by the Director:** keep the `MediaAsset` row and clear only its
`hero_tab` association, so the record of what was uploaded and when survives.

**Delivered.** `MediaAssets::HeroImageRemover` clears both paths;
`Admin::TemplesController#remove_hero_images` runs it during the profile save,
before uploads, so a same-save replace ends with the new image. Control lives on
the shared slot partial, so it covers all seven page tabs plus 活動預設圖片.

Two bugs surfaced while building it. Both are fixed; neither was in the
original scope.

- **The fallback chain had no floor.** `hero_image_for` ended at
  `hero_images["home"]`, so a temple with no home image resolved to nil. The
  placeholder existed only as a seed constant. `Temple::DEFAULT_HERO_IMAGE` now
  owns it and terminates the chain, the seed resolves it lazily (it is required
  by rake before autoloading), and 首頁 is removable like any other tab --
  which is what the Director pointed out, having already seen a re-seed purge
  home and everything fall to the placeholder correctly.
- **The profile form replaced the whole `hero_images` map.** Submitting a
  partial hash silently wiped the omitted tabs. Never bit only because the
  rendered form posts a field for every tab. `normalized_hero_images` now
  merges into the temple's current map; a submitted blank still clears its own
  key, so the paste-URL box keeps working, and omission means "leave alone".

**Acceptance:**

- Removing a tab's image makes `hero_image_for(tab)` return the home image ✓
- Removing 首頁 falls through to `Temple::DEFAULT_HERO_IMAGE`, not to nil ✓
  (the constant was moved to the model to make this true)
- No tab ever resolves to nil, even with nothing set at all ✓
- A partial form submission leaves omitted tabs alone ✓
- A tab with no image is unaffected by Remove (idempotent) ✓
- The S3 object still exists afterwards ✓
- Covered for both storage paths, since clearing only one was the bug ✓
- Replace-in-one-save keeps the new image ✓

## Phase 0 — Give production its own S3 prefix

Prerequisite for Phase 2. Small now, and it only gets more expensive.

**Why.** The Director first settled on dev/staging/none, then asked whether
prefixing production was better. It is, for one reason: with no prefix,
production's namespace *is* the bucket root, so its sweep would see `dev/` and
`staging/` objects as orphans. The mitigation would be an explicit
sibling-prefix exclusion list that must be updated every time an environment is
added — forgetting means deleting that environment's files. Prefixing
production deletes that hazard outright instead of managing it forever.

It cannot be avoided by scoping to one key root: `HeroImageUploader` writes
`uploads/hero-images/…` while `ManagedUploader` writes `gatherings/hero/…`,
`gallery/images/…` and `gallery/videos/…`. Narrowing to `uploads/` would skip
exactly the gallery albums this work targets.

**Measured 2026-09-02, production:**

```text
bucket templemate-media-assets:  9 objects, 2.1 MB, all under uploads/
media_assets rows:               16  (8 real uploads, 8 placehold.co seed rows)
dev/ objects:                    none
```

**Correcting an earlier claim in this document:** "every gallery photo ever
deleted is still in the bucket and still billed" implied a real cost. At 2.1 MB
it is noise, and there are effectively no orphans to reclaim today. Phase 2's
value is preventing a future mess, not recovering storage — which lowers its
urgency considerably.

**Final scheme:** development → `dev`, staging → `staging`, production → `prod`.

### Steps

1. **Dry run.** Report every object that would be copied, every
   `MediaAsset.file_uid` that would be rewritten, and every stored URL that
   embeds the old path. Writes nothing. This runs first and the Director reads
   it.
2. Server-side copy `uploads/…` → `prod/uploads/…`.
3. Rewrite the 8 `MediaAsset.file_uid` values.
4. Rewrite stored URLs: `temple.hero_images` entries, and any
   `hero_image_url` / `poster_image_url` columns on events, services and
   gatherings that embed the old path.
4b. **Grant public read on the new prefix in the bucket policy.** Not
   optional and not in code — `copy_object` does not carry access with it.
   Verify with an anonymous `curl` before declaring step 4 done.
5. Set `S3_OBJECT_PREFIX=prod` in `/etc/default/shengfukung-wenfu-env`, and
   `staging` in both staging units (already prepared in `ops/systemd/`).
   Restart. Requires sudo.
6. Verify the site renders every hero and gallery image, then delete the old
   root-level copies.

Steps 2–4 write to the production database and bucket. Step 5 needs sudo.
Nothing runs without the Director reading step 1's output first.

### Ordering hazard

Step 5 must come **after** 2–4, and step 6 after 5. Setting the prefix before
the objects and URLs move would break every existing image, because the app
would start resolving `prod/uploads/…` for files still at `uploads/…`.

### Applied 2026-09-03 — steps 1–4 done and verified

```text
copied 9 objects (originals left in place)
rewrote 8 file_uids
rewrote 8 stored URLs
```

A re-run of the dry run afterwards reported `0` and `0`, confirming both
rewrites landed and that the task is idempotent. `objects to copy` still
reports 9 because the originals are deliberately still in place for step 6.

**The plan missed a required step, and the site broke until it was found.**
Every hero returned `403 AccessDenied` at the new prefix. `copy_object` copies
bytes, not access: public read comes from a **bucket policy**, which lives in
AWS and is recorded nowhere in this repo, and it was scoped to the old prefix.
The dry run could not have caught this — it lists objects and rows, and never
fetches anything.

**Also found, pre-existing and unrelated to this migration:** both policy
statements were scoped to `<prefix>/uploads/*`, but only `HeroImageUploader`
writes there. `ManagedUploader` writes `gatherings/hero/…`, `gallery/images/…`
and `gallery/videos/…`, so **the first gallery or gathering upload would have
returned 403**. It had never fired because the bucket held only hero images.
Scoping by environment prefix instead of by key root fixes both at once.

The policy granted `s3:GetObject` on `dev/*`, `staging/*`, `prod/*` and
`uploads/*`. That last statement was legacy, kept only until step 6; it was
removed 2026-09-05 and the policy is now the three environment prefixes.

**Add to step 6, and to any future environment's setup:** verify the bucket
policy covers the new prefix *before* moving anything into it.

### Applied 2026-09-05 — steps 5–6 done, Phase 0 complete

- **Step 5.** `S3_OBJECT_PREFIX=prod` set in
  `/etc/default/shengfukung-wenfu-env`; Puma and Sidekiq restarted; site
  verified rendering. The step's staging half — `S3_OBJECT_PREFIX=staging` in
  both staging units — is prepared in `ops/systemd/` but moot on the droplet
  now that staging is disabled; it applies again only if staging is brought
  back.
- **Step 6.** The root-level `uploads/` objects deleted by the Director, and
  the `PublicReadLegacyUnprefixedUploads` statement removed from the bucket
  policy. Live images and the site verified 200 afterwards.

**The staging precondition dissolved rather than being met.** Step 6 was
written to wait until staging wrote prefixed, because until then staging still
wrote to `uploads/`. Staging was disabled 2026-09-05
(`shengfukung-wenfu-staging-puma` / `-sidekiq`, `disable --now`), so it writes
nothing at all and the reason for waiting no longer existed. A precondition can
stop applying without ever being satisfied; the Director spotted that the
recorded gate had gone inert while it was being quoted back at him.

**What actually needed checking was different, and it was not in the plan:**
whether any live row still pointed at a bare `uploads/` key. None did. The
check that matters before an irreversible delete is *what still references the
thing*, not the status of the process that used to write it.

**A near-miss worth recording.** The live objects sit at `prod/uploads/…` —
the migration prepended `prod/` to keys that already began with `uploads/`. So
the bucket held both `uploads/…` (legacy, 9 objects) and `prod/uploads/…`
(live, 16 references). These are distinct S3 prefixes and deleting one does not
touch the other, but they are one folder name apart in the console. A first
reference scan that matched the substring `uploads/` reported all 16 live rows
as still-referenced, which was the scan being wrong, not the data.

## Hardening — one render path, one meaning for file_uid

Applied 2026-09-03, after a four-angle review of the Phase 0/1 changes found
that most of what it flagged traced to two structural faults rather than to
the individual patches.

### The two faults

**A hero image had two persisted representations and both fed the read path.**
`temple.hero_images[tab]` and a `MediaAsset` keyed by `metadata["hero_tab"]`.
Nothing kept them consistent except code that remembered to touch both, so
every consumer had to remember, and the ones that forgot were the bugs. It is
why an uploaded hero could be replaced but never removed: the admin cleared
one and the other kept winning.

**`file_uid` did not mean one thing.** A storage key for real uploads, a full
URL for seeded rows. That ambiguity is what broke the Phase 0 migration, which
would have rewritten those rows to `prod/https://placehold.co/...`.

### What changed

- **One render path.** `Temple#hero_image_for` is now
  `hero_images[tab] || hero_images["home"] || DEFAULT_HERO_IMAGE`. A
  `MediaAsset` is the upload record and is never consulted when rendering —
  the shape `TempleGathering` already used, where `hero_image_url` is the only
  thing read and `metadata["hero_asset_id"]` is provenance. This deleted
  `sanitized_hero_source` and `placeholder_hero?`, collapsed
  `hero_image_set?` to one check, and took the admin edit page from up to 16
  single-row `media_assets` queries to none. `GET /api/v1/temple` likewise.
- **`file_uid` is validated as a storage key.** A URL is rejected. The class
  of bug that broke Phase 0 can no longer be created.
- **Absent means absent.** The seed persists only what the yml supplies. It
  used to inflate `{}` into all eight tabs filled with the placeholder, then
  manufacture eight `MediaAsset` rows whose `file_uid` was that URL. Those
  rows are now purged on seed; they reference no S3 object, so nothing is
  orphaned by dropping them. The floor is applied at render time and never
  stored.
- **The placeholder is no longer recognised by pattern.** The `placehold.co`
  regex existed in Ruby and in JS and would have been silently defeated by any
  future default image on another domain. With "no image" stored as absent
  there is nothing to detect. `DEFAULT_HERO_IMAGE` now comes from
  `shared/app_constants/temple_profile_placeholders.json`, which both stacks
  already read.
- **The chain is resolved once, on the server.** `siteContent.js` re-ran
  tab → home → filter on top of an already-resolved payload; it now reads what
  the serializer sent.

### Still open

- **A single registry of stored-media references.** The model→column list the
  prefix migration hardcoded is the same list Phase 2's sweep needs. Until it
  exists in one place, a new column holding an image escapes both — and for
  the sweep that means being classified as an orphan and deleted.
- **One detached-asset policy.** Temple heroes unlink and keep (Director's
  call); `Admin::GatheringsController#cleanup_detached_assets` destroys. Two
  answers to the same question, decided per feature.
- **Removal runs outside the form transaction.** `HeroImageRemover` commits
  and audits before `@form.save` can fail, so a validation error elsewhere
  leaves the image gone, audited, and the re-rendered page showing the old URL.

## Phase 2 — Orphan reclamation sweep

Can permanently destroy customer files. Not to be authorized in the same breath
as Phase 1.

### Scope narrowed 2026-09-08, and the claim corrected 2026-09-09

The heading below originally read "new orphans are no longer being created". It
was premature. `d3f06a6` gave `MediaAsset` the hook, but until `572e599` an
uploaded gallery photo was never linked to its asset, so deleting one reclaimed
nothing -- the reclamation was inert on the only path a temple admin uses. No
real photos were uploaded in that window, so nothing was actually leaked, but
the statement was wrong for two days and a reader would have trusted it.

### New orphans are no longer being created

This phase was written when **nothing in this application had ever deleted an
S3 object**, so every removed image leaked and a sweep was the only way to get
any of them back. `d3f06a6` changed that: `MediaAsset#after_destroy_commit`
reclaims the object when the row goes, guarded against URL-valued `file_uid`s
and against objects a sibling row still references.

So the sweep now addresses **history, not an ongoing leak**. Two consequences:

- Its urgency dropped. Every gallery photo deleted from here on reclaims itself,
  and destroying an album reclaims its photos' objects too.
- Its target set is knowable and finite: objects orphaned before 2026-09-08,
  plus anything a future code path drops without going through `MediaAsset`.

Step 2a's report is still the right first move and is still unauthorized. What
changed is that the report should now be read as an inventory of past damage
rather than a running total, and 2b's deletion set should be small.

Hero images and gathering heroes still destroy `MediaAsset` rows through their
own paths, so they inherit the reclamation automatically. That was not designed
here -- it falls out of putting the hook on the row that owns the object.

**Step 2a, report only.** `Maintenance::CleanupWorker` (already stubbed for
exactly this, already fanned out to by `NightlyCleanupJob`) lists objects under
the configured prefix, subtracts referenced `file_uid`s, and reports what it
*would* delete — count, total bytes, and a sample of keys. Deletes nothing.
Runs on demand, not on a schedule.

**Step 2b, deletion.** Only after the Director has read a real report from
production and agrees the set looks right.

**Safety constraints, all mandatory:**

- **Environment isolation in the bucket.** OBSOLETE AS WRITTEN. This section
  still describes the first scheme (production → no prefix) and the sibling-
  exclusion list that scheme required. Phase 0, applied 2026-09-03, gave
  production its own `prod/` prefix precisely to delete that hazard, so the
  exclusion-list mandate below no longer applies. The current scheme is
  development → `dev`, staging → `staging`, production → `prod`; read the
  Phase 0 section above, not the paragraphs that follow here.

- **Superseded text, kept only to show what changed.** Settled by the Director
  2026-09-02: development → `dev`, staging → `staging`, production → none.

  All three share one bucket, `templemate-media-assets`. Staging previously had
  **no** prefix, because it inherits production's env file and the unit
  overrode only `RAILS_ENV`, `PUMA_PORT` and `PGDATABASE` — so staging uploads
  landed beside production's while the databases stayed separate, and a sweep
  in either would have seen the other's files as orphans.
  `S3_OBJECT_PREFIX=staging` is now in both staging units.

- **Production's namespace IS the bucket root, and that cannot be scoped away.**
  Because production has no prefix, its sweep lists everything, including
  `dev/…` and `staging/…` — which have no rows in production's database and
  would therefore be classified as orphans.

  It cannot be narrowed to a single key root either: `HeroImageUploader` writes
  `uploads/hero-images/…`, but `ManagedUploader` writes `gatherings/hero/…`,
  `gallery/images/…` and `gallery/videos/…`. Scoping to `uploads/` would miss
  exactly the gallery albums this work exists to reclaim.

  **So the production sweep must carry an explicit exclusion list of sibling
  prefixes (`dev/`, `staging/`), and refuse to run if that list is empty.** This
  is a standing maintenance hazard: adding a fourth environment means updating
  the list, and forgetting to means deleting its files. Giving production its
  own prefix would remove the hazard entirely, at the cost of migrating existing
  objects — the Director chose none, so the exclusion list is the mitigation.
- **Age threshold.** Never consider an object newer than some window (24h+), so
  an upload that is mid-flight or whose row is not yet committed cannot be
  collected.
- **Dry run is the default**; deletion requires an explicit flag.
- **Audit every deletion**, with the key and the reason.

**Gallery deletion stays async.** Deleting from S3 inline during
`GalleryEntriesController#destroy` is tempting but wrong ordering: a failed
request mid-destroy leaves a live row pointing at a dead object, which is worse
than an orphan. Destroy the row, let the sweep reclaim.

## Explicitly out of scope

- Deleting or changing anything in the bucket before a report has been read
- Per-event `hero_image_url` (`admin/events/_form.html.erb` renders a bare text
  field). Likely has the same removal gap, but it is a plain column with no
  MediaAsset path, so it is a different fix. Check before assuming.
- Any change to `Storage::S3Service` itself; it already exposes what is needed.

## Next Step

Phase 0 is complete: production reads and writes `prod/`, the legacy
unprefixed objects and their bucket-policy statement are gone.

Phase 1 is done and deployed pending the usual staging/production walk.

Phase 2 remains unauthorized. When it is taken up, start at **2a (report
only)** and do not enable deletion until the Director has read a real
production report. The prefix hazard above is the thing to verify first.
