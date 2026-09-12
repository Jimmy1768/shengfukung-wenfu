# EXPO DUMMY-CLIENT RESIDUE AND DOWNLINE PLAN

Capture only. Nothing here is assigned, and nothing here is to be started
without the Director. It exists so these findings stop being re-raised in
conversation one at a time.

## 0. Why this exists

The Director's framing, 2026-09-12: "8-11, what i wanted was created. there's a
few defects. dummy vs real client, and slug became hardcoded. we need to fix
these 2 defects."

Defect 2 (the hardcoded slug) is assigned —
`EXPO_RUNTIME_TENANT_BINDING_PLAN.md`,
assignment 012. Defect 1 is not. This file holds defect 1's residue and
everything found downline of both that assignment 012 does not cover.

A dummy client was added on 2026-08-11 (`0263b0a`) and removed on 2026-09-04
(`ae82ad6`, "remove the dummy client, leaving one mode and one binding"). The
removal was incomplete. The plan the Director approved
(`406a349^:ops/docs/plans/archive/`
`EXPO_DUMMY_ACCOUNT_DEVELOPMENT_CLIENT_PLAN.md`)
is titled "Dummy Account … Development Client" and never uses the phrase "dummy
client"; the phrase enters the repository the same day in docs commits `6a03bca`
and `dae088b`. That plan does carry a "Dummy-Mode Boundary" section, so a mode
switch traces to a document; the Director's account of what he asked for is the
authority and the two have not been reconciled.

## 1. Not in scope — assignment 012 already covers it

- Deleting `isReleaseConfig` and collapsing to one code path.
- Whatever `copy.js` string pairs that deletion forces a choice on.
- The three `loadBootstrap()` calls and `loadCollections()`.
- Taking the temple out of the OAuth flow.
- `mobile/app/real/storage.js` and the AsyncStorage key namespace — explicitly
  forbidden there, pending §6.

## 2. Residue of `ae82ad6` — Observed unless marked

Verified here by grep and by reading the files.

- `real/config.js:18` hardcodes `const mode = 'real'` with no alternative.
  `App.js:109` and `App.js:150` still branch on `clientMode !== 'real'`, which
  can no longer be false.
- `app.config.js` and `eas.json` carry `clientMode: 'real'`; four
  `mobile/scripts/verify-*.js` and `__tests__/native-config.test.js:74` assert
  it.
- `ui-refinement.test.js:20` asserts the phrases `示範模式`, `Demo mode:`,
  `僅供展示` and `display only` are **present** in `copy.js`. The hallucination
  written down as a contract: it fails the moment the strings go, so it is
  deleted with them rather than worked around.
- `real-adapter.test.js:41` is named "there is one mode, and it cannot be
  configured without tenant and API inputs" — the name pins the compile-time
  tenant.
- `response.js:54-57` keeps a coarse read-only fallback "for fixtures";
  `adapter.js:44` still exposes `kind`/`network`/`mode` from the multi-adapter
  interface.
- Already removed: `copy.js` `realBindingUnavailable` (`b9593e6`), which told a
  patron QR binding was unavailable for their "local/test account". Defined in
  both locales, rendered nowhere.

From Recovery's ADVICE of 2026-09-12, **not independently verified here**:

- Modules with no importer anywhere: `lib/auth/client.js` (stubs that throw "no
  adapter installed"), `lib/theme/storage.js`, `lib/theme/resolver.js`,
  `lib/app_constants/env.js`, `theme/styles/login.js`. `0263b0a` gutted these
  and `ae82ad6` left the stubs.
- `screen_model.js`: nine of eleven exports used only by tests;
  `isBoundPresentation` admits a `'switching'` state nothing produces.
- Copy belonging to removed flows: `switchTemple`, `switchDescription`,
  `confirmSwitch`, `resetDemo`, `fixtureCredentials`, `assistanceFixture`,
  `completedCashDemo`, `pendingCashArrangement`, `bindingFailed`,
  `connectWithLink`, `connectionLink`, `unbindTempleDescription`.
- Two demo strings reach release patrons, with no `…Release` variant to select
  instead: `cameraPermissionDenied` (`camera_surface.js:31`) and
  `certificateFixture` as the fallback certificate label (`App.js:267`).

## 3. Reference docs that assert the removed shape

These are maintained documents, so a session looking for intent finds the defect
confirmed back to it. That happened twice on 2026-09-12. From Recovery, spot-
checked here at `templemate_native_account_api.md` only.

- `templemate_native_account_api.md:30-31` states the native base enforces
  `temple_slug` "on every request, else tenant_required". False on the branch
  for
  eight actions, and the sentence that codifies defect 2's server half as
  architecture. Line 8 names `mobile/app/real/adapter.js`; line 53's "37
  methods"
  is a count that drifts.
- `templemate_native_oauth.md:38,56` and `oauth_account_resolution.md:5`
  describe
  the dummy driver as current.
- `deployment_notes.md:160-164` documents a "Dummy-mode Metro/ADB attach recipe"
  with `TEMPLEMATE_CLIENT_MODE=dummy`. Inference (Recovery): run today it boots
  into `REAL_CONFIG_REQUIRED`, because `config.js` ignores `clientMode` and the
  recipe sets no local API URL. A reference doc handing the next session a
  command that bricks the dev client.
- `future_work.md:86-92` links five files under `ops/docs/plans/archive/`,
  deleted at `406a349`. Dangling links, which `work_mode_config.md` forbids.
- `repo_context.md:135` says the dev client "auto-loads a dummy temple". It is a
  real temple on a local Rails. The word re-entered the protocol file on
  2026-09-12.

## 4. The token-refresh defect — production, predates both defects

Verified here. This is the only item in this file that affects production now.

- Nothing calls `adapter.refresh()`. The only caller in the repository is
  `real-adapter.test.js:64` (Observed, grep across `mobile/` excluding
  `node_modules`).
- `JWT_ACCESS_TTL` defaults to 15 minutes (`jwt.rb:54,57`) and is set nowhere in
  the repository.
- A 401 maps to `session_invalid` (`response.js:33`) and the adapter clears
  retained state (`adapter.js:34`).
- Inference: a session cannot outlive its access token. The likely visible
  symptom is being signed out between launches rather than mid-use, because the
  app issues no requests while a patron browses already-loaded state. Awaiting
  the Director's device answer: does TestFlight sign him out between sessions?
- Unrelated but adjacent (Recovery, not verified here): `authenticate` applies
  the session before `loadBootstrap` throws, so each temple-less sign-in attempt
  mints a refresh-token row the client then discards. Orphaned rows, not a
  fault; `revoke_all!` exists.

## 5. Temple-less account operations

From Recovery, not independently verified. Every native route inherits
`resolve_native_temple!`; assignment 012 exempts session issuance only. Profile,
preferences, privacy requests and account closure are user-level data behind a
temple gate, so a patron who has unloaded their temple cannot change language,
edit their name, request an export, or close their account from the app. The web
sends a temple-less user to a chooser instead (`Account::BaseController:22`).

If "no temple means the scanner and nothing else" is the design, this is
consistent and should be written down rather than changed. `SystemAuditLog`
`belongs_to :temple, optional: true`, so nothing in the data model prevents the
other answer.

Related trap, same file: `native_temple_delinquent?`
(`native_base_controller.rb:22-26`) dereferences the temple unguarded. Safe
while
every caller is temple-required; a 500 the moment anything temple-scoped joins
`TEMPLE_OPTIONAL_ACTIONS`. This is the second reason `/bootstrap` stays
temple-required.

## 6. Open decisions — the Director's

1. **The binding storage key.** Installed devices hold entries under the old
   slug; `expo-secure-store` cannot enumerate keys, so old entries can only be
   deleted by a name the app will no longer know. Either one migration constant
   carrying the literal `shengfukung-wenfu`, named as such and with a removal
   date — a deliberate exception to D1 — or no migration and every TestFlight
   device rescans once. The fleet is staff, and they must be handed the new
   build
   anyway. If the key is changing at all, the tenant component should leave it
   entirely so it never moves twice: the session is user-level on the server
   (`refresh_tokens` has no `temple_id`), so a per-tenant key was a fiction of
   the compile-time pin.
2. **Temple-less account operations** — scanner-only as today, or reachable.
3. **The token-refresh defect** — whether it jumps the queue. It affects
   production now; neither defect does.
4. **Deploy order.** Recovery, not verified here: no single QR string satisfies
   both the old and new parsers, so Rails deploys first and the app follows.
   The new link points at `sourcegridlabs.com/templemate/connect/<slug>`, a page
   in another repository that D4 says does not exist — a native-camera scan
   lands
   on whatever that host serves.

## 7. Evidence limits

- Recovery ran nothing; its findings are reads. Where this file relies on them
  it says so, item by item.
- §2's unimported-module list and §5 were not re-derived here.
- 15 minutes and 30 days are the defaults in `jwt.rb`; production may override
  both by environment variable, and neither was read from the droplet.
- The protocol currently contradicts the permission profile on who may merge
  (`work_mode_config.md:35` against Control B's deny list). Reported to the
  Director 2026-09-12; those files belong to Workspace Strategy and are not
  touched from here.
