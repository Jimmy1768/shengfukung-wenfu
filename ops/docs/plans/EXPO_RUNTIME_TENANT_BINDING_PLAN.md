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
- **The scan verifies the slug against the backend before loading** (D7). The
  app is signed in when the scanner appears (`App.js:218` gates on `signedIn`,
  `:219` on the tenant), so an authenticated native call carrying
  `temple_slug` verifies it: `native_base_controller.rb:33-37` resolves any
  temple by slug and returns `tenant_not_found` 404. No backend change is
  needed for verification.
- **Loaded, not bound** (D3). The word "bind" in the code is the code's, not
  the Director's; existing identifiers may keep it, new text should not.

## 5. Not in scope

- The `sourcegridlabs.com/templemate/` page itself (D4 says it does not exist).
- Any switchboard or multi-temple UI (D2).
- Stale-temple handling (withdrawn — already solved).
- Renaming the `shengfukung-wenfu` tenant — separate plan.
- Whether this needs a native rebuild, and any AAB sequencing. Not determined
  here; ask.

## 6. Readiness scan — what already works, Observed 2026-09-12

Scanned before planning any work, because most of this exists. Build only what
is missing; everything else is a regression guard.

| # | criterion | now | covered by | missing |
| - | --- | --- | --- | --- |
| 1 | no hardcoded slug | false | — | the four places in §2 |
| 2 | release build starts | true | it is in production | must not break; §2 shows the naive removal throws |
| 3 | scan loads that temple, backend-confirmed | half | `tenant-binding.test.js:29` | the QR carries no slug; the scan confirms the *configured* temple |
| 4 | non-platform origin refused | true, wrong value | `tenant-binding.test.js:13-17` | only the pinned origin changes |
| 5 | unload → scanner → load another | true | `ui-refinement.test.js:95` | **nothing** |

**Criterion 5 is not work.** `App.js:193` clears stored state, `App.js:219`
returns to `TenantSetupGate` when no temple is loaded, and a test already
guards that only the explicit Unbind control forgets it. "A different temple"
fails today solely because of the slug pin — a consequence of 1 and 3, not a
separate feature. Do not build it.

**Criterion 4 is nearly free.** `binding.js:13` already enforces exact origin,
https only, no credentials, no fragment. Only the value it compares against
moves. Two of the existing assertions already prove a foreign origin and plain
`http` are refused.

**Criterion 3 is the work**, and the existing test names the property that must
survive: *"The QR code's claim about which temple it is never wins; the server
does."* That stays true — the QR carries a slug, the backend confirms it, and a
slug the backend rejects does not load. Same guarantee, new input.

**`verify-release-interface.js:5` hard-asserts
`TEMPLEMATE_PUBLIC_TENANT_SLUG === 'shengfukung-wenfu'`** for both lanes. It
fails the moment the slug leaves `eas.json`, so it is part of the change rather
than collateral.

## 7. Done criteria

BUILD:

1. No hardcoded tenant slug in `mobile/` — the three places in §2 — and
   `app.config.js:115` still resolves local development. (D1, D3)
2. Scanning a temple's QR in the app loads that temple, after the backend
   confirms the slug. (D6, D7)

GUARD — already true, must remain true:

3. A release build starts. (D3; §2 shows why this is not automatic)
4. A payload from any origin other than `sourcegridlabs.com` is refused. (D5)
5. Unload returns to the scanner, and a different temple can then be loaded.
   (D2, D6)

## 8. Files — Observed

    mobile/app.config.js              the slug, and the local-dev slug
    mobile/app/real/config.js         PUBLIC_TENANT, boot throws
    mobile/app/real/adapter.js        boot throw, sends temple_slug
    mobile/app/tenant/binding.js      the payload format
    mobile/app/tenant/scanner.js      scan then verify
    mobile/app/tenant/storage.js      key namespace derives from the slug
    mobile/eas.json                   TEMPLEMATE_PUBLIC_TENANT_SLUG
    mobile/scripts/verify-release-interface.js   enforces that env value
    mobile/__tests__/tenant-binding.test.js
    mobile/__tests__/camera-session.test.js
    mobile/__tests__/real-adapter.test.js
    mobile/__tests__/native-config.test.js
    rails/app/services/templemate/connection_link.rb
    rails/app/controllers/account/connections_controller.rb
    rails/test/integration/account/connect_qr_test.rb
