# STAGING COMMAND WRAPPER PLAN

**Superseded in approach, 2026-09-13, by
`ENV_PARTITION_BY_MUTABILITY_PLAN.md`.** That plan removes the precedence
problem this one proposed to guard against: once nothing is overridden, the
wrapper carries no values and there is nothing for it to drift from. §5's
second decision is answered there and §3's override list no longer applies.

What survives and is still worth reading: §0, why hand-assembled commands
were rejected; §2, why this repository's own ruling shapes the answer; and
§4, why a duplicated override list fails worse here than in the repository
it was modelled on. `bin/staging` is still needed and becomes step 5 there.

Plan only. Nothing here is implemented.

## 0. Why this exists

2026-09-13: asked for commands to start staging, Planning produced six shell
lines with `RAILS_ENV=staging PGDATABASE=templemate_data_staging` pasted into
each one. The Director rejected them as invented protocol and said to check how
`sourcegrid-labs` handles the staging database.

It handles it with a wrapper. The rejection was correct for a reason worth
writing down: in this repository `DATABASE_URL` is unset, so `staging:` in
`database.yml` falls through to libpq, which reads `PGDATABASE` -- and
`/etc/default/shengfukung-wenfu-env` sets `PGDATABASE=templemate_data`, which is
**production**. Every manual staging command therefore carries an override that,
omitted once, runs against the live database. Six chances to get it right is not
a procedure.

## 1. The reference — `sourcegrid-labs`, Observed 2026-09-13

`shengfukung-wenfu` and `sourcegrid-labs` are both clones of
`Golden-Template`. That shared origin is why the pattern transfers: the two
deployments are the same shape, run by the same person, on the same droplet
conventions. SourceGrid has `bin/staging`; this repository has nothing
staging-aware in `bin/` at all.

`sourcegrid-labs/bin/staging`:

- sources the **canonical** env files -- runtime and secrets -- and then exports
  every staging override itself: `DATABASE_URL`, `PUMA_PORT`, `RAILS_ENV`, the
  Redis URLs, the display identity. Its usage text is explicit that it "does not
  read sourcegrid-labs-staging-* env files";
- `set -euo pipefail`, usage on no arguments;
- refuses to run when an env file is unreadable, naming the file and the remedy,
  rather than proceeding with whatever the shell already has;
- `set -a` / `source` / `set +a`, `cd` to `rails/`, then
  `exec bundle exec "$@"`, with `rails` special-cased so
  `bin/staging rails db:migrate` reads naturally.

`Golden-Template` does not carry it. That matters only because of §6a: it is
what the template would be gaining, not something this repository is failing to
inherit.

## 2. Why that shape is the right one here

Because this repository has already made the decision SourceGrid's shape
encodes. `ops/docs/reference/deployment_notes.md`: "Deliberately no separate
staging env file -- Director's call: staging exists to protect the production
server, not to multiply file-management surface. Staging's systemd units share
production's own `/etc/default/shengfukung-wenfu-env`."

So the overrides belong in one reviewed place that applies them after sourcing
the shared file, which is exactly what `bin/staging` is. The wrapper is not a
new convention; it is the missing tool for a convention this repository already
has.

## 3. What the wrapper exports — from the unit, not from the doc

Observed in the installed unit on the droplet
(`/etc/systemd/system/shengfukung-wenfu-staging-puma.service`):

    ExecStart=/usr/bin/bash -lc "RAILS_ENV=staging PUMA_PORT=4002 \
      PGDATABASE=templemate_data_staging <rbenv> exec bundle exec puma ..."

Three overrides. The wrapper mirrors exactly these, and takes none of
SourceGrid's values: this repository's staging runs `RAILS_ENV=staging` where
SourceGrid's runs `production`, on 4002 rather than 3202, and selects its
database through `PGDATABASE` rather than `DATABASE_URL`.

The unit applies them as an `ExecStart` command prefix rather than
`Environment=`, for a documented reason: per `systemd.exec(7)`,
`EnvironmentFile=` resolves after `Environment=` and wins, so an
`Environment=PGDATABASE=` line
would be silently overwritten back to production's value. A wrapper sourcing the
same file has the same hazard and the same remedy -- export after sourcing,
never before.

Once it exists, the §0 commands become:

    bin/staging rails db:migrate
    bin/staging rails runner \
      'puts ActiveRecord::Base.connection_db_config.database'

## 4. The duplication, and why it is sharper here than in SourceGrid

### What the duplication is

Staging differs from production by a short list of values. That list has no
owner. In `sourcegrid-labs` it exists three times, Observed 2026-09-13:

1. `Environment=` directives in `puma-sourcegrid-labs-staging.service`;
2. an `env VAR=... VAR=...` prefix inside that same unit's `ExecStart`;
3. the `export` block in `bin/staging`.

The first two are both in one file and both necessary, which is the part that
looks like redundancy and is not. Per `systemd.exec(7)`, `EnvironmentFile=`
is resolved **after** `Environment=`, so an `Environment=PGDATABASE=...` line is
silently overwritten by the shared production env file loaded afterwards. The
`ExecStart` prefix is applied last and therefore actually wins. This
repository's own unit carries a long comment explaining exactly this, and uses
only the prefix form.

The third copy exists because a shell is a different entry point from systemd.
`bin/staging` cannot read the unit, so it restates the list.

### Why drift is silent

Nothing compares the copies. Rename the staging database, or change its port,
and update one copy: the service and the manual commands now address different
things, and both continue to work. Nothing fails, no log line appears, and the
divergence surfaces only as a confusing result -- a migration that "ran" but
whose table never appears to the app, or a console that shows data the running
service does not have.

### Why this repository fails worse than the one being copied

SourceGrid's wrapper supplies a **safe default**:

    export DATABASE_URL="${SOURCEGRID_STAGING_DATABASE_URL:-postgresql:///sourcegrid_staging}"

If the override variable is absent, it still resolves to the staging database.
The failure mode of an omission is "staging", and at worst a connection error.

Here there is no default anywhere in the chain. Observed: `database.yml`'s
`staging:` entry is `url: <%= ENV["DATABASE_URL"] %>`; `DATABASE_URL` is unset
on the droplet; with no `url` and no `database:` key, libpq falls back to
`PGDATABASE`; and the shared env file sets `PGDATABASE=templemate_data`, which
is production. So an omitted or drifted override does not fail and does not
reach staging -- it connects to the production database and proceeds normally.

That asymmetry is the point. Copying SourceGrid's structure without its safe
default reproduces the ceremony and not the protection, in the one repository
where the unguarded path leads somewhere worse.

### What follows for the implementation

Structure alone is not enough here. Whatever §5 decides about consolidating the
copies, the wrapper should also:

- resolve the staging database from an explicit default rather than relying on
  the override being present, as SourceGrid's does; and
- refuse to run if the database it resolved is not the staging one -- assert
  before executing, rather than trusting that the export worked.

A guard makes drift loud instead of silent, which is worth having even if the
copies are consolidated, and is the only thing that makes them safe if they are
not.

## 5. Decisions for the Director

1. **`S3_OBJECT_PREFIX`.** `deployment_notes.md` says the staging units override
   four values "the last added by the Phase 0 prefix work", naming
   `S3_OBJECT_PREFIX=staging`. The installed unit overrides three and does not
   include it. Inference: staging therefore writes uploads into production's S3
   prefix. Which is right decides both what the wrapper exports and whether the
   unit needs repairing -- the wrapper cannot be written without an answer.
2. **Whether the unit invokes the wrapper**, per §4, or whether two copies are
   accepted and kept in step by review.

## 6. Not in scope

- Re-enabling staging, which was disabled 2026-09-05 and needs sudo.
- The staging database's contents, idle since that date.
- The wrapper's own implementation here, which waits on §5.

## 6a. Porting back to Golden-Template — the Director, 2026-09-13

"interesting, that means we can port this back to Golden-Template, add to v3."

Intended, and it is the right destination. Both this repository and
`sourcegrid-labs` are `Golden-Template` clones with the same staging shape, and
only one of them has the tool for it. Putting it in the template means every
clone starts with a supported way to run a staging command, rather than
discovering the need the way this one did -- after a near miss against a
production database.

Not this repository's work to do -- `Golden-Template` is its own repo with its
own Planning. What this plan owes that effort is the comparison in §1 and §2
and the hazard in §3, so the template's version is written from the reasoning
rather than copied from whichever clone is nearest.

Sequencing is open: the template could take it first and this repository adopt
it as a clone, or this repository could prove it and the template follow. The
second is the shorter path to an answer on §5, since both decisions are about
this deployment's own facts.

## 7. Evidence limits

- The unit was read on the droplet, the two wrappers in their working trees, all
  on 2026-09-13.
- Only the puma unit was read. The sidekiq unit's overrides were not, and could
  differ.
- That staging writes to production's S3 prefix is inference from the absence of
  the override, not an observed upload.
