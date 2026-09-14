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

## Still open

1. **Does the rename reach infrastructure** — the env file, the four units, the
   nginx configs, `/var/www`, and the local and droplet checkout directories —
   or only the temple slug and its content? Infrastructure means a root-owned
   rename on a live host and a window where units are down.

2. **Is production's temple row migrated in place**, or does the demo get a new
   row and the old one is retired? Migrating in place is one UPDATE and keeps
   every foreign key; a new row means deciding what happens to the registrations
   already attached to the old one.

## Sequencing note

Not to be mixed with the connect page redesign or the mobile readiness work.
Those are reversible edits to markup and CSS. This touches a live host and a
production data row, and bundling them makes both harder to undo.
