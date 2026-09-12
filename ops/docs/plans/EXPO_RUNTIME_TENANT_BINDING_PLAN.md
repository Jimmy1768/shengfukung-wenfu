# EXPO RUNTIME TENANT PLAN

## 0. Source — the Director's words, 2026-09-12

Everything below derives from these and cites them. Nothing else is a
requirement.

- **D1** "we can't hardcode one tenant to the expo app. it's one expo app for
  all tenants."
- **D2** "the user, scans a QR code for ONE temple, and the app loads in that
  one slug only. no 2 temple loading, no temple switchboard. Load. Unload.
  that's it."
- **D3** "there is not bind. the QR code scan loads in the temple. this already
  works. we're removing hard code slug from app.config.js."
- **D4** "scanning with native camera can go to the TempleMate page. it doesn't
  exist yet. but it will be sourcegridlabs.com/templemate/"
- **D5** "we should protect from hostile source."
- **D6** "the qr code scanned using the app, needs to resolve the temple slug,
  and load it. keep it simple."
- **D7** "verify the slug against backend, use path segment"

- **D8** "no, signing does not require a temple. we designed 2 'gates' on
  purpose. signing in with no temple, only shows the scanner page."
- **D9** "not only first-time patron will be temple-less. a user can unload a
  temple at anytime. then scan another temple." Temple-less is a steady state.
- **D10** "Oauth vs email is the wrong framing. We write the app so it can log
  in. This is not hard. if there's no temple slug, it goes to the scanner
  screen. don't overly complicate it. we're massively simplifying the app. it's
  the easier direction."
- **D11** "8-11, what i wanted was created. there's a few defects. dummy vs real
  client, and slug became hardcoded. we need to fix these 2 defects."

Withdrawn by the Director: any stale-binding behaviour. "a temple is loaded in,
and is saved in async storage. it persists after reload of the app, and sign
out as well." Already solved; not in scope.

## 1. The gap — Observed

The QR encodes `https://shengfukung.com.tw/connect/templemate/v1` and nothing
else. `ConnectionLink.for(request:)` takes only the request
(`connection_link.rb:25-27`); `binding.js:15` rejects any query but `v=1`.

The page already knows the temple. `Account::ConnectionsController` is behind
`Account::BaseController`, whose `@active_temple_slug` comes from the session
(`base_controller.rb:56`), and the view prints `current_temple.name` three
times. The controller's own comment says it "hands the app the temple
identity" — it does not. The slug is in hand and never reaches the link.

Nothing resolves a temple from the host: no `request.host` in `app/`, and the
manifest's `domains:` feeds nothing. `/connect/templemate/v1` is not a route —
only `/connect` exists — so the QR points at a 404 today.

## 2. The slug is hardcoded in four places — Observed

    mobile/app.config.js:30      tenantSlug: 'shengfukung-wenfu'
    mobile/app/real/config.js:4  PUBLIC_TENANT = 'shengfukung-wenfu'
    mobile/eas.json:27,40        TEMPLEMATE_PUBLIC_TENANT_SLUG

`mobile/app.config.js:115` is the local-development slug
(`TEMPLEMATE_LOCAL_TENANT_SLUG`) and must survive.

**Removing only `app.config.js:30` makes every release build fail at boot.**
`real/config.js:15` throws `REAL_CONFIG_REQUIRED` on an empty `tenantSlug`;
`:24-25` require `tenantSlug === PUBLIC_TENANT` for a release origin and throw
`TRUSTED_API_REQUIRED` otherwise; `adapter.js:14` throws without it. The app
would reach BootFailure before a scanner is shown.

## 3. The new QR payload — D4, D5, D6, D7

    https://sourcegridlabs.com/templemate/connect/<temple-slug>

- Native camera lands on the TempleMate page (D4). That page does not exist
  yet; building it is not this work.
- The app requires the origin to be `sourcegridlabs.com` and rejects anything
  else (D5). This moves the trust anchor from a tenant's domain to the
  platform's, which is what stays constant across clients.
- The slug is a path segment (D7).

## 4. What changes

- **The slug leaves the app** (D1, D3): `app.config.js:30`,
  `real/config.js:4`, `eas.json:27,40`, and the boot requirements at
  `real/config.js:15,24-25` and `adapter.js:14` that assume it — because the
  app must still start (D3: the scan already works).
- **`apiBaseUrl` stays pinned** to the shared backend. It is not a tenant
  value; every temple is served by one Rails deployment.
- **`binding.js`** parses the new payload: origin `sourcegridlabs.com`, path
  `/templemate/connect/<slug>`, returns the slug (D6, D7).
- **`ConnectionLink`** emits the new payload, taking the temple it already has
  (D6).
- **The scan verifies the slug against the backend before loading** (D7).
- **Loaded, not bound** (D3). The word "bind" in the code is the code's, not
  the Director's; existing identifiers may keep it, new text should not.

Added 2026-09-12, after the first attempt shipped a branch that could not sign
in. All three are removals.

- **Sign-in never touches a temple** (D8, D10). The session routes are already
  temple-optional. OAuth is not: `native_oauth_flow.rb:26` passes
  `temple_slug: @temple.slug` into the transaction and `:121` falls back to it
  for `central_tenant_slug`, so a temple-less start raises `NoMethodError`
  through a rescue list that does not cover it. OAuth credentials are
  per-deployment ENV values — `AUTH_BASE_URL`, `AUTH_CLIENT_ID`,
  `AUTH_CLIENT_SECRET`, and each provider's pair
  (`app_constants/oauth.rb:30,47`)
  — so nothing about signing in varies by temple. The temple comes out. This is
  not a platform-tenant concept; `ENV["AUTH_TENANT_SLUG"]` already exists.
- **Nothing temple-scoped runs without a temple** (D8). `loadBootstrap()` is
  called unconditionally at `adapter.js:55` (`authenticate`, covering sign-in
  and password reset), `:68` (`exchangeOAuth`), and `:88` (`restoreSession`,
  which wipes the stored session before rethrowing). `loadCollections()` — six
  temple-scoped requests — runs the same way from `completeSignIn`
  (`App.js:158-171`) and startup (`App.js:119`). Bootstrap stays temple-required
  on the server: every line of `native_bootstrap_controller.rb:11-14` is
  temple-scoped, and `native_temple_delinquent?`
  (`native_base_controller.rb:22`)
  dereferences the temple unguarded.
- **One code path, not two** (D11). `isReleaseConfig()` is the surviving half of
  the dummy-client switch removed in `ae82ad6`, and it selects behaviour, not
  wording: binding persistence exists only in release
  (`tenant/storage.js:7,18`),
  and the temple's identity comes from `boundTenant` (`App.js:91`) in
  development but from storage in release. That fence is why criterion 2 fails —
  the code that names a temple after loading it sits on the side a release build
  never runs. Deleting the switch brings that behaviour to the one path, and
  forces choosing one string from each `demo`/`...Release` pair in `copy.js`.

## 5. Not in scope

- The `sourcegridlabs.com/templemate/` page itself (D4 says it does not exist).
- Any switchboard or multi-temple UI (D2).
- Stale-temple handling (withdrawn — already solved).
- Renaming the `shengfukung-wenfu` tenant — separate plan.
- Whether this needs a native rebuild, and any AAB sequencing. Ask.
- The rest of the `ae82ad6` vocabulary: `clientMode` in `app.config.js` and
  `eas.json`, the `verify-*` scripts that assert it, unimported dummy-era
  modules, and copy belonging to removed flows. Only what deleting
  `isReleaseConfig` forces is in scope here.
- **The token-refresh defect.** Nothing calls `adapter.refresh()`; the only
  caller is a test. `JWT_ACCESS_TTL` defaults to 15 minutes and is set nowhere
  in the repository, and a 401 clears retained state. A session cannot outlive
  its access token. Reported to the Director 2026-09-12; it predates both
  defects and affects production now. Not this assignment.

## 6. Readiness scan — Observed 2026-09-12

Scanned before planning any work, because most of this exists. Build only what
is missing; everything else is a regression guard.

| # | criterion | now | covered by | missing |
| - | --- | --- | --- | --- |
| 1 | no hardcoded slug | false | — | the four places in §2 |
| 2 | scan loads that temple, backend-confirmed | false | `tenant-binding.test.js:29` | the load itself — see below |
| 3 | release build starts | true | it is in production | must not break |
| 4 | non-platform origin refused | true, wrong value | `tenant-binding.test.js:13-17` | only the pinned origin changes |
| 5 | unload → scanner → load another | true | `ui-refinement.test.js:95` | **nothing** |
| 6 | temple-less sign-in reaches the scanner | false | — | §4, all three removals |

**Row 2 was recorded "half" on 2026-09-12 and was wrong.** The scan confirms a
slug; it does not load a temple. `onCameraResult` (`App.js:228`) saves the
binding and calls `setData(adapter.snapshot())` — the snapshot as it already
was. No bootstrap, no collections. On `main` the compiled tenant hid this: both
had already run at sign-in. Corrected after Recovery's ADVICE of 2026-09-12,
verified here.

**Criterion 5 is not work.** `App.js:193` clears stored state and `App.js:219`
returns to the scanner. Do not build it.

**Criterion 4 is nearly free.** `binding.js:13` already enforces exact origin,
https only, no credentials, no fragment. Only the compared value moves.

**`verify-release-interface.js:5` hard-asserts
`TEMPLEMATE_PUBLIC_TENANT_SLUG === 'shengfukung-wenfu'`** for both lanes. It
fails the moment the slug leaves `eas.json`, so it is part of the change.

## 7. Done criteria

Numbers are stable identifiers, not an order. 1, 2, 6 and 7 are BUILD; 3, 4 and
5 are GUARD — already true, and must remain true.

1. No hardcoded tenant slug in `mobile/` — the places in §2 — and
   `app.config.js:115` still resolves local development. (D1, D3)
2. Scanning a temple's QR loads that temple — its name, its collections —
   after the backend confirms the slug. (D6, D7)
3. A release build starts. (D3)
4. A payload from any origin other than `sourcegridlabs.com` is refused. (D5)
5. Unload returns to the scanner, and a different temple can then be loaded.
   (D2, D6)
6. A patron with no temple loaded signs in by email, by Google and by Apple,
   and lands on the scanner with no error banner. (D8, D9, D10)
7. `isReleaseConfig` is gone, and one path serves every build. (D11)

**A fixture that cannot fail does not satisfy any of these.** Three checks have
now passed for the wrong reason on this work: the mobile `/bootstrap` fixture
answered success regardless of `temple_slug`; a Rails test asserted the very
`tenant_required` that breaks criterion 6; and the branch's OAuth-start test
stops one line before the dereference, on an unset env var. The adapter fixture
must answer `tenant_required` 422 with no slug, and `tenant_not_found` 404 for
an unknown one, on every path outside the session set.

## 8. Files — Observed

    mobile/App.js                     the gates, the scan, the loads
    mobile/app.config.js              the slug, and the local-dev slug
    mobile/app/real/config.js         PUBLIC_TENANT, boot, isReleaseConfig
    mobile/app/real/adapter.js        boot, temple_slug, bootstrap calls
    mobile/app/tenant/binding.js      the payload format
    mobile/app/tenant/scanner.js      scan then verify
    mobile/app/tenant/storage.js      key namespace derives from the slug
    mobile/app/ui/copy.js             the demo/Release pairs
    mobile/eas.json                   TEMPLEMATE_PUBLIC_TENANT_SLUG
    mobile/scripts/verify-release-interface.js   enforces that env value
    mobile/__tests__/tenant-binding.test.js
    mobile/__tests__/camera-session.test.js
    mobile/__tests__/real-adapter.test.js
    mobile/__tests__/native-config.test.js
    mobile/__tests__/ui-refinement.test.js       pins the demo phrases
    rails/app/services/auth/native_oauth_flow.rb          the temple in the flow
    rails/app/services/auth/native_oauth_transaction.rb  temple in the token
    rails/app/services/templemate/connection_link.rb
    rails/app/controllers/account/connections_controller.rb
    rails/test/integration/account/connect_qr_test.rb
    rails/test/integration/account/api/native_sessions_test.rb
