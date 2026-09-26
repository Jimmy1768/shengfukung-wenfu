# TEMPLEMATE REFINE LEDGER

> The `ops/docs/handoffs/` files linked below were deleted in 102ecda; recover them from git history.

## Purpose

- Running ledger for TempleMate (mobile) refinements discovered during
  real-device/TestFlight QA.
- Keep this file focused on the mobile app and its production
  dependencies, not Rails/Vue web work (that's `ACCOUNT_PORTAL_REFINE.md`
  / `ADMIN_PORTAL_REFINE.md`).

## Workflow

Two categories, fixed differently — iOS has no dev-client, so this
distinction matters:

- **Local-fixable**: application-code bugs, testable against a local/dev
  backend via Android dev-client (the real 95% iteration loop) before
  ever spending a TestFlight build.
- **Production-side**: bugs that live in production environment/
  deployment state itself, not in this repo's application code. Can't be
  reproduced via dev-client (which talks to local/dev, not production) —
  can only be validated by pushing an actual signed build to TestFlight
  and testing against the real deployed backend.

Build numbering: version stays `1.0.0`, build number increments per
TestFlight upload without touching the marketing version — next build
is **build 2**.

## Active Items

### Production-Side

- [x] `/api/v1/*` namespace missing on `shengfukung.com.tw` production —
      every native-API route 404s (native OAuth start, bootstrap, login,
      temples, theme), while the older `/auth/central/*` web OAuth path
      is live and healthy. Blocks all native sign-in/login/bootstrap/
      registration on the real build. Not a code defect in this repo —
      a production deployment gap. Full diagnosis:
      `ops/docs/handoffs/2026-08-19-production-native-api-namespace-missing-finding-control-b.md`.
      **Root-cause hypothesis (read-only investigation, no production
      access): production's Rails checkout is simply stale**, predating
      the native OAuth routes commit (`7fa60f0`, 2026-08-11) — no
      automated deploy pipeline exists anywhere in the repo, so this is
      an ordinary manual-deploy gap, not a config/proxy defect. nginx
      confirmed correctly proxying `/api` behaviorally. Full evidence:
      `ops/docs/handoffs/2026-08-19-production-native-api-namespace-hypothesis-control-b.md`.
      Actual deploy action still needs its own separately authorized
      production workflow — pending Director decision on whether they
      do it directly (no pipeline exists, may need to be them regardless)
      or authorize a scoped packet.
      **Fixed 2026-08-19**: Director deployed directly (`release/current`
      advanced to `main`, `bundle install`, both pending migrations run,
      services restarted). Verified via `curl` — the namespace now
      returns `422` (real auth rejection) instead of `404` (route
      missing). Full record:
      `ops/docs/handoffs/2026-08-19-production-native-api-namespace-deploy-fix.md`.
      Remaining validation: real Google/Apple sign-in on the installed
      TestFlight build.

- [x] `AUTH_NATIVE_RETURN_URL` missing from production env — fixed
      2026-08-19, added to `/etc/default/shengfukung-wenfu-env`, Puma
      restarted. Full trace:
      `ops/docs/handoffs/2026-08-19-native-oauth-full-trace-confirmed-blocker.md`.

- [x] `templemate://oauth/complete` not registered with the central
      auth service (`auth.sourcegridlabs.com`) for the `shengfukung`
      tenant — confirmed live via a direct probe (`422
      invalid_return_url`), fixed 2026-08-19 by Codex SourceGrid
      Planning (additive, independently re-verified). Full record:
      `ops/docs/plans/CENTRAL_AUTH_TENANT_REGISTRATION_PLAN.md` (deleted 2026-09-26; the
      blocker cleared, recorded in `reference/templemate_native_oauth.md`).

- [ ] **New finding, 2026-08-19 — first real sign-in succeeded (Apple:
      dialogue, account selection, FaceID, all successful) but the app
      never leaves the sign-in screen.** Root cause identified directly:
      `oauth/start` returns `201`, but `oauth/exchange` returns `503`.
      Traced to `Auth::OAuthIdentityResolver#resolve_or_link!`
      (`rails/app/services/auth/oauth_identity_resolver.rb`) — it has
      **no path that creates a new account**. Any identity that isn't an
      exact existing `OAuthIdentity` match (or the narrow Google-subject-
      replacement edge case) raises `UnmatchedIdentity`, which routes to
      `Auth::OAuthAccountResolution.create!` — gated behind the
      `oauth_account_resolution` feature flag, currently off in
      production. This means **no genuinely new identity has ever been
      able to sign up via native OAuth**, regardless of provider — not
      specific to this test.
      Turning the flag on would not by itself fix this: the web side has
      a real, complete resolution flow
      (`rails/app/controllers/account/oauth_resolutions_controller.rb`,
      `consume_new!`/`consume_existing!`), but the **native side has no
      equivalent** — grepped the entire mobile app for
      `resolution_token`/`account_resolution_required`, zero matches.
      The backend would correctly return `409` with a resolution token;
      the app has no code to recognize or act on it, and would just show
      a generic failure.
      Confirmed **not** a general "can't create accounts" gap — native
      email/password signup (`NativeSessionsController#signup` via
      `Account::RegistrationForm`) is a fully separate code path,
      untouched by the OAuth resolver or the feature flag. Code-level
      confirmed only, not live-tested end-to-end.
      **Dispatched 2026-08-19**: Control A — further diagnostics (why the
      flag is off, whether a native resolution-consuming endpoint needs
      building or already exists somewhere unfound, whether native
      email/password signup actually works live). Control B — build the
      missing native-side flow (screen + state handling for
      `account_resolution_required`), once Control A's endpoint findings
      land.
      **Control A's diagnostics landed 2026-08-19** (`c469de4`,
      `ops/docs/handoffs/2026-08-19-oauth-account-resolution-diagnostics-control-a.md`):
      flag confirmed never turned on, no consuming endpoint on either
      side, and a concrete contract scoped —
      `POST oauth/resolution/existing|new`, login-shaped response,
      `surface: "native"` already valid in the model. Real local runtime
      proof (fenced disposable DB) confirms native email/password signup
      itself works end-to-end; production account creation was correctly
      declined regardless of dispatch wording.
      **Control B built the mobile side 2026-08-19** (`2c0da17`,
      `df60cba`): new `account_resolution` phase in
      `app/oauth/transaction.js`, resolution screen in `App.js` (link-
      existing / create-new, mirroring the web controller's fields
      exactly), `consumeOAuthResolution` in `app/real/adapter.js` wired
      to the confirmed contract via the existing `authenticate()` helper.
      68/68 tests (5 new), lint, verify all green.
      Branch-naming collision from this dispatch fixed in
      `ops/protocol/claude_work_mode.md` (`9842512`) — Planning's own
      mistake, reusing Control B's existing branch name for Control A's
      separate packet; no data lost, Control B's commits landed on
      `main` directly instead of through its normal flow as the one
      symptom.
      **Rails side built and merged 2026-08-20** (`2290df3`,
      `ops/docs/handoffs/2026-08-20-native-oauth-account-resolution-endpoints-control-a.md`):
      `Api::V1::Account::NativeOAuthResolutionsController`, all three
      routes, round-trip tests drive a real `409` through the actual
      exchange endpoint and verify real DB state + a genuine working
      access token. 542/3421 full suite, independently re-verified. The
      whole chain — detection, phase, screen, both submit paths,
      consuming endpoints — is now complete and reachable, for Apple.
      **Real bug found, not fixed yet**: Google-specific account
      resolution is broken end-to-end (web and native both) — a
      provider-string mismatch (`OAuthAccountResolution` stores
      `"google_oauth2"`, both clients hand back canonical `"google"`,
      `validate_record!` always fails the comparison). Apple/Facebook
      unaffected (identity-form and canonical strings are identical for
      both). Not live-impacting today since the feature flag is still
      off, but the flag is a single global toggle — turning it on for
      Apple testing turns it on for Google too.
      **Fixed 2026-08-20** (`bcf8131`,
      `ops/docs/handoffs/2026-08-20-oauth-google-provider-mismatch-fix-control-a.md`):
      canonicalized both sides of the comparison rather than just the
      stored side — a one-sided fix would have silently broken Google
      consolidation the same way (a third caller intentionally passes
      identity-form). New regression tests use Google specifically and
      assert storage stayed identity-form. Chain is now correct for
      Google, Apple, and Facebook alike, still gated behind the
      still-off feature flag.
      Also found, not fixed, deferred like the env-file rename: shared
      local test-database contention traced to `rails/config/database.yml`
      defaulting `PGDATABASE_TEST` to the literal unparameterized
      `golden_template_test` — same pattern as today's other unrendered-
      template-default findings. Not urgent; fenced disposable databases
      already avoid the actual risk in every packet.
      OTA note: Control B correctly declined to publish
      `yarn ota:testflight` off Planning's relayed "Director confirmed"
      framing — held the direct-authorization rule even against a
      literal quote, and separately noted publishing now would ship
      client code pointing at 404s regardless. Correct on both the
      process and the merits; that conversation happens with the
      Director directly once this is fully tested end-to-end.

      **Production deployed and OTA-blocked, 2026-08-20** (Director
      confirmed directly, in-session): backend redeployed to `main`
      (`ead42e2`), `oauth_account_resolution` flag turned on in
      production, both verified live. Mobile side hit two real bugs on
      the first actual OTA publish — `runtimeVersion` was silently
      unread by the EAS build pipeline (nested one level too deep) and
      the publish script didn't set `BUILD_MODE` (first publish shipped
      dev identity under the testflight channel). Both root-caused to
      `mobile/`'s Expo/EAS config having diverged from
      `~/Projects/DojoMate-Expo`'s proven pattern instead of following
      it; fixed to match it exactly, with guardrail tests added so
      either regressing is loud, not silent. Full record:
      `ops/docs/handoffs/2026-08-20-ota-runtimeversion-buildmode-fix-planning.md`.
      **Hard blocker found and cleared, 2026-08-20**: the already-
      installed TestFlight binary (build 1, `9f36c64`, 2026-08-19)
      predated the config fix and had no runtime version embedded at
      all — confirmed by unzipping the real `.ipa`. A third instance of
      the same fail-unsafe-default bug also surfaced live via `eas
      submit` (bundle identifier resolved to `.dev` for a `--profile
      testflight` submit); fixed at the shared resolution logic, not
      patched per call site. Director authorized and completed: new
      build (`2a7dee90`, iOS build number 2, version 1.0.0 unchanged),
      verified `EXUpdatesRuntimeVersion => "1.0.0"` actually embedded
      this time, submitted to App Store Connect and processing. Full
      record:
      `ops/docs/handoffs/2026-08-20-ota-runtimeversion-buildmode-fix-planning.md`.
      Remaining: install build 2 via TestFlight, relaunch twice for the
      already-published OTA update to apply, then the QA checklist
      items below.

### Local-Fixable

- [x] Dev/demo copy strings (sign-in headline, loading text, QR-scan
      copy, account-closure text) unconditionally showing even in
      `isReleaseConfig()`-true production builds, despite the repo
      already having the right gate for this pattern applied to
      behavior elsewhere. Control B fixing independently, own branch,
      no Rails/deployment overlap — found and handled same session as
      the production-API finding above.

## QA Checklist

- [x] Apple sign-in reaches the real central-auth exchange on a real
      TestFlight build against production (2026-08-19) — first time
      ever. Blocked next by the account-resolution gap above, not by
      anything already fixed.
- [ ] Google sign-in succeeds end-to-end on a real TestFlight build
      against production.
- [ ] A genuinely new identity (Google or Apple) can complete signup on
      native and land in the app.
- [ ] No dev/demo copy visible in a release-config build.
