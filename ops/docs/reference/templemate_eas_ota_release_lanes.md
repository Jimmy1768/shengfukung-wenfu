# TempleMate EAS build and update lanes

This source contract defines `testflight` and `production` as distinct, app-version runtime lanes for TempleMate. Both use the public origin `https://shengfukung.com.tw`. Neither carries a tenant: the app is built with no temple, the camera scans a temple's QR code, and the slug it resolves is kept in async storage.

**`testflight` is a live EAS Update channel** (Director, 2026-08-31): iOS build 1 was uploaded, distributed, and installed by staff, and simple JS changes reach that lane as an OTA update rather than a rebuild. Native config, native dependency, and `runtimeVersion` changes still require a build. `production` remains reserved and unexercised.

## Which git branch an OTA publishes from (Director, 2026-09-03)

**Never `main`.** An OTA only reaches builds whose `runtimeVersion` matches, and
`runtimeVersion` is pinned to `versioning.appVersion`. So the git source for a
publish must be a branch pinned to that same version, or a later change on
`main` -- a version bump, a native dependency, anything -- can be published at
an app version it was never built for.

- **`release-1.0.0`** is the source for every OTA aimed at 1.0.0 builds. It
  matches what is distributed through App Store Connect and Google Play.
- **`main`** is where implementation branches merge and patching continues.
  What is safe for a shipped version is merged into that version's release
  branch; what is not stays on `main` until the next build.
- A release branch is kept until every user has migrated off that version, not
  deleted when the next one ships. Users on old builds still receive OTAs from
  their own branch.

At the time of writing iOS is at build 1 of `1.0.0`; no Android AAB has been
produced, so Android is version 1 with nothing distributed.

**Not to be confused with `release/current`**, which is the droplet's web deploy
ref and has nothing to do with the app. Different artefact, different lifecycle.

This file describes the lane contract only. It is not a receipt: what has actually been built, uploaded, or published is tracked in `ops/docs/reference/templemate_release_receipts.md`.

The routine iteration lane is neither of these — it is the Android dev-client APK (`development` profile: internal distribution, `buildType: apk`, no channel) with JS served by `yarn dev-client`. Promote to iOS only for a production test.

`yarn build:testflight` and `yarn build:production` are cloud-build entry points requiring later Director authority. `yarn ota:testflight <message>` and `yarn ota:production <message> production` are guarded wrappers. They fail before EAS invocation without a clean attributed release source, accepted receipt, release environment, lane/message, and production scope token. Rollback is a separately authorized republish/reconciliation operation.

No values for signing, Apple, provider registration, privacy/support/deletion URLs, or EAS environments are stored here.
