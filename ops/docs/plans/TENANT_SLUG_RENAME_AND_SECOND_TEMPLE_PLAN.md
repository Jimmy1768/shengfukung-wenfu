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
- **`AUTH_TENANT_SLUG`** — a third string, and not this one: its value is
  `shengfukung`, not `shengfukung-wenfu`. It names this deployment as a
  registered client of SourceGrid's central auth at `auth.sourcegridlabs.com`,
  which holds the client credentials and the redirect-URI allowlist
  (`auth_tenant_redirect_uris`). A SourceGrid tenant, not a TempleMate one.
  **Not touched by this plan**, and see below.

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

## The env file moves; one value inside it must not

Each tenant has its own env file on the droplet at
`/etc/default/<temple-slug>-env` — `bin/load_temple_env:35` builds the path from
the slug, and `ops/docs/commands.md:113` provisions a new one by installing
`ops/env/template.temple.env` there. So the rename moves
`/etc/default/shengfukung-wenfu-env` to `/etc/default/shengfukung-demo-env`,
along with the five places `commands.md` names it literally
(`:23`, `:33`, `:133`, `:176`, `:186`), `OAUTH_PROVIDERS_SETUP_PLAN.md:78`, and
`PLATFORM_ENV_FILE_REORGANIZATION_PLAN.md:39`. That last file also records a
stray `/etc/default/templemate-env` from an aborted attempt; know it is there
before moving anything in that directory.

**`AUTH_TENANT_SLUG` keeps its value through all of this.** The file is renamed;
the line inside it is not. Setting it to the new temple slug breaks OAuth,
because central auth has no tenant by that name — it would fail closed with
`native_oauth_unavailable` 503 rather than silently, but it would fail. This is
exactly the trap `ops/docs/reference/onboarding.md:111` exists to prevent: "Do
not assume `PROJECT_SLUG == AUTH_TENANT_SLUG`. They may match for simple cases,
but they serve different scopes."

**The implication for every temple after this one.** The Director, 2026-09-12:
"this is the APP. not per temple." A new temple `jimmytemple` needs its own
`/etc/default/jimmytemple-env`, and that file carries
`AUTH_TENANT_SLUG=shengfukung` — the same value as every other temple's file.
It identifies TempleMate to its auth provider, so it does not vary by tenant and
is not a per-temple value to be filled in during onboarding. One auth tenant,
many temples.

Related, confirmed 2026-09-12: the fallback that used to supply a temple's
own slug here is gone (`native_oauth_flow.rb:123-127` now raises rather than
defaulting). That fallback would have sent `shengfukung-wenfu`, which is not a
registered tenant — so OAuth working on TestFlight is evidence the env value is
already set correctly on the droplet. Confirm it before the first deploy of the
Expo tenant work; treat it as a check, not a blocker.

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

Sequence: Expo tenant fix → new TestFlight build → **staff confirmed on that
build** → rename.

The middle step is the one that is easy to skip. Releasing the build is not the
same as staff running it; TestFlight does not auto-update, and the demo is what
the sales team shows.

What the old build does after the rename, if anyone is still on it — both
failures Observed in the code:

- **A fresh scan is refused.** `app/tenant/scanner.js` compares the server's
  `temple.slug` against the compiled `tenantSlug`. The server answers
  `shengfukung-demo`, the build expects `shengfukung-wenfu`, and the result is
  `binding_failed`.
- **An existing binding fails quietly, which is worse.**
  `app/tenant/storage.js:10` validates the stored binding against
  `config.tenantSlug`, and both are still the old string, so the binding loads
  and the app looks healthy. Then `app/real/adapter.js:6` sends
  `temple_slug=shengfukung-wenfu` on every request. `TempleContextResolver`
  finds no temple for it, falls through to `:project_default` — which is
  `AppConstants::Project.slug`, the same dead string — and resolves nothing. The
  app opens normally and then fails at everything.

"Only staff use TestFlight" does not make this safe to skip. Staff are the
people demonstrating the product.

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
