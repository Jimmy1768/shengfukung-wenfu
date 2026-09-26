# Shengfukung Wenfu — Repo Context

Product/runtime and builder-procedure context for this repository only. It does
not apply to any other repository and is not copied into another. `CLAUDE.md`
and `ops/protocol/claude_work_mode.md` are written by Workspace Strategy and
received here; copies of those lag between repositories and that is expected.
Everything true here and nowhere else belongs in this file.

The work mode governs builder coordination only. It does not define or change
Wenfu product/runtime phase integrity — temple, patron/account, offering and
registration, payment (ECPay), deployment, or other product/runtime lifecycle
semantics. Those live here.

## Domain And Tenancy Architecture

Recurring source of confusion, worth getting right once: **the Rails
backend and the TempleMate mobile app are centralized and legitimately
multi-tenant — the Vue frontend is not.**

- Rails (backend/database) and TempleMate (`mobile/`) are shared,
  single deployments serving every client/temple. A `temples` table
  with multiple tenant rows, `current_temple` resolution, and
  cross-temple switching inside those two surfaces are all legitimate.
- **Each real client gets their own separate Vue deployment on their
  own domain** — `temple1.org.tw`, etc. — not a shared multi-tenant Vue
  instance. This matches the existing `bin/deploy_vue <client-slug>`
  pattern (`ops/docs/reference/deployment_notes.md`): one build, one
  `rsync` target per client.
- `shengfukung.com.tw` is the backend's own identity permanently, by
  deliberate decision (2026-08-28, see
  `ops/docs/reference/templemate_product_positioning.md`) — not a
  placeholder awaiting a future domain swap. That backend being
  multi-tenant, with multiple temple rows reachable through it, **is
  correct and was never the actual problem.**
- **The part that must stay strictly separate is the Vue level**, and
  that's unaffected by any of the above. Each real client's Vue site
  needs its own domain, its own env file, its own deploy target — a
  browser visiting any one client's Vue site (`shengfukung.com.tw`
  today, `temple1.org.tw` for a future client) must never expose or
  switch between *other* temples' data from that one site's own
  interface. **Do not build or treat any feature as "create a new
  temple reachable from shengfukung.com.tw's own Vue frontend."** A new
  real temple means a new domain, new env file, and new Vue deployment
  — the backend can already serve it fine, only the frontend needs its
  own isolated surface.
- No dedicated platform domain (`templemate.com` or similar) will be
  acquired — decided, not deferred; see the reference doc above for the
  reasoning. The platform's own public identity, for App Store/Play
  Store listing requirements and the help guide, lives at
  `sourcegridlabs.com/templemate` instead — a page on an already-owned
  domain, not a domain the backend itself will ever run on.
  `shengfukung.org.tw` is confirmed as the real (non-demo) Shengfukung
  temple's own future Vue site once onboarded — still its own single
  domain, still isolated from other clients' Vue sites the same way.
  `shengfukung.com.tw` keeps its current role as the demo/sales-sandbox
  temple going forward; it is not replaced or retired by any of this.

## Who May Merge

`work_mode_config.md` defers this here, and until 2026-09-13 this file was
silent, which is why it blocked three times in one day: Control A could not
merge `main` into its branch, Control B sent `purge-tenant-slug` for merge
rather than merging it, and Planning was refused the command by the auto mode
classifier.

**Planning may merge.** The Director, 2026-09-13.

Neither Control may. `Bash(git merge:*)` is denied in both Control profiles,
alongside push, rebase, `reset --hard`, worktree and the `git -C` family, and a
deny refuses outright rather than prompting. A Control that needs `main` in its
branch, or its branch in `main`, asks Planning and does not reproduce the merge
by hand -- hand-applying one is the same act by another name.

This is the repository's answer, not a universal one. Workspace Strategy
declined to promote Combatives' rule that a Control may merge its own
authorized task, as not holding everywhere.

## Control Track Assignment

Control A and Control B are split by **kind of work**, not by surface:

- **Control A — core build.** Features and subsystems, on any surface. Kept
  clean, so it is never pulled off a subsystem to firefight.
- **Control B — the Expo app, and live-production hot-fixes.** Both mobile work
  and anything urgent against what is live, whichever surface it touches.
- The two stay independent; cross-track coordination routes through Planning,
  not Control-to-Control.

The second half is the point. A hot-fix goes to B **regardless of surface** — a
Rails admin fix included — so that A keeps its context on the subsystem it is
building. An earlier version of this section split them by surface instead
(A: Rails/account/admin, B: mobile), which left urgent work with no lane and
interrupted whichever Control owned the affected surface.

This is an operating convention for this repository, not a work-mode rule.

## Database Names Come From the Product, Not the Repository

The repository is called `shengfukung-wenfu`. The product is TempleMate. The
databases are named after the product.

| | |
| --- | --- |
| production | `templemate_data` |
| staging | `templemate_staging` — still `templemate_data_staging` on the droplet; renamed with the env-partition work |
| local development | `templemate_dev` |
| local test | `templemate_test`, which exists only during a run |
| local review | `templemate_review`, behind `bin/review_admin_server` |

**Two code paths, and they do not meet.** Production and staging resolve from
`ENV.fetch("PGDATABASE", nil)` and read no derived base at all, so nothing named
locally can reach a deployment. Development and test derive theirs from
`databaseName` in `shared/app_constants/project.json`, falling back to the slug
when that key is absent — so a clone that has not set one behaves exactly as it
did before the key existed. `PGDATABASE` and `PGDATABASE_TEST` override either.

That separation is asserted rather than assumed.
`rails/test/lib/database_configuration_test.rb` has a case proving production
and staging resolve to **nothing** when `PGDATABASE` is unset. It is the case
that earns its place: with `PGDATABASE` set, a derived fallback would pass
unnoticed, and a derived fallback there is exactly how staging came to run
silently against production's database.

`databaseName` beats `PROJECT_SLUG`. The more specific key wins, and
`PROJECT_SLUG` steering database names was always a side effect of naming the
project rather than a decision about databases.

**One thing none of this covers.** `Profile::Infrastructure::Storage.db_base`
and `.db_name` derive their own database names from the slug, independently of
`database.yml`, and have no callers anywhere in `app`, `lib`, `config`, `bin` or
`ops`. They are guarded by a test protecting a regression in code nothing runs.
Found and left alone on 2026-09-14: delete or align them deliberately, not
incidentally while doing something else.

## The Environment Is Partitioned By Mutability, And Boot Refuses The Wrong Database

Live since 2026-09-14. Each deployment on the droplet reads two files, in this
order, and nothing else:

- `/etc/default/shengfukung-demo-env` (root-owned, mode 640, group
  `jimmy1768_user`) holds what every checkout of the deployment shares: the
  project slug and origins, secrets, provider keys, and the Postgres host, port
  and user. It carries no per-checkout value, so the shared file alone leaves
  Rails with no database.
- `instance.env` beside each checkout holds only what differs between
  checkouts: `RAILS_ENV`, `RACK_ENV`, `PUMA_PORT`, `PGDATABASE` and
  `S3_OBJECT_PREFIX`. The staging checkout's file is what makes it staging.

The units (`ops/systemd/*.service`) name both files with `EnvironmentFile=`,
shared first, and carry no `Environment=` line and no `ExecStart` prefix, so
there is no precedence to reason about: a forgotten value is absent rather than
silently production's, and absent cannot serve traffic. `bin/staging` carries
no value either; it sources the same two files in the same order and execs.

`DeploymentIdentity` (`rails/lib/deployment_identity.rb`, loaded from
`config/initializers`) refuses to boot production or staging when the database
name resolved by `config/database.yml` is blank or is not the one that
environment expects, and says which file to look in. It reads the name before
anything connects. `bin/staging` states the environment it believes it is
running, and is held to that. The design is recorded in §4a of
`ops/docs/plans/ENV_PARTITION_BY_MUTABILITY_PLAN.md`; the step that proves the
guard by removing a key from staging's `instance.env` was declined by the
Director on 2026-09-14, so the guard has been exercised by every boot since,
not by a deliberate failure.

## Installed Ops Artefacts Drift, In Two Directions

`ops/systemd/*.service` and `ops/nginx/*.conf` are authored here and are inert
until somebody copies them onto the droplet. Nothing reloads them for you and
nothing has ever checked that the copy happened.

    ops/systemd/<name>.service   ->  /etc/systemd/system/<name>.service
    ops/nginx/<name>.conf        ->  /etc/nginx/sites-available/<name>.conf

`bin/check_ops_drift` reports whether each committed artefact matches its
installed copy. Run it **on the droplet**, from a checkout, as the deploy user —
both installed locations are mode 644, so it needs no sudo. It exits non-zero on
any difference, and it only looks: a test scans it for seventeen write verbs and
fails if one appears. Fixing drift is a deploy, which is a different act with a
different approval, and a drift checker that grows a `--fix` flag becomes
`bin/apply_systemd_units` again.

Why it exists, Observed on taiwan-01-web 2026-09-14: both staging units were
missing `S3_OBJECT_PREFIX=staging`, committed here for some time. Staging was
inheriting production's `prod` and writing uploads into production's S3
namespace, and since the two databases are separate a reclamation sweep in
either would have read the other's files as orphans. The nginx configs, checked
the same day, were identical. The problem was never that everything had
drifted — it was that nobody could tell either way.

**It only walks committed → installed, and that is half the problem.** The other
direction is an installed artefact with no committed source, which is worse: a
file running on the host that nobody can review, reproduce or diff against
anything. Observed 2026-09-14, installed 2026-08-04, four of them:

    shengfukung-wenfu-platform-billing-lifecycle.service     + .timer
    shengfukung-wenfu-platform-billing-monthly-close.service + .timer

All four are `static` and `inactive` with no timer scheduled, so they do
nothing today. Nothing in this repository renders them: `ops/systemd/template/`
holds `golden-template-platform-billing-*` originals whose names do not even
match (`monthly-collection` and `monthly-review` against an installed
`monthly-close`), and no rendered copy was ever committed back. They are what
`bin/apply_systemd_units` leaves behind — it renders units from templates
rather than installing the reviewed files, which is what took production down
for five minutes on 2026-08-19.

Since the 2026-09-25 rename these four still carry the old name, and any path
inside them that named the checkout now names a folder that no longer exists —
`~/Projects/shengfukung-wenfu` became `~/Projects/shengfukung-demo`. They are
inactive with no timer scheduled, so nothing fails; they would, if started.

Reverse drift is not built. Until it is, the answer to "what is running on that
host" is the listing, not this check.


## The Test Database Is Disposable, And The Suite Makes and Removes It

`rails/test/test_helper.rb` creates the test database when it is missing, loads
`db/schema.rb`, and removes it again when the run that created it ends. **The
steady state on a machine is that no test database exists between runs.**

Measured 2026-09-14: create and load schema 2.6s, suite 29.4s, drop 0.3s. An
empty Postgres database costs 8.6 MB before a single table exists, and our 64
tables add 5.2 MB of structure holding no rows — which is why 28 abandoned test
databases on this machine came to 377 MB storing nothing. The disk was going on
their existence, not their contents.

**THE BOUND IS THE WHOLE DESIGN: a run removes only what that run created.** A
database that was already there is used and left alone. That is what makes this
safe with no naming scheme and no knowledge of how checkouts are laid out — a
teardown can never land on another checkout's running suite, whatever the two
are called. An earlier attempt built a per-checkout naming scheme to satisfy a
precondition that was never real. Naming is a separate decision and is a
precondition for nothing here.

Properties, each held by a test in
`rails/test/lib/test_database_provisioner_test.rb` rather than by a comment:

- **Test environment only**, guarded first and unconditionally, so nothing is
  created or dropped in development, staging or production under any
  circumstance, including being loaded by accident.
- **Absence only.** Creation triggers on `ActiveRecord::NoDatabaseError` and
  nothing else. Bad credentials or a dead server surface as themselves rather
  than being answered by creating things.
- **Removal is armed in one place**, the branch that has just created the
  database, and is handed the config captured at that moment. There is no call
  path that arms removal for a database the run found.
- **A red or broken run still removes what it made.** `at_exit`, not
  `Minitest.after_run`, because the latter does not cover an exception raised
  while test files are loading. A stray is not the price of a failing suite.
- **Loud, twice.** One line when it makes the database, one when it removes it.
- **A failed removal prints and returns**, naming the exact `dropdb` command,
  rather than raising. Cleanup cannot turn a green run red.
- **Exactly one file may drop a database**, named as `test/test_helper.rb` and
  not as a directory, asserted by a scan over the whole test tree.

**Proving provisioning without touching anything shared:**

    cd rails && PGDATABASE_TEST=<a name that exists nowhere> bin/rails test

**Breaking a guard that runs at suite-load time is destructive during the run
that tests it.** `provision!` is called with real defaults every time
`test_helper` loads, so a break in the created/found distinction fires against
the real configuration and drops the real database — this is how the shared test
database was lost on 2026-09-14, and it was reproduced deliberately afterwards
to confirm it. Pin `PGDATABASE_TEST` to a throwaway before running any break of
this file. That is not a precaution, it is the difference between testing the
guard and executing it.

**Not covered, and left uncovered on purpose:** a hard kill leaves the database
behind, because nothing in-process can catch one. The next run finds it and, by
the bound, leaves it alone. Remove it by hand.

The workspace policy this implements is in `work_mode_config.md`'s Databases
section: a run that creates a test database deletes it in the same run, and how
a repository names its databases is not a work-mode concern. That file carries
the rule; this section is what this repository does about it.

## Mobile/Expo Reference Pattern

`~/Projects/DojoMate-Expo` is the Director's mature, proven Expo/EAS
project — its `app.config.js`/`config/base.cjs` (runtimeVersion,
updates, per-buildMode identity), `eas.json` build profiles, and
`scripts/publish-ota.mjs` / `scripts/check-ota-lane-guardrails.mjs`
patterns are the reference for any Expo/EAS config question on
TempleMate (`mobile/`), not something to work out from scratch against
the Expo docs. **Check it before editing `app.config.js`, `eas.json`, or
any OTA/build script here — don't invent a new shape.**

Real incident, 2026-08-20: `runtimeVersion` was placed one level too
deep in `mobile/app.config.js` (nested under `expo.updates` instead of
a sibling of it) — schema-valid, but silently unread by the actual EAS
build pipeline. A real TestFlight build shipped with no runtime version
embedded at all, structurally unable to ever receive an OTA update,
undetected because the local test suite asserted the wrong (nested)
shape as correct instead of the real one. The same session also
published an OTA update without explicitly setting `BUILD_MODE`, which
silently fell through to the development identity. Both fixed by
matching DojoMate-Expo's actual proven pattern exactly — literal-string
`runtimeVersion` pinned to `versioning.appVersion`, and the OTA script
injecting each lane's `BUILD_MODE` itself rather than trusting the
caller's shell.

## Building the Expo App

Builds are npm scripts in `mobile/package.json`. There is no wrapper:

    npm run build:production    ios, profile production    <- the live lane, from build 4
    npm run build:testflight    ios, profile testflight    <- builds 1-3; served its purpose

The Director moved the live lane to `production` on 2026-09-24: "the testflight
one served its purpose."

**Node is pinned: 24.21.0.** In `mobile/.nvmrc`, and as `node` in every
`mobile/eas.json` build profile. Before 2026-09-24 nothing pinned it, so EAS
chose, invisibly — builds 1 to 3 took the VM image default, Node 20.19.4. Build
4 is the first built on a pinned Node. Local work follows `.nvmrc`; for anything
that must run on Node 20, set it per shell and never relink Homebrew
machine-wide, because operator-kit requires Node 24:

    export PATH="/opt/homebrew/opt/node@20/bin:$PATH" && node -v

**Prove which Node a build used from its log, not from the config.** The
`INSTALL_CUSTOM_TOOLS` phase of a pinned build reads `Installing node v24.21.0 …
Now using node v24.21.0`. An unpinned build's same phase holds only its start and
end markers, and the Node it actually ran is the `- Node.js` line under
`SPIN_UP_BUILDER`. The log is brotli-compressed JSON lines from
`eas build:view <id> --json`, which returns two `logFiles` — and **which index is
the build log is not stable between builds**. Build 3's was index 1, build 4's
was index 0. The wrong file is a valid log with no Node lines in it, which reads
as "unpinned" when it only means "wrong file". Pick by filename: the build log is
the one *without* `-xcode` in its name.

**Runtime 1.0.0 now spans two Node majors, separated by channel.** Runtime
version is the app version, and the Director kept 1.0.0 rather than bumping:

    channel testflight    builds 1-3, Node 20.19.4, ten OTA updates published
    channel production    build 4 onward, Node 24.21.0, no OTA history

The channel is what routes updates, so the two populations cannot exchange them.
**Do not publish the same OTA to both channels** while both Node majors are in
use. That is the only path by which they could still mix, and nothing enforces
it.

**Submitting needs no Apple login.** `eas submit` uses an App Store Connect API
key stored on EAS — Key ID `FUKYXV8BN7`, source "EAS servers". `eas.json`
carries only the app id, so the key is invisible from the repository. It
submits unattended, and it spends the build number the moment it uploads:

    npx eas submit --platform ios --id <build-id> --profile testflight

`--profile testflight` there is the *submit* profile, the only one defined, and
it carries nothing but the app id — the same for both lanes. It does not make the
build a TestFlight-profile build.

`bin/expo_build` and `bin/expo_prebuild` were removed on 2026-09-13. Neither had
ever run -- both used `ruby <<'RUBY' "$MANIFEST_FILE"`, which hands Ruby the
manifest as its script, so they died on line 1 of the YAML before doing
anything. Every real build went through the npm scripts, which is why nobody
noticed and why the wrappers' presets were free to rot: two named profiles that
`eas.json` never defined, and none for `testflight`, the only lane in use.
`DojoMate-Expo`, the reference, has no such wrapper either.

Do not rename `build:testflight` or `build:production`. Control B's permission
profile denies them by exact string; a rename leaves a runnable build command
covered by no deny rule.

**The Android lanes are not configured, and that is the real gap.** Tier 5
above -- Android side-loading for China, where there is no Google Play -- has no
profile and no script. `mobile/eas.json` defines `development`, `testflight` and
`production` only. `DojoMate-Expo` has the shape to copy, Observed 2026-09-13:

    production             distribution store,    android buildType app-bundle
    production-apk         distribution internal, android buildType apk
    production-china-apk   distribution internal, android buildType apk,
                           channel production-china

Note the separate channel on the China build: it is its own OTA population, not
a variant of production. Adding these is a release-lane decision and is the
Director's, not cleanup.

## Client Release Tiers

Five tiers, ordered by how fast a result arrives and how much it means. Speed
and fidelity trade against each other down the list.

1. **Simulator** — iOS, driven by a session directly. Fastest, and the only
   tier a session can exercise without the Director.
2. **Dev client** — Android APK, internal distribution, `development` profile.
   The Director sees results quickly. Android only; there is no dev client for
   his iPhone, which is the whole reason tier 3 exists.
3. **TestFlight** — `testflight` profile, store distribution, `testflight`
   channel. Slower than the dev client, faster than a full rebuild cycle.
   Doubles as the production-conditions check: a real store build against the
   real server, not a staging server. Staff test here. **No customer reaches
   it.** This is where a layout difference between iPhone and everything else
   gets confirmed.
4. **Production** — `production` profile and channel, the live build in
   distribution, iOS and Android.
5. **Production-China** — Android side-loading, because the marketplace is not
   available there. **Not configured**: no build profile, no channel, no
   reference in `eas.json`, `app.config.js` or `versioning.js` as of
   2026-09-12. It is a tier in the Director's plan, not in the repository.

**What each tier skips, and who catches it.** The tiers are a safety net only
if the loop above checks what the loop below never runs. Director's model,
2026-09-12:

| tier | skips | caught by |
| --- | --- | --- |
| dev client | the QR scan, loading and unloading a temple, and the whole release config path | TestFlight |
| TestFlight | native changes, store submission | a new build |
| new build | — | reserved for when the app is stable |

The dev client auto-loads a real temple on a local Rails, named by
`TEMPLEMATE_LOCAL_TENANT_SLUG`, and never shows the scanner. It is a real
tenant row with real data; only the scan is skipped. That is deliberate: the
scan is one feature, and paying for it on every session — running the web
portal, signing in, fetching a code — would tax all the work that has nothing
to do with temples. The cost is that the skipped step is invisible until
TestFlight, which is acceptable because TestFlight is production conditions
anyway.

**Dev and release resolve configuration through different code**
(`releaseConfiguration` returns null outside the release lanes), so a passing
dev run says nothing about whether a release build starts. That is not a
theoretical gap: on 2026-09-12 the boot checks that could have bricked the app
existed only on the release path, and no amount of dev-client running would
have reached them.

TestFlight is production, not staging. It is a separate lane the Director uses
for his own testing; the App Store line is tier 4.

## OTA Reach Is Decided by Version, Not by Build

`runtimeVersion` is pinned to `versioning.appVersion` as a literal string
(`app.config.js`), and it names the **version**, never the build number.
`iosBuildNumber` is a separate field that EAS Update does not consult.

Consequences, and they are not obvious:

- An OTA published for a version reaches **every build carrying that version**.
  Version X build 1 and version X build 2 are one population.
- Incrementing the iOS build number without spending a version number is an
  Apple-side convenience. It separates uploads; it does not separate OTA
  audiences.
- **`release-x.x.x` is the isolation boundary.** Different version lines can
  serve different populations at once — a newer line for the Director, an older
  one for staff, an older one still in distribution — and an OTA on one line
  cannot touch another. That is what the branch is for.

**Director's decision, 2026-09-12: dev and staff are not separated into
different builds.** When an OTA fix is needed, staff are brought onto the same
build as the Director first. TestFlight's group feature would gate who receives
a *build*; it does not gate an OTA, because reach follows `runtimeVersion`.

**OTA carries JavaScript only.** A dependency change requires a rebuild and
cannot ship as an update. The hazard that remains runs one way and needs all
three of: a native module added in a rebuild, the build number bumped without
the version, and later JS that references that module — at which point the
older build receives JS assuming a native layer it does not have. Keeping staff
and Director on one build removes the second condition.

## QA Dummy Admin Account

For debugging real, limited-permission admin behavior on production (menu
visibility, permission gates) without using a real staff member's account:
`ops/docs/reference/qa_dummy_admin_account.md`. Never granted `owner` role
anywhere, so it also proves owner-only gates (Billing) stay blocked, not
just that capability gates work. Local dev/test database work is unrelated
— fabricate throwaway users there freely, same as any other fixture.

## shengfukung.com.tw Is a Demo Temple, Not a Real Client

`shengfukung-demo` (public domain `shengfukung.com.tw`) is used to demo
TempleMate to prospective clients and is deliberately unlocked to create
registrations without paying the platform setup fee — but it is
deliberately excluded from real platform-billing (no statement, delivery,
or charge is ever generated for it). These are two independent
mechanisms, not one flag: `ops/docs/reference/shengfukung_demo_temple_status.md`.
Do not complete a real Stripe setup checkout for it to "fix" anything, and
do not assume unlocked-for-registrations implies real-client, or vice
versa.

**Named `shengfukung-demo` since 2026-09-25.** It was `shengfukung-wenfu`,
which is now reserved for a real temple should one onboard. The rename moved
the temple's record — in place, id 1, registrations kept — its config files,
and the demo deployment's infrastructure: units `shengfukung-demo-*`, checkouts
`~/Projects/shengfukung-demo` and `-staging`, `/var/www/shengfukung-demo`, and
the nginx configs. The repository keeps its own name, and so does the
Director's Mac checkout.

**An env file carries its own slug** (Director, 2026-09-25). The demo's units
load `/etc/default/shengfukung-demo-env`, whose `PROJECT_SLUG` is
`shengfukung-demo`. `/etc/default/shengfukung-wenfu-env` still exists with
`PROJECT_SLUG=shengfukung-wenfu` and is loaded by nothing — reserved, not
stale. Never edit one file's slug to name another temple.

**The slug has two readers with different precedence, and that bit once.**
`AppConstants::Project.slug` reads `ENV["PROJECT_SLUG"]` before `project.json`;
`Profile::Identity.app_codename` reads `project.json` directly. After the record
was renamed but before the demo env file existed, production resolved
`shengfukung-wenfu` through the first and `shengfukung_demo` through the second,
found no temple by name, and served the demo only because the resolver falls
back to the first temple by id. The check at the time verified *what* the API
served, not *how* it found the temple, so it could not fail. **Verify
resolution by route, not by output:** `Temple.find_by(slug:
AppConstants::Project.slug)` must return the temple.

**Seeded accounts kept their emails.** The demo accounts log in as
`@shengfukung-wenfu.local`, locally and on production; the rename changed a
temple record, not user emails. The seeds build addresses from the slug, so
running them again adds `@shengfukung-demo.local` accounts alongside.

**Data migrations run only under `db:migrate`.** A schema load records every
migration up to `schema.rb`'s version as applied without running it, so the
rename migration would have done nothing on any database built from schema.
Never `db:schema:load`, `db:reset` or `db:setup` a live database.

## OperatorKit Copying Boundary

The three-file portable package at `.agents/skills/codex-work-mode` —
`codex_work_mode_skill_package_manifest.yml`, `SKILL.md`, and
`agents/openai.yaml` — is the sole authorized exception to the general
prohibition on copying OperatorKit into this repository. The reason is that
OperatorKit is a separate product with its own kernel semantics: copying its
sources here would create a second, drifting copy of definitions that only
OperatorKit owns. No other OperatorKit source, local path, product/runtime
rule, or repository content may be copied here.

## Safety, Phase, And Product Boundaries

For TempleMate Android development-client work on a USB-connected device,
attach Metro through the exact target-fenced ADB reverse and local
`exp+templemate` URL method established by accepted device evidence. Never
ask the Director to scan a Metro/Expo QR code to attach or log in to Metro.
Temple tenant QR validation is a separate app feature and must be performed
only inside TempleMate through its own `Scan demo QR` / Expo CameraView
surface after the app bundle loads. Do not use the Expo development
launcher's QR scanner or the Pixel's native Camera/QR scanner for that
feature test, and never conflate it with Metro attachment.

Without explicit authorization, do not push, deploy, publish, mutate external
systems, access or rotate secrets, alter accounts, perform destructive
actions, or inspect or change production data. Local or prototype acceptance
does not authorize release promotion.

Deployment, server, DNS, TLS, proxy, Nginx, systemd, queue, cron, production
migration, and production-data work require a separate explicit production
workflow with the exact target, commit, plan, rollback, impact, verification,
approval, and monitoring boundaries.

Payment-provider work is separately gated. Do not access real ECPay
credentials, change merchant configuration, move money, issue real refunds,
or claim legal, accounting, tax, invoice, settlement, or regulatory finality
from local or stubbed evidence.

Keep Rails, Vue, Expo, deployment, temple, account/admin, authority, payment,
and documentation ownership explicit in every assignment and terminal.
Preserve tenant isolation, owner/admin authority, secret handling, payment
and accounting semantics, user-work protections, and the assisted-onboarding
operating model unless an authorized plan explicitly changes them.
