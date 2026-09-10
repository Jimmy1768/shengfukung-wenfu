# Shengfukung Wenfu — Repo Context

Product/runtime and builder-procedure context for this repository only. It does
not apply to any other repository and is not copied into another. `CLAUDE.md`
and `ops/protocol/claude_work_mode.md` are identical everywhere; everything
that is true here and nowhere else belongs in this file.

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

The work mode's Control A/B are hand-agnostic by default — packet owns the
branch, either hand can pick one up. This repository keeps them specialized by
domain instead, inherited from how the work has actually run:

- **Control A** owns Rails / account / admin / offering-data work.
- **Control B** owns TempleMate / EAS / TestFlight / OTA / native OAuth /
  mobile work.
- The two stay independent; cross-track coordination routes through
  Planning, not Control-to-Control.

This is an operating convention for this repository, not a work-mode rule.
Wenfu keeps the split because the domain division is already real, and each
Control's accumulated context stays more useful when it is focused.

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
and documentation ownership explicit in every bounded packet and return.
Preserve tenant isolation, owner/admin authority, secret handling, payment
and accounting semantics, user-work protections, and the assisted-onboarding
operating model unless an authorized plan explicitly changes them.
