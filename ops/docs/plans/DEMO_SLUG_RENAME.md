# shengfukung-wenfu → shengfukung-demo

Wenfu Planning, 2026-09-14. **Measured, not planned.** Two decisions are still
open and the work cannot be sequenced without them.

## Why

The Director, 2026-09-14: *"shengfukung-demo is the demo slug now, we need to
change it in the entire repo. reserve shengfukung-wenfu for the real temple when
it onboards."*

This repository's demo temple has been occupying the name the real client will
want. Renaming it now is cheap; renaming it after the real temple onboards means
doing it while two things answer to one name.

## Decided

**The demo keeps `shengfukung.com.tw`.** The real temple gets
`shengfukung.org.tw` when it onboards. Director, 2026-09-14, confirming the
spelling is `shengfukung` (聖福宮) and not `shengfuking`, which appeared twice as
a typo. On a domain that difference is not cosmetic, which is why it is recorded
here.

## Blast radius, Observed 2026-09-14

76 tracked files. 313 occurrences of `shengfukung-wenfu`, 6 of
`shengfukung_wenfu`, 5 of `shengfukungwenfu`. Three tiers, and only the first is
mechanical.

**1. Repo-only.** Tests, fixtures, documents, the manifest label. Safe to
rewrite in bulk.

**2. Runtime-coupled — the trap.** `shared/app_constants/project.json`'s `slug`
is read at boot and drives real paths:

    AppConstants::Project.systemd_env_file  →  /etc/default/shengfukung-wenfu-env
    AppConstants::Project.marketing_root    →  /var/www/shengfukung-wenfu
    Profile::Infrastructure                 →  its own derived names

Change the slug alone and Rails looks for an env file and a web root that do not
exist. The four systemd unit names, the two nginx configs and both checkout
directory names are all spelled from it too.

**3. Live data.** Production's temple row carries `slug: shengfukung-wenfu`.
Renaming the constant without migrating the row breaks temple resolution.

**Not affected**, and this is why the job got cheaper on 2026-09-14: database
names now derive from `databaseName: templemate`, not from the slug. `scheme`,
`bundlePrefix` and `easProjectId` are separate keys and are untouched.

## Decided — Director, 2026-09-25

**Everything named `shengfukung-wenfu` in this repository becomes
`shengfukung-demo`**, and the droplet follows it: the process names, the env
file, the Vue folder and nginx config, the two checkout folders, and the demo
temple's database record. `shengfukung-wenfu` is left unused.

**The database record is renamed in place.** The demo temple's registrations
are attached by `temple_id`, not by slug, so one UPDATE keeps them all. Observed
on production 2026-09-25: two temples, `shengfukung-wenfu` (示範宮廟, 3
registrations) and `demo-lotus` (蓮城慈航宮, 1).

**Not included:** the repository's own name on GitHub and the local folder
`~/Projects/shengfukung-wenfu`. Renaming those moves every session's working
directory, the registry entry and the memory path. That is the repository's
identity, not the demo temple's, and is a separate decision.

## Established before planning — Observed 2026-09-25

**Nothing else stores the temple's slug as text.** The other `slug` columns —
on `temple_events`, `temple_gatherings`, `temple_offering_setup_drafts`,
`temple_pages` and `temple_services` — hold those records' own slugs, scoped by
`temple_id`.

**Two files are named after it and are read by slug at runtime:**
`rails/db/temples/shengfukung-wenfu.yml` and
`rails/db/temples/offerings/shengfukung-wenfu.yml`. `period_key_rollover.rb`
opens `"#{temple.slug}.yml"`. Both must be renamed with the slug.

**The platform-path helpers are dead.** `AppConstants::Project.systemd_env_file`
and `.marketing_root` derive paths from the slug and have no caller. The units
and nginx configs name their paths explicitly. So changing `project.json`'s slug
does not by itself move any path the running system reads.

**The public site finds its temple through `project.json`'s slug.**
`TempleContextResolver` falls back to `AppConstants::Project.slug`. That slug and
the database record's slug must therefore change together, or the public site
cannot find its temple.

**Media is not at risk, but a trap sits next to it.** `config/storage.yml`
names its bucket via `Profile::Infrastructure::Storage.s3_bucket`, which reads
`S3_BUCKET_PRODUCTION` and otherwise derives a bucket from the slug. Production
sets `S3_BUCKET`, not `S3_BUCKET_PRODUCTION`, so ActiveStorage would today use a
bucket called `shengfukung-wenfu`. It does not matter: the `active_storage_blobs`
table does not exist on production, so ActiveStorage is not in use. All real
media goes through the separate S3 service on `S3_BUCKET=templemate-media-assets`.
Stored media URLs contain `/shengfukung-wenfu/` in their paths and keep working,
because the objects do not move; new uploads land under the new slug. If
ActiveStorage is ever enabled, its bucket name must be set explicitly.

## Steps

Three phases, split so that the part that changes behaviour and the part that
changes names are never in the same window.

### Phase A — the temple's identity. Code and data, no infrastructure names.

Ordinary Control work, merged to `main`.

- `shared/app_constants/project.json`: `slug` → `shengfukung-demo`.
  `marketingRoot` **unchanged** in this phase.
- `rails/app/lib/temples/manifest.yml`: the temple's `slug` and `label` →
  demo. `domains` stays `shengfukung.com.tw`. `vue_dir` **unchanged** in this
  phase.
- Rename `rails/db/temples/shengfukung-wenfu.yml` and
  `rails/db/temples/offerings/shengfukung-wenfu.yml`.
- **A data migration** that renames the temple record in place. Running it as a
  migration puts code and data in one commit and runs it everywhere the code
  goes — local, staging, production.
- Every test, fixture and seed that names the slug.
- `.claude/launch.json`'s dev-client `TEMPLEMATE_LOCAL_TENANT_SLUG`.

Infrastructure names — units, env file, nginx, `/var/www`, checkout folders —
stay as they are. This phase changes what the temple is called, not where
anything lives.

**Then prove it on staging.** Staging tracks `main` and has its own copy of the
demo temple record. Reset it, run the migration, restart, and confirm the API
serves the temple under its new slug.

**Phase A — done, 2026-09-25** (assignment 034, merged). The migration is
`20260925000000_rename_demo_temple_slug.rb`. It renames in place, keeps
`temple_id`, refuses to rename onto a slug that already exists, does nothing
when the old slug is absent, and reverses.

**Rehearsed on a real database before merging.** `templemate_dev` was in the
same state as production — migrations up to `20260907000000`, the rename not
recorded, temples `shengfukung-wenfu` and `demo-lotus`. `db:migrate` printed
"renamed 1 temple from shengfukung-wenfu to shengfukung-demo"; the record kept
id 1 and both its registrations.

**The finding that governs Phase B: the rename runs only under `db:migrate`,
never after a schema load.** `db:schema:load` marks every migration up to
`schema.rb`'s version as already applied — now including this one — so a
database built from schema records the rename as done without doing it. That is
harmless on a fresh database, which has no old slug. On staging or production it
would leave the record at `shengfukung-wenfu` while `project.json` says
`shengfukung-demo`, and the public site would find no temple. **So Phase B uses
`db:migrate`, never `db:schema:load`, `db:reset` or `db:setup`.** Observed
2026-09-25: neither production nor staging has recorded `20260925000000`, so
`db:migrate` will run it on both.

**Staging is also one migration behind.** Its highest applied migration is
`20260831010000`; it never ran `20260907000000_create_temple_gallery_photos`,
which production has. Staging's checkout was moved to `main` on 2026-09-14
without a migrate, so its gallery has had no table since. Its `db:migrate` in
Phase B runs both migrations.

### Phase B — production switch. [DIRECTOR — sudo]

Code and the record must change in one short window, because the public site
finds its temple by the slug in the code. Run the migration and restart back to
back: between the two, the running server still looks for the old slug and the
public site cannot find its temple. Seconds, not minutes, but real.

**Gate: how Phase A reaches `release/current`.** Production runs a curated
branch, and this rename touches files across the whole repository, many of which
differ between `main` and `release/current`. A cherry-pick of it is unlikely to
apply cleanly. Either `main` is promoted to `release/current` in full first, or
the rename is implemented a second time on `release/current`. **[DIRECTOR]**
decides which.

**Phase B — done, 2026-09-25.** Promoted as `08fb844`. `db:migrate` renamed
the production record ("renamed 1 temple from shengfukung-wenfu to
shengfukung-demo", id 1 and its 3 registrations kept), and after the restart
`https://shengfukung.com.tw/api/v1/temple` served `shengfukung-demo`.

**But production's project slug did not move, and Phase B's check could not
see it.** `AppConstants::Project.slug` reads `ENV["PROJECT_SLUG"]` before
`project.json`, and the shared env file sets `PROJECT_SLUG=shengfukung-wenfu`.
Observed on production after Phase B:

    AppConstants::Project.slug     = "shengfukung-wenfu"   from the env file
    Profile::Identity.app_codename = "shengfukung_demo"    reads project.json directly
    temple found by the project slug: nil

Two readers of one concept with different precedence, so the rename reached one
and not the other. The public site still shows the right temple because the
resolver falls back to the first temple by id, and the demo is id 1. The admin
area uses the slug only as a brand label. Nothing a visitor sees is broken —
but the site finds its temple by fallback, not by name.

Phase B was verified by *what* the API served, not *how* it resolved. The
fallback produced the right answer, so that check could not fail. Control A's
criterion 6 test asserts the route (`:project_default`, not `:scope_fallback`),
but tests do not load production's env file.

**The rule that governs the fix — Director, 2026-09-25: an env file carries
its own slug.** `/etc/default/shengfukung-wenfu-env` keeps
`PROJECT_SLUG=shengfukung-wenfu` and is not edited. The demo deployment gets
its own `/etc/default/shengfukung-demo-env` with
`PROJECT_SLUG=shengfukung-demo`, and the demo's units load that. This is the
shape the code already assumes: `AppConstants::Project.systemd_env_file` builds
`/etc/default/#{SLUG}-env`. So Phase C is no longer cosmetic — loading the demo
env file is what makes production's project slug correct.

### Phase C — infrastructure names. [DIRECTOR — sudo, downtime]

One maintenance window, everything together, because each piece refers to the
others by path:

- The four units `shengfukung-wenfu-*` → `shengfukung-demo-*`.
- `/etc/default/shengfukung-demo-env` created as a copy of the wenfu file with
  `PROJECT_SLUG=shengfukung-demo`. `shengfukung-wenfu-env` is **left in place,
  unedited**, still carrying `PROJECT_SLUG=shengfukung-wenfu` — nothing loads it
  after the switch.
- `/var/www/shengfukung-wenfu` → `/var/www/shengfukung-demo`; `manifest.yml`'s
  `vue_dir` and `project.json`'s `marketingRoot` follow.
- The nginx configs; `shengfukung.com.tw` keeps pointing at the demo, now at the
  new root.
- The two checkout folders on the droplet, with the unit files'
  `WorkingDirectory` and `EnvironmentFile` paths and each `instance.env`.

Then run `bin/check_ops_drift` from the renamed checkout: every artefact should
report `matched`.

### After — re-link the apps

A phone that linked the demo temple stored the slug `shengfukung-wenfu`. After
Phase B that slug resolves to nothing, so the app must scan the temple's QR code
again. Observed users: the Director and one staff member. Any QR code already
printed or posted carries the old slug and stops working; the website's connect
page shows the new one immediately.

## Not mixed with other work

This touches a live host and a production data row. It is not bundled with the
mobile web work or anything else, so each can be reversed on its own.
