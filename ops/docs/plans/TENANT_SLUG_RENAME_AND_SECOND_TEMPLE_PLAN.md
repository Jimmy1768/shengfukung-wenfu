# TENANT SLUG RENAME AND SECOND TEMPLE PLAN

## Decision

Rename the demo tenant's slug from `shengfukung-wenfu` to `shengfukung-demo`,
freeing `shengfukung-wenfu` for the real Shengfukung temple when it onboards.

The alternative — leaving the demo as it is and giving the real temple a new
slug such as `shengfukung-actual` — was rejected. It costs nothing today but
permanently gives the real client a name that reads as a workaround. `Wenfu` is
the temple owner's name and is the reason the convention exists.

## Why the demo holds that name at all

Historical. The project began for one client and grew into a tenant structure
serving many temples. The repository kept the original name. `templemate-core`
would match `apprelay-core` and describe what this became, but the repository
name is invisible and renaming it is a separate and far more expensive
operation — see the last section.

## What the slug is and is not — Observed 2026-09-12

Two different concepts share the string `shengfukung-wenfu`, and only one is
being renamed:

- **`AppConstants::Project.slug`** — the project. Drives the Postgres database
  name (`shengfukung_wenfu_dev`) and the S3 bucket prefix, via
  `app/lib/profile/infrastructure.rb:71,75`. **Not touched by this plan.**
- **`temples.slug`** — the tenant row. What is being renamed.

Two temple rows already exist, `demo-lotus` and `shengfukung-wenfu`, so several
tenants under one project slug is the normal case rather than something this
introduces.

## What the rename touches

- **`temples.slug`** — one column update on one row.
- **`rails/app/lib/temples/manifest.yml`** — the `slug:` key.
- **`temple_context_resolver.rb:76,87,93`** — the only genuine unknown. Requests
  arriving with no explicit slug fall back to `:project_default`, which is
  `AppConstants::Project.slug`. After the rename no tenant matches that string.
  Check what relies on that fallback before flipping.

## What it does not touch

- **Postgres and the S3 bucket** — project-derived, not tenant-derived.
- **S3 object keys.** New uploads land under `.../shengfukung-demo/` while
  existing objects keep their stored URLs. The demo's files end up split across
  two prefixes and nothing breaks. The Director's ruling: the demo's S3 content
  is disposable, so this is not a consideration at all.
- **`/var/www/shengfukung-wenfu`.** `bin/deploy_vue:55` prefers the manifest's
  explicit `deploy.vue_dir` over `/var/www/<slug>`, and the nginx `root` at
  `ops/nginx/shengfukung-wenfu.conf:20` is a literal. Slug and directory are
  already decoupled, so the rename works with the directory untouched.

## Ordering — this waits on the Expo tenant fix

**The rename must come after `EXPO_RUNTIME_TENANT_BINDING_PLAN.md` ships.**

Today the release app pins `tenantSlug: 'shengfukung-wenfu'`. Renaming the
tenant before that fix breaks every installed TestFlight build: they would fail
to bind and fail to reach the API. Once staff are on a build without the pin,
the rename costs nothing on the app side.

Sequence: Expo tenant fix → new build → rename.

## Onboarding the real temple is an addition, not a handover

The real temple does **not** take over `/var/www/shengfukung-wenfu`. Per
`ops/protocol/repo_context.md`, each client gets their own Vue deployment on
their own domain. `shengfukung.org.tw` needs its own directory, its own nginx
server block, and its own build. The demo loses nothing and there is no
handover to plan.

What onboarding needs, when the temple provides the domain:

- a `temples` row with slug `shengfukung-wenfu`
- a manifest entry: slug, domains, `public_url`, `deploy.vue_dir`
- a new `/var/www/` directory and `bin/deploy_vue` against the new slug
- an nginx server block and a certificate for `shengfukung.org.tw`

## Optional housekeeping, safe to never do

Renaming `/var/www/shengfukung-wenfu` to `/var/www/shengfukung-demo` is
cosmetic. The only cost of skipping it is a path whose name no longer matches
its tenant, seen by nobody. If it is wanted, the cheapest moment is while
editing nginx for the real temple's server block: one `mv`, one `root` line,
one `vue_dir` line, one reload, in a window where nginx is already being
touched. Doing it on its own means a production nginx edit for no functional
gain.

## Not this plan

Renaming the repository to `templemate-core`. That would drag
`AppConstants::Project.slug` with it — Postgres database name, S3 bucket
prefix, systemd unit names, deploy paths, the env file at
`/etc/default/shengfukung-wenfu-env`. Genuinely expensive, unlike the tenant
rename, and invisible either way. Two operations that look similar and are not.
