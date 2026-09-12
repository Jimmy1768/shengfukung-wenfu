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

`shengfukung-wenfu` (public domain `shengfukung.com.tw`) is used to demo
TempleMate to prospective clients and is deliberately unlocked to create
registrations without paying the platform setup fee — but it is
deliberately excluded from real platform-billing (no statement, delivery,
or charge is ever generated for it). These are two independent
mechanisms, not one flag: `ops/docs/reference/shengfukung_demo_temple_status.md`.
Do not complete a real Stripe setup checkout for it to "fix" anything, and
do not assume unlocked-for-registrations implies real-client, or vice
versa.

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
