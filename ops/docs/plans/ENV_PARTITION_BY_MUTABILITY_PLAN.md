# ENVIRONMENT PARTITION BY MUTABILITY

Plan only. Nothing implemented. The decisions in §6 are the Director's.

## What this is

Release server hardening -- the Director's name for it, 2026-09-13: "correcting
env files, and how we start our 2 servers on droplet and connected databases."
That is the whole of this document. There is no separate hardening track; the
partition, the guard and the wrapper are it.

Two servers on one droplet, production on 4003 and staging on 4002, sharing one
env file in which the only thing telling them apart is an override on staging's
`ExecStart`. Remove that override and staging runs against production's
database, silently. The phases below end that by construction rather than by
care.

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

## 4. Implementation phases

The spec's steps 0-5, ordered along the permission boundaries that actually
exist on the host, Observed 2026-09-13:

    /etc/default/shengfukung-wenfu-env   root:jimmy1768_user 640  sudo
    /etc/systemd/system/*.service        root:root           644  sudo
    ~/Projects/<checkout>/               jimmy1768_user           writable

So instance files need no sudo; unit files, the shared env file, and every
`daemon-reload` and `restart` do. Anything marked **[DIRECTOR]** cannot be done
from a session: `sudo` on this host prompts for a password.

Run this after every phase, against both deployments:

    bin/rails runner 'puts ActiveRecord::Base.connection.execute(
      %q{SELECT current_database()}).first'

### Phase 0 — enable staging **[DIRECTOR — sudo]**

Staging was disabled 2026-09-05 and nothing listens on 4002. Nothing below can
be verified until it runs. Enable and start both units on the *current* config,
unchanged, and confirm it boots. That is also the baseline Phase 3 is measured
against, and it is what the Expo promotion needs regardless of this work.

### Phase 1 — repository only. No droplet, no Director.

Ordinary Control work, merged to `main`, deployed later in Phase 4.

- **`.gitignore`: add `instance.env`.** Observed: it is not currently ignored,
  so it would sit untracked inside each checkout, where `git clean` would
  delete it and every `git status --porcelain` cleanliness check would report
  it. Do this first; it is the cheapest thing to forget.
- **`rails/config/database.yml`**: give `production:` and `staging:` a
  `database: <%= ENV.fetch("PGDATABASE", nil) %>` and remove the dead
  `url: <%= ENV["DATABASE_URL"] %>` lines. This is what makes the name knowable
  from config, which the guard depends on.

  **The nil default is required.** This plan and the spec both originally said
  bare `ENV.fetch`, arguing it gave "structural loudness in Rails config". It
  does not: Rails renders the whole file's ERB in one pass in whatever
  environment is running, so production's line is evaluated during `bin/rails
  test` and every development boot, where `PGDATABASE` is legitimately unset,
  and raises `KeyError` before a test runs. Observed by applying the original
  form and running the suite. Absence stays fatal, enforced one layer up in
  the guard, which can name the file to fix rather than surfacing a KeyError
  from inside a template.

  SourceGrid Planning's generalisation, which is the rule to carry: *a config
  file evaluated in every environment cannot carry an environment-specific
  assertion; assertions belong after `Rails.env` is known.*
- **`rails/config/initializers/deployment_identity.rb`**: the boot guard, with
  the spec's `Console` exclusion. Decide deliberately which commands it stops.
- **`ops/env/`**: templates for the two instance files, so a future clone has
  the shape.
- **`bin/staging`**: sources the shared file then the instance file for the
  checkout it stands in, in that order, exporting nothing of its own.

The guard is written here but only becomes live in Phase 4, by which time
`database.yml` can answer it. That is the spec's step-0-before-step-2 hazard,
resolved by phasing rather than by reordering.

### Phase 2 — write the instance files. No sudo.

Both checkouts are writable by the deploy user, and none of these five values
is a secret.

    ~/Projects/shengfukung-wenfu/instance.env
      RAILS_ENV=production
      RACK_ENV=production
      PUMA_PORT=4003
      PGDATABASE=templemate_data
      S3_OBJECT_PREFIX=prod

    ~/Projects/shengfukung-wenfu-staging/instance.env
      RAILS_ENV=staging
      RACK_ENV=staging
      PUMA_PORT=4002
      PGDATABASE=templemate_data_staging
      S3_OBJECT_PREFIX=staging

**[DIRECTOR — confirm, do not supply]** Every production value above was read
live from the host and needs no invention. The one to check rather than trust
is `S3_OBJECT_PREFIX=prod`: the spec proposed empty, and empty would move every
production S3 object path. `staging` for the staging file is decision §6.2 and
is a change in behaviour, not a transcription.

Nothing reads these files yet. Writing them changes nothing.

### Phase 3 — units load the instance file **[DIRECTOR — sudo]**

Add a second `EnvironmentFile=` line to all four units, pointing at the
instance file in that unit's own checkout, listed after the shared file and
with no `-` prefix. `daemon-reload`, restart all four.

Nothing should change: all sources now agree. This is the phase that buys the
staged safety, because the instance file already wins before anything is
removed from the shared file.

### Phase 4 — deploy Phase 1, prove the guard **[DIRECTOR — sudo]**

Pull both checkouts to the merged `main`, restart. The guard is now live and
passing against a state known to be correct. A guard that has never passed
against a known-good state is untested, and the later phases are the wrong
moment to find it was written wrong.

### Phase 5 — remove the ExecStart prefixes **[DIRECTOR — sudo]**

Delete `RAILS_ENV=staging PUMA_PORT=4002 PGDATABASE=templemate_data_staging`
from both staging units. `daemon-reload`, restart, verify. The instance file is
now doing the work alone.

### Phase 6 — empty the shared file, prove it fails **[DIRECTOR — sudo + edit]**

Delete `RAILS_ENV`, `RACK_ENV`, `PUMA_PORT`, `PGDATABASE` and
`S3_OBJECT_PREFIX` from `/etc/default/shengfukung-wenfu-env`. Root-owned, so
this is an edit only the Director can make. Restart both.

Only now is absence structural: from here a missing instance file or a missing
key stops a deployment instead of silently handing it production's values.

Then, from the spec, and not optional:

> delete one key from staging's instance file and confirm staging refuses to
> boot -- **the migration is not proven until you have seen it fail.**

Put it back.

### Not yet phased

The env file split is decided and lands between Phase 1 and Phase 3, as
**Phase 2a**. It is **[DIRECTOR — sudo and the edit]** throughout, since it
creates and populates two root-owned files in `/etc/default/`. Repository work
that can precede it with no Director involvement: the two `.env.example` stubs
under `ops/env/`, mirroring SourceGrid's, which is what a future clone fills in.

### Where the Director is needed, in one list

    Phase 0   sudo    enable and start the staging units
    Phase 2   values  confirm S3_OBJECT_PREFIX=prod and the staging prefix
    Phase 3   sudo    edit four unit files, daemon-reload, restart
    Phase 4   sudo    restart after deploying
    Phase 5   sudo    edit two unit files, daemon-reload, restart
    Phase 6   sudo    edit the shared env file, restart, and the failure test

Phase 1 needs nothing from the Director beyond ordinary review. Phase 2 needs
judgement on two values and no sudo.

## 4a. The guard and the wrapper — settled 2026-09-13

The spec left two things undecided and this plan asked SourceGrid Planning to
rule, since the spec is theirs. Settled across `decision.001` through `.003` and
this repository's replies. Attribution is marked because the reasoning matters
more than the outcome.

### What gets built

**The guard** makes one comparison, in one place:

- Refuse when a **declared** environment disagrees with the resolved database
  name. Console or not, human present or not.
- Warn only when there is **no declaration AND stdin is a TTY**.
- Refuse otherwise.
- `WENFU_EXPECTED_DATABASE=<exact name>` overrides the comparison on both paths.

**The wrapper** sources the shared file, then the checkout's `instance.env`, and
exports nothing but the one environment it declares. It carries no copy of any
value, so there is no second list to drift.

Result: one copy of every value (the instance file), one comparison (the guard),
one declared intent (the wrapper's name).

### Why each piece is shaped that way

**Assert the database name, not `RAILS_ENV`** — SourceGrid. This plan proposed
asserting `RAILS_ENV` and it was wrong: the hazard is an omission failure.
Staging's instance file can set `RAILS_ENV=staging` and omit `PGDATABASE`, the
shared file answers in its place, and a `RAILS_ENV` assertion passes while the
console connects to production. A label that correlates with the hazard is not
the hazard.

**The wrapper asserts rather than exports** — this repository. SourceGrid first
ruled that the wrapper should export its own values, as theirs does. Withdrawn
after checking: hardcoding a database in the wrapper protects the console and
leaves the systemd service reading the same surface, so it removes the risk from
one of two consumers and leaves them disagreeing with no way to tell which is
right. See §4 for why a second list is the hazard here specifically.

**The exemption keys on declaration, not on console** — this repository, ruled
by SourceGrid. The guard as first built warned rather than refused at a console,
following the spec's own note that a guard which aborts `rails console` "is how
guards get deleted rather than fixed". That exemption swallows the Gap 1 defect:
a wrapper named `staging` would warn and open a production console anyway.

Keying on declaration separates two real situations. Nobody asserted anything:
the operator's belief is still forming and a warning informs it. Something
asserted an environment and was wrong: the belief is already fixed and already
false. SourceGrid's formulation — *presence is what makes a warning readable, it
is not what makes it timely* — is why a human being present does not soften a
declared mismatch. And a guard that fires only on a broken promise is silent
through every correct invocation, so it does not accumulate the resentment the
spec was protecting against.

**Two positive conditions, not one absence** — SourceGrid. Requiring only that a
declaration be *absent* to reach the warning makes absence the permissive
direction, which is Defect 1's shape one layer up. A declaration can go missing
from the wrapper failing before its export, a hand-sourced instance file, `sudo`
or `env -i` stripping it, or a refactor moving the export below the exec. So the
permissive path requires no declaration **and** an interactive stdin.

### The TTY probe — verified in both directions

Observed in this repository: `$stdin.tty?` is false from a Claude session
directly, under `bundle exec`, and through a pipe. Reproduced independently by
SourceGrid Planning in `sourcegrid-labs`, a different repository and session.

Observed in both repositories, using `script(1)` to allocate a pty: true under a
pty, and true through a plain `exec` — the shape `bin/staging` ends with, so the
TTY survives it.

Two consequences worth keeping:

- **The permissive path is structurally unreachable from an agent session.**
  Every session, script, pipe and automation takes the refusal. The warning is
  reachable only with a real terminal. That matters here because the main
  non-human operator of this repository is a Claude session, and this excludes
  them by construction rather than by policy.
- **The probe fails closed.** Every way of losing a TTY — `ssh` without `-t`, a
  pipe, a script, a stripped environment — lands on refuse. No configuration
  accidentally opens the permissive path.

Evidence limit: a pty is not any particular terminal emulator, and `tty?`
interrogates the file descriptor rather than what is attached beyond it. This
confirms the probe answers correctly to a pty through an `exec`. Whether a given
operator's path supplies one is still an observation, not an assumption — and
where it does not, the guard refuses, which is the safe direction.

## 5. Relationship to the wrapper plan

`STAGING_COMMAND_WRAPPER_PLAN.md` stays, reduced. Its §5 decision about whether
the unit should invoke the wrapper is answered: neither carries values, so
there is nothing to consolidate. Its §4 analysis of why duplication is
dangerous here remains the reason this work is worth doing. `bin/staging` is
still needed — there is still no supported way to run a manual staging command
— but it becomes step 5, a file that sources two files in order and exports
nothing.

## 5a. One framework for every repository — the Director, 2026-09-13

"i want one system that runs all of my repos, i don't want to remember big
differences. if it requires more build, i can accept it... use the same
convention for all. so don't say, sourcegrid has it but we don't, so we don't
need it."

This governs the work and outranks per-repository convenience. The partition
above is not a Wenfu answer to a Wenfu problem; it is the shape every
deployment takes, and Wenfu is where it is proven first. Where repositories
currently differ, the difference is resolved rather than accommodated, and the
resolution goes to `Golden-Template` so no clone inherits a dialect.

Unused does not mean absent: a key that a project has no use for is present and
blank. AppRelay does not use S3, so it carries `S3_OBJECT_PREFIX=` rather than
omitting it. The schema is the same everywhere; only values differ.

### The four conventions, and how each resolves

**1. `RAILS_ENV` for staging — Wenfu's, not SourceGrid's.**

The repositories disagree deliberately, and the less obvious one is right.
SourceGrid runs staging with `RAILS_ENV=production` so it behaves identically
to production. Wenfu runs `RAILS_ENV=staging`, and
`rails/config/environments/staging.rb` is a single `require_relative
"production"`, with the reasoning in its header:

> Staging is infrastructure separation only, not a distinct application
> behavior -- it must run identically to production... Reusing production.rb
> directly (rather than duplicating its settings here) is what actually
> guarantees that: there is no second copy of these settings to drift out of
> sync... not in `RAILS_ENV` pretending to be "production" the way some sibling
> projects' staging setups do.

Same behavioural guarantee, and `Rails.env` stays honest, so logs, error
reports and `config/puma.rb`'s `when "staging"` case can tell the deployments
apart. Observed: zero `Rails.env.staging?` references in `rails/app` or
`rails/config`, so nothing depends on staging behaving differently. Unifying
means SourceGrid adopts the one-line `staging.rb`; it does not mean Wenfu
adopts the pretence.

**2. Blank is fine, and nothing needs migrating.**

Unused keys are present and blank. Existing env files already carry many
blanks; they live in the shared file, the partition does not move them, and
none of them needs touching.

Blank already reads as "unused" where it matters. `s3_service.rb:57-61`:

    prefix = ENV["S3_OBJECT_PREFIX"].to_s
    return raw if prefix.blank?

Blank means no prefix, which is exactly the intent. A sentinel would be worse,
not better: environment values are strings, so `S3_OBJECT_PREFIX=null` is not
blank, gets normalised to `"null/"`, and every object lands under
`s3://bucket/null/`. Making a sentinel safe would mean every consumer -- Rails,
the Vue build, shell scripts -- decoding it, and one missed decode is silent.

The only case worth guarding is a blank value for one of the five *instance*
keys, which is a typo rather than a state anyone chooses. Step 0's guard
already covers the one that matters: a blank `PGDATABASE` does not resolve to
the expected name, so the deployment aborts. No additional rule, no schema, and
no declaration of which keys may be blank -- that was considered and rejected
as machinery for a problem the guard already solves.

**3. Ports — already uniform; declare the base.**

Not a divergence. SourceGrid is 3201/3202/3203 and Wenfu 4001/4002/4003:
one convention, `<base>01` development, `<base>02` staging, `<base>03`
production, with a different base because they share a host. The base is a
per-project parameter. Declaring it once and deriving the three, rather than
typing three literals, is what makes it a convention instead of a coincidence.

**4. Env file split — DECIDED 2026-09-13: split, same as SourceGrid.**

SourceGrid splits `/etc/default/<project>-runtime.env` from `-secrets.env`.
Wenfu has one file, in which `STRIPE_SECRET_KEY`, `SECRET_KEY_BASE`,
`JWT_SECRET_KEY` and `QA_DUMMY_ADMIN_PASSWORD` sit beside `PROJECT_NAME` and
`VITE_TEMPLE_LAYOUT`. Recommendation: adopt the split. It lets the secrets half
carry tighter permissions, and lets the runtime half exist as a reviewable
template in `ops/env/` that a new clone fills in -- neither of which a single
mixed file can offer.

The Director's ruling, 2026-09-13: "yes, split it. same as sourcegrid."

Three files per deployment, and the unit loads them in order:

    EnvironmentFile=/etc/default/<project>-runtime.env
    EnvironmentFile=/etc/default/<project>-secrets.env
    EnvironmentFile=<checkout>/instance.env

The ordering still matters only as defence: under the partition no two of them
set the same variable.

**Classification follows SourceGrid's own files, not our judgement.** They keep
stubs in the repository at `ops/env/sourcegrid-labs-*.env.example` --
runtime carrying real non-secret values, secrets carrying placeholders -- and
those settle most of what was ambiguous here. Observed 2026-09-13:

    AUTH_CLIENT_ID                  runtime   (its secret sibling is not)
    STRIPE_PUBLISHABLE_KEY          runtime   (publishable by design)
    EAS_PROJECT_ID                  runtime
    S3_SECRET_ACCESS_KEY            secrets
    BREVO_API_KEY, JWT_SECRET_KEY   secrets
    SECRET_KEY_BASE                 secrets

By analogy with their `STRIPE_PRICE_*`, our
`STRIPE_TEMPLEMATE_PLATFORM_ACCOUNT_ID` and the two price IDs are runtime.

**The rule this repository uses**, decided 2026-09-13: an identifier alone is
runtime; anything that authenticates on its own is secrets. So
`S3_ACCESS_KEY_ID` sits in runtime and `S3_SECRET_ACCESS_KEY` in secrets.

SourceGrid's own files disagree with themselves on this -- `AWS_ACCESS_KEY_ID`
in runtime, `S3_ACCESS_KEY_ID` in secrets, the same kind of value classified two
ways. **That is not this work's problem to raise.** The Director's ruling: the
rule is right but reconciling it now would mix two repositories' decisions
together, and he will move the key himself during SourceGrid's own staging and
env-protocol phase. Nothing here waits on that, and nothing here should send it
to them as an action.

**Two keys have no precedent there** and need a call when the files are written:
`PGUSER`, which is an identifier rather than a credential and by the rule above
is runtime; and `PGDATABASE_TEST`, which no deployment reads at all and arguably
should not be on the droplet. SourceGrid has neither, because they resolve the
database through `DATABASE_URL` -- which they classify as a secret, correctly,
since it embeds the password.

**What the partition changes about their shape.** SourceGrid's runtime file
carries `RAILS_ENV` and `PUMA_PORT`; ours must not, because those are two of the
five that move to `instance.env`. We are adopting their split plus our
partition, which they do not yet have. Our runtime file is therefore theirs
minus the five instance keys.

### Consequence for §4

Wenfu's migration is unchanged in shape but gains the split as a step between
1 and 3, and step 2 takes the blank-rejecting form. The framework -- not the
values -- then ports to `Golden-Template`, per `6a` of
`STAGING_COMMAND_WRAPPER_PLAN.md`, and SourceGrid adopts it after Wenfu is
green, per the spec's own closing note.

## 6. Decisions for the Director

1. **Payment and mail credentials.** Confirmed shared: staging can create real
   Stripe charges, real LINE Pay transactions, and send real Brevo mail.
   Pre-existing and independent of this work. The spec reports rather than
   decides, and so does this.
2. **`S3_OBJECT_PREFIX=staging` for the staging instance.** Adopting it changes
   where staging writes, which is the point, but existing staging objects under
   `prod` stay where they are.
3. ~~**The env file split**~~ — DECIDED 2026-09-13, split as SourceGrid
   does.
   See 5a.4 for the classification and the two keys that still need a call when
   the files are written.
4. **Whether this lands before or after the Expo promotion.** It touches the
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
