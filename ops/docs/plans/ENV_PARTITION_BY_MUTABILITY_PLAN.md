# ENVIRONMENT PARTITION BY MUTABILITY

Plan only. Nothing implemented. The decisions in §6 are the Director's.

## 0. Where this came from

SourceGrid Control A wrote an implementation spec on 2026-09-13
(`WENFU_ENV_PARTITION_SPEC.md`, carried by the Director, committed nowhere)
after Wenfu Planning asked SourceGrid Planning a read-only diagnostic about
duplicated staging overrides. It supersedes the approach in
`STAGING_COMMAND_WRAPPER_PLAN.md`: that plan proposed a wrapper plus a guard to
make a precedence problem survivable; this removes the precedence problem.

Its principle, quoted:

> Partition the environment by **what differs per instance**, not by deployment
> role. One shared file holds what is identical everywhere. One instance file
> holds everything that differs, and lives beside the checkout it belongs to.
>
> Nothing is overridden. There is no precedence question, because no two
> sources ever set the same variable.
>
> Safety comes from the shared file no longer containing any pointer to mutable
> state: a forgotten value is then *absent* rather than silently production's,
> and absent cannot serve traffic.

That is a stronger answer than a guard, and it is adopted.

## 1. The spec asked for host confirmation. Here it is.

The spec states plainly that nothing in it was read from the droplet and that
every claim about `/etc/default/shengfukung-wenfu-env` is inferred from
`ops/env/template.temple.env`. All of the following was read on the host,
2026-09-13, read-only.

**Confirmed as written:**

- Four units exist, all loading one `EnvironmentFile=`, the shared file.
- `DATABASE_URL` does not appear in the shared file, so `database.yml`'s
  `url: <%= ENV["DATABASE_URL"] %>` resolves to nil for both `production:` and
  `staging:`, and the database name is decided by libpq from `PGDATABASE`. The
  spec's consequence follows: `connection_db_config.database` cannot be relied
  on for a guard.
- All five proposed instance keys are currently in the shared file:
  `RAILS_ENV`, `RACK_ENV`, `PUMA_PORT`, `PGDATABASE`, `S3_OBJECT_PREFIX`.
- Staging shares production's payment and mail credentials. Present in the
  shared file: seven `STRIPE_*`, four `LINE_PAY_*`, two `BREVO_*`. Also
  `SECRET_KEY_BASE`, `JWT_SECRET_KEY` and `QA_DUMMY_ADMIN_PASSWORD`.

**Three corrections. Two of them matter.**

**1a. Staging overrides three values, not four.** Both staging units' ExecStart
prefixes are exactly:

    RAILS_ENV=staging PUMA_PORT=4002 PGDATABASE=templemate_data_staging

`S3_OBJECT_PREFIX` is **not** among them. The spec inherited "four" from
`deployment_notes.md`, which claims `S3_OBJECT_PREFIX=staging` was "added by the
Phase 0 prefix work". The installed unit disagrees with the document, and the
unit is what runs.

This strengthens the case rather than weakening it. It is not an override to be
removed in step 3; it is a live defect the partition fixes — staging writes S3
objects under production's prefix today.

**1b. `S3_OBJECT_PREFIX` is `prod`, not empty.** Step 1 of the spec writes
`S3_OBJECT_PREFIX=` into production's instance file and asks the implementer to
"confirm empty behaves as production does today". It does not. The live value
is `prod`. Following step 1 as written would move every production S3 object
path. Production's instance file must carry `S3_OBJECT_PREFIX=prod`.

**1c. This repository has no `Environment=` directives.** None of the four units
uses one; the only precedence surface is the ExecStart prefix. The systemd
`EnvironmentFile=`-after-`Environment=` trap that motivates SourceGrid's
belt-and-braces does not exist here, so the migration is simpler than the shape
it is modelled on.

**Also found, not in the spec:** staging runs with `RACK_ENV=production`.
`RACK_ENV` is in the shared file set to `production` and is not in either
staging prefix, so staging's Rails is `staging` while its Rack is `production`.
Probably harmless; it is exactly the class of silent divergence the partition
ends, and it is listed in the instance keys already.

## 2. Live values the instance files must carry — Observed

    production checkout            staging checkout
    RAILS_ENV=production           RAILS_ENV=staging
    RACK_ENV=production            RACK_ENV=staging
    PUMA_PORT=4003                 PUMA_PORT=4002
    PGDATABASE=templemate_data     PGDATABASE=templemate_data_staging
    S3_OBJECT_PREFIX=prod          S3_OBJECT_PREFIX=staging

Every production value above is the current live value, read from the host, not
derived from a template or a document.

## 3. Target unit shape

As the spec gives it, with its four load-bearing properties intact: the
instance file named by the checkout path so a deployment cannot read another's;
listed second so it wins during the staged migration; no `-` prefix, so a
missing file is a hard failure; and no `Environment=` and no ExecStart prefix,
since neither is needed once nothing is overridden.

## 4. Migration

The spec's steps 0-5, with 1b applied and one reordering.

**Run step 2 before step 0.** The spec says the guard reads config, but config
cannot name the database until step 2 puts `database:` back — until then the
guard sees nil and silently passes. The spec offers writing step 0 against
`SELECT current_database()` and simplifying later; taking step 2 first is
cheaper and leaves one guard rather than two.

Then: step 1 create both instance files and add the second `EnvironmentFile=`
to all four units, changing nothing observable; step 0 add the boot guard and
prove it passes against a known-good state; step 3 remove the ExecStart
prefixes; step 4 delete the five keys from the shared file; step 5 make the
wrapper source shared-then-instance and export nothing of its own.

The spec's verification stands and is not optional:

> delete one key from staging's instance file and confirm staging refuses to
> boot — **the migration is not proven until you have seen it fail.**

Note the spec's `Console` exclusion on the guard, and decide deliberately which
commands it should stop. A guard that also aborts `rails console` and
`db:migrate` is a guard that gets deleted rather than fixed.

## 5. Relationship to the wrapper plan

`STAGING_COMMAND_WRAPPER_PLAN.md` stays, reduced. Its §5 decision about whether
the unit should invoke the wrapper is answered: neither carries values, so
there is nothing to consolidate. Its §4 analysis of why duplication is
dangerous here remains the reason this work is worth doing. `bin/staging` is
still needed — there is still no supported way to run a manual staging command
— but it becomes step 5, a file that sources two files in order and exports
nothing.

## 6. Decisions for the Director

1. **Payment and mail credentials.** Confirmed shared: staging can create real
   Stripe charges, real LINE Pay transactions, and send real Brevo mail.
   Pre-existing and independent of this work. The spec reports rather than
   decides, and so does this.
2. **`S3_OBJECT_PREFIX=staging` for the staging instance.** Adopting it changes
   where staging writes, which is the point, but existing staging objects under
   `prod` stay where they are.
3. **Whether this lands before or after the Expo promotion.** It touches the
   production unit files and the shared env file; the Expo work needs a Rails
   deploy and a `release/current` promotion. Doing both at once means a failure
   has two candidate causes.

## 7. Not in scope

- Blast-radius isolation. Staging still shares the Postgres server and role
  with production; only the database name differs.
- Re-enabling staging, disabled 2026-09-05, which needs sudo.
- SourceGrid's own adoption. Per the spec: SourceGrid takes this shape after
  Wenfu is green, and the framework ports while the values do not.

## 8. Evidence limits

- Host reads were of the four unit files, the shared env file's key names, and
  the six non-secret values in §2. No secret value was read or printed.
- The staging database's contents were not inspected.
- That staging writes to production's S3 prefix is inference from the absence
  of the override in both staging units, not an observed upload.
