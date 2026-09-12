# EXPO RUNTIME TENANT BINDING PLAN

## Purpose

Remove the hardcoded tenant from the Expo release configuration so one build
serves every temple. A patron scans their temple's QR, the app binds to that
temple, and can unbind. Load, unload — one temple at a time, decided at
runtime rather than at build time.

## Why this is not a naming problem

This surfaced while deciding whether to rename the `shengfukung-wenfu` tenant
slug. It is a separate and larger issue: whatever the demo tenant is called, a
build-time tenant blocks the second client either way. The naming decision does
not depend on this and should not wait for it.

## Current state — Observed 2026-09-12

`mobile/app.config.js:30`, inside `releaseConfiguration`:

```
apiBaseUrl: 'https://shengfukung.com.tw',
tenantSlug: 'shengfukung-wenfu',
```

The release build is pinned to one temple in three layers, and the first two
run before the slug is ever compared:

1. `app/tenant/scanner.js` — `parseProductionConnectionLink(payload,
   config.apiBaseUrl)` requires the QR link to come from the configured origin.
2. The scanner then fetches `${config.apiBaseUrl}/api/v1/temple` — it asks the
   configured origin which temple *it* is, not the temple the QR names.
3. `temple.slug !== config.tenantSlug` → `binding_failed`.

The file's own comment states the design: *"The link must come from the
configured origin, and the temple it names must be the configured tenant."*

Consequences:

- A second temple's QR fails at step 1. In a release build there is no runtime
  path to any tenant but this one.
- The scan does not discover a temple. It confirms the one the build already
  knew.
- `app/tenant/storage.js:10` refuses a retained binding whose id is not the
  configured slug, and `app/real/adapter.js:6` sends that slug as `temple_slug`
  on every request.

This contradicts `ops/protocol/repo_context.md`, which records Rails and
TempleMate as shared single deployments serving every temple, with only Vue
being per-client. The document describes the intended app; the code is the
app that exists.

## The backend needs nothing — Observed

`TempleContextResolver` (`app/services/temple_context_resolver.rb:73`) takes
`params[:temple_slug]` as its first resolution candidate, ahead of session and
the project default. `GET /api/v1/temple?temple_slug=<slug>` already answers
for an arbitrary temple. The server is already the authority on which temples
exist. The client throws that away by asking the origin who it is.

**The pin is client-side only.**

## A list of accepted tenants is not the fix

Any list is stale the moment a client signs up, and staleness means a rebuild
per temple — the same defect with more entries. One hardcoded slug is a list of
one. The app must not know which tenants exist.

## What changes

- **`apiBaseUrl` stays.** It is the platform's identity, not a tenant's: one
  shared backend serves every temple, and pinning it is what stops a hostile QR
  pointing the app at another server. This is a security property, not an
  oversight.
- **`tenantSlug` is removed** from `releaseConfiguration`. Which temple an
  install belongs to is runtime state.
- **`scanner.js`** fetches the temple the QR names, at the configured origin,
  and binds if the server confirms it.
- **`storage.js` and `adapter.js`** read the bound tenant from stored state
  rather than from config.

One temple at a time remains the rule. It becomes a session rule rather than a
compile rule; the current code conflates the two.

## Out of scope

- Renaming the `shengfukung-wenfu` tenant slug. Separate decision.
- Any temple switchboard or multi-temple UI. Load and unload, one at a time.
- Backend changes. None are required.

## Sequencing — this gates the Android build

Do this **before** cutting the first AAB.

Android `versionCode` must increase with every upload to Play, so each build
spends a number permanently. iOS is cheaper: the same `version` can carry many
`buildNumber` increments. `mobile/versioning.js` currently holds
`appVersion: '1.0.0'`, `iosBuildNumber: '2'`, `androidVersionCode: 1`.

Shipping the fix first means the first Android build is already correct and no
`versionCode` is spent on a build that cannot onboard a client.

This is a native config change, so it needs a rebuild and a new build number
rather than an OTA — see `ops/protocol/repo_context.md`, "OTA Reach Is Decided
by Version, Not by Build".

## Done criteria

- No tenant slug appears anywhere in `mobile/app.config.js`.
- A release build binds to a temple named by a QR it has never been told about,
  confirmed against the server.
- A QR from an origin other than the configured one is still refused.
- Unbind returns the app to an unbound state that can bind to a different
  temple.
- Onboarding a temple requires no app build, no submission, and no version bump.
