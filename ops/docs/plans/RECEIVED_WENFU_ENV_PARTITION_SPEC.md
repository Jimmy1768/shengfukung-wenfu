> **Received document, preserved verbatim. Do not edit.**
>
> Written by SourceGrid Control A on 2026-09-13 and carried to Wenfu by the
> Director. It was committed in no repository -- SourceGrid Planning searched
> sourcegrid-labs, control-a and control-b, and Wenfu Planning searched this
> one -- so two repositories were implementing against a file that existed only
> inside the session that wrote it. Committed here so it survives that session.
>
> It is the source, not the plan. `ENV_PARTITION_BY_MUTABILITY_PLAN.md` is what
> Wenfu implements; its §1 records four defects found in this document by
> reading the host, and SourceGrid Planning's `decision.001` rules on two gaps
> it left open. Where this file and that plan disagree, the plan is current and
> this is the record of where it came from.
>
> Corrections belong in the plan or in a new message, never in this file.

# Wenfu: environment partition by mutability — implementation spec

Written by SourceGrid Control A, 2026-09-13, for Wenfu Planning to assign.
Not committed anywhere. Carried by the Director.

Facts below were read from `~/Projects/shengfukung-wenfu` in the working tree
on 2026-09-13. **Nothing here was read from the Wenfu droplet** — every claim
about `/etc/default/shengfukung-wenfu-env` is inferred from
`ops/env/template.temple.env` and must be confirmed on the host before step 1.

## The principle

Partition the environment by **what differs per instance**, not by deployment
role. One shared file holds what is identical everywhere. One instance file
holds everything that differs, and lives beside the checkout it belongs to.

Nothing is overridden. There is no precedence question, because no two sources
ever set the same variable.

Safety comes from the shared file no longer containing any pointer to mutable
state: a forgotten value is then *absent* rather than silently production's,
and absent cannot serve traffic.

## Current state

Four units, all loading one shared file, staging overriding four values in an
ExecStart command prefix:

| unit | checkout | override prefix |
| --- | --- | --- |
| `shengfukung-wenfu-puma` | `shengfukung-wenfu` | none |
| `shengfukung-wenfu-sidekiq` | `shengfukung-wenfu` | none |
| `shengfukung-wenfu-staging-puma` | `shengfukung-wenfu-staging` | 4 vars |
| `shengfukung-wenfu-staging-sidekiq` | `shengfukung-wenfu-staging` | 4 vars |

Overrides: `RAILS_ENV=staging PUMA_PORT=4002 PGDATABASE=templemate_data_staging
S3_OBJECT_PREFIX=staging`.

The mechanism is correct — a command prefix is applied after systemd composes
the environment, so it wins. The exposure is that it is the *only* thing that
wins, and the shared file underneath it holds production's `PGDATABASE`.

### Two things found while reading, which the partition surfaces

**1. `database.yml` cannot name the database from config.**

    staging:
      <<: *default
      url: <%= ENV["DATABASE_URL"] %>

`DATABASE_URL` does not appear in `ops/env/template.temple.env`, so `url:`
resolves to nil and the entry carries no `database:` key. The name is decided
by libpq from `PGDATABASE` at connect time. The `production:` entry has the
same shape, so this likely applies to production too — confirm on the host.

Consequence: `ActiveRecord::Base.connection_db_config.database` returns nil.
Any guard written against it would silently pass. The guard must either query
the live connection, or `database.yml` must name the database — step 2 does
the latter, which is cheaper and fails earlier.

**2. Staging shares production's payment credentials.**

`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `LINE_PAY_CHANNEL_SECRET` and
`BREVO_API_KEY` are in the shared file. By the membership rule below they are
pointers to mutable external state — staging can create real charges and send
real mail. This is pre-existing and independent of the systemd defect. It is
reported, not decided: moving them is Wenfu's call, and the partition simply
makes the question visible.

## Membership rule

A variable goes in the **instance file** if it differs between two deployments
on the same host. Everything else stays in the **shared file**.

Instance file, for Wenfu:

    RAILS_ENV
    RACK_ENV
    PUMA_PORT
    PGDATABASE
    S3_OBJECT_PREFIX

Shared file keeps: `PROJECT_*`, `VITE_*`, `PGHOST`, `PGPORT`, `PGUSER`,
`PGPASSWORD`, `S3_BUCKET`, `S3_REGION`, `S3_ACCESS_KEY_ID`,
`S3_SECRET_ACCESS_KEY`, `AUTH_*`, `EXPO_*`, `JWT_SECRET_KEY`,
`GOOGLE_MAPS_API_KEY`, `PAYMENTS_*`, and — pending the decision above —
`STRIPE_*`, `LINE_PAY_*`, `BREVO_*`.

`PGDATABASE_TEST` stays shared; it is a developer-machine concern and no
deployment reads it.

## Target unit shape

All four units become identical apart from `WorkingDirectory`:

    [Service]
    Type=simple
    User=jimmy1768_user
    WorkingDirectory=/home/jimmy1768_user/Projects/<checkout>/rails
    EnvironmentFile=/etc/default/shengfukung-wenfu-env
    EnvironmentFile=/home/jimmy1768_user/Projects/<checkout>/instance.env
    ExecStart=/usr/bin/bash -lc "/home/jimmy1768_user/.rbenv/bin/rbenv exec bundle exec puma -C config/puma.rb"
    Restart=always

Four properties, each load-bearing:

- **The instance file is named by the checkout path**, so a deployment cannot
  read another's. The binding between which code and which data is a
  filesystem fact, not a list entry.
- **It is listed second.** Where two `EnvironmentFile=` lines set the same
  variable, the later wins — documented in `systemd.exec(7)`. This is what
  makes the migration safe in stages: the instance file already wins before
  anything is removed from the shared file.
- **No `-` prefix.** `EnvironmentFile=-/path` skips a missing file silently
  and throws away the whole property being bought here.
- **No `Environment=` directives, and no ExecStart override prefix.** Both
  are precedence surfaces; neither is needed once the partition exists.

## Migration

Each step is independently reversible, and steps 0–2 change nothing
observable. Run `bin/rails runner 'puts ActiveRecord::Base.connection.execute(%q{SELECT current_database()}).first'`
against both deployments after every step.

**Step 0 — guard first, while the config is still known-good.**

Add the boot guard and deploy it before changing anything. A guard that has
never passed against a state you know is correct is untested, and step 3 is
the wrong moment to discover it was written wrong.

    # rails/config/initializers/deployment_identity.rb
    expected = { "production" => "templemate_data",
                 "staging"    => "templemate_data_staging" }[Rails.env.to_s]

    if expected && !Rails.const_defined?(:Console)
      actual = ActiveRecord::Base.connection_db_config.database
      abort "refusing to boot: #{Rails.env} expects #{expected}, resolved #{actual.inspect}" unless actual == expected
    end

This reads config, not a connection — but only after step 2 makes the name
knowable from config. Until then it will see nil. **Run step 2 before step 0
if you want the guard live from the start**, or write step 0's version against
`connection.execute("SELECT current_database()")` and simplify it later.

Note the `Console` exclusion: a guard that aborts also aborts `rails console`
and `rails db:migrate`, which is how guards get deleted rather than fixed.
Decide deliberately which commands it should stop.

**Step 1 — create the instance files, change nothing else.**

    /home/jimmy1768_user/Projects/shengfukung-wenfu/instance.env
      RAILS_ENV=production
      RACK_ENV=production
      PUMA_PORT=<read the current value from the shared file>
      PGDATABASE=templemate_data
      S3_OBJECT_PREFIX=

    /home/jimmy1768_user/Projects/shengfukung-wenfu-staging/instance.env
      RAILS_ENV=staging
      RACK_ENV=staging
      PUMA_PORT=4002
      PGDATABASE=templemate_data_staging
      S3_OBJECT_PREFIX=staging

Add the second `EnvironmentFile=` line to all four units. Reload and restart.
Nothing should change: all three sources now agree.

Confirm `S3_OBJECT_PREFIX=` empty behaves as production does today — systemd
sets it to the empty string rather than leaving it unset, which is not the
same thing if the application distinguishes them.

**Step 2 — name the database in `database.yml`, remove the dead `url:` lines.**

    production:
      <<: *default
      database: <%= ENV.fetch("PGDATABASE") %>

    staging:
      <<: *default
      database: <%= ENV.fetch("PGDATABASE") %>

`fetch` with no default raises when `PGDATABASE` is unset. That is the
structural loudness expressed in Rails config, and it makes the name knowable
without connecting.

**Step 3 — remove the ExecStart override prefixes** from the two staging
units. The instance file is now doing the work alone. Restart, verify, and put
the prefix back if the database name moves.

**Step 4 — remove the per-instance keys from the shared file.** Delete
`RAILS_ENV`, `RACK_ENV`, `PUMA_PORT`, `PGDATABASE` and `S3_OBJECT_PREFIX` from
`/etc/default/shengfukung-wenfu-env`. Only now is absence structural: from
here, a missing instance file or a missing key stops a deployment rather than
silently handing it production's.

Restart both deployments. Then delete one key from staging's instance file and
confirm staging refuses to boot — **the migration is not proven until you have
seen it fail.** Put it back.

**Step 5 — apply the same shape to the wrapper.** Whatever `bin/staging`
becomes, it sources the shared file and then the instance file for the
checkout it is standing in, in that order, and exports nothing of its own. A
wrapper that carries its own copy of the values is a third source that can
disagree with the other two.

## What this does not do

- It does not give blast-radius isolation. Staging still shares the Postgres
  server with production under the same role; only the database name differs.
  A separate instance is a stronger and more expensive answer, and is an
  independent decision.
- It does not address the payment-credential sharing found above.
- It does not touch AppRelay or SourceGrid. SourceGrid adopts this shape after
  Wenfu is green; the framework ports, the values do not.
