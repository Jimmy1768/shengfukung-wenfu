# Platform Env File Reorganization Plan

## Status: paused, rescoped after a real attempt — deferred, not abandoned

First attempt (`7069c38`) tried to hand-edit the rendered
`ops/systemd/shengfukung-wenfu-{puma,sidekiq}.service` files directly.
Reverted (`1778068`) after discovering the env file name isn't
independently configurable — it's derived from the project slug via
`ops/systemd/template/golden-template-*.service` (`{{project_slug}}-env`),
rendered by `bin/stage_ops_configs`/`bin/apply_systemd_units`, which
already ran once during this attempt and silently regenerated the
files back to `shengfukung-wenfu-env` from the template, confirming the
hand-edit would never have survived anyway.

**Doing this properly means changing `shared/app_constants/project.json`'s
`slug`, not just an env file name** — and that slug also drives the
systemd service names (`{{project_slug}}-puma.service`), the nginx
config filename, and the `WorkingDirectory` path
(`/home/jimmy1768_user/Projects/{{project_slug}}/rails`). The server's
actual cloned directory is still named `shengfukung-wenfu` on disk — a
slug change without also renaming that directory would point
`WorkingDirectory` at a path that doesn't exist and break the service
outright. This is a real, cascading rename (services, nginx, the
on-disk directory), not the single-file change originally scoped.

## Objective (unchanged, revisit later with full scope acknowledged)

The Rails backend's production env file is named `shengfukung-wenfu-env`
— scoped to look like it belongs to one temple tenant, when it's
actually the centralized platform config serving every temple through
this backend (per `ops/protocol/repo_context.md`'s
"Domain And Tenancy Architecture" section). Still worth fixing, but as
its own deliberately-scoped project-slug migration, not squeezed in
alongside an unrelated OAuth fix.

## Immediate unblock (separate from the rename, do this now)

Add `AUTH_NATIVE_RETURN_URL=templemate://oauth/complete` directly to
the **existing, currently-in-use** `/etc/default/shengfukung-wenfu-env`
— no rename, no new file. This is what's actually referenced by the
live (reverted-back) systemd units. Also remove the orphaned
`/etc/default/templemate-env` created during the aborted attempt —
unused, and exactly the kind of stale duplicate config that causes
confusion later if left behind.

## Next Owner/Action

Rename itself: on hold until the Director decides whether to take on
the full project-slug migration (services + nginx + on-disk directory
rename) as its own deliberately scoped, separately authorized piece of
work. Not blocking anything — the platform runs correctly under the
current name either way.
