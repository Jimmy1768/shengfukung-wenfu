# TempleMate native account API: what exists

## The one fact this doc exists to prevent getting wrong

**The native account API is built.** As of 2026-08-31 there are 43 routes under
`/api/v1/account/native/*` covering sessions, OAuth, profile, dependents,
registrations, resources, preferences, privacy, and assistance — and
`mobile/app/real/adapter.js` consumes nearly all of them.

This doc exists because the planning record said the opposite for a long time
and was widely cited. `EXPO_ACCOUNT_APP_READINESS_AND_PARITY_PLAN.md` asserted
"native authentication is not implemented", "JSON parity is mostly absent", and
six blocking contract gaps (B-01..B-06). All six are resolved. A session that
reads that plan without checking the routes will re-plan work that already
shipped, or re-build endpoints that already answer.

**Check `bin/rails routes | grep native` before believing any claim that a
native endpoint is missing.**

## Authority boundary (why this API is separate)

`Api::V1::Account::NativeBaseController` deliberately does **not** inherit
`Account::BaseController`. That controller is a browser-cookie surface with
admin-aware scope helpers: for a user who also holds admin authority,
registration scope can widen to owned admin temples, and preferences accept an
admin display mode. An account-only app must never receive or mutate that.

The native base instead enforces:

- `temple_slug` resolvable where it is supplied, else `tenant_not_found` — on
  every route, including the ones below that do not require it
- `temple_slug` **present**, else `tenant_required`, on every route except the
  ones that issue or begin a session: `native_sessions` signup, login, refresh,
  password_recovery and password_reset; `native_oauth` start and exchange; and
  `native_oauth_resolutions` show, existing and new_account
  (`TEMPLE_OPTIONAL_ACTIONS`, `native_base_controller.rb`). Signing in does not
  require a temple: a patron with none loaded is shown the scanner, and that is
  a steady state rather than a first-run phase, since a temple can be unloaded
  at any time
- a bearer JWT whose `scope` claim is exactly `"account"`, else
  `session_invalid`
- a live refresh-session (`session&.active?`), else `session_revoked`
- a non-closed user, else `account_closed`

`Api::BaseController` itself provides no authentication on purpose — nine
public tenant endpoints (temples, events, gatherings, services, news,
galleries, contact requests) inherit it directly, so a base-level
authenticate filter would be wrong there, not merely missing.

Session lifecycle is `Auth::RefreshToken` — `issue!`, `rotate!`, `revoke!`,
`revoke_all!` are all implemented.

## Three layers, three different completion states

Do not collapse these. "The app can't do X" is usually a *screen* gap, not an
API gap.

| Layer | State |
| --- | --- |
| Rails native API | Essentially complete (see absences below) |
| `mobile/app/real/adapter.js` | Covers the API except contact + payment |
| Expo account screens | Present but **minimal**. All 12 render from `App.js`; several expose a fraction of the fields their endpoint accepts |

Screens are **not** in `mobile/app/account/` (that directory holds registration
authority and presentation logic only). All 12 declared in `ACCOUNT_SCREENS`
render from `App.js`, which calls 24 adapter methods. The gap is field
coverage, not missing screens:

| Surface | API accepts / returns | UI exposes |
| --- | --- | --- |
| Profile | `english_name`, `native_name`, `phone`, `city`, `notes` (5) | `native_name` only (1) |
| Dependents | `english_name`, `native_name`, `relationship_label`, `birthdate`, `phone`, `email`, `notes` (7) | name, relationship (2) |

`NativeProfileController` uses the same `Account::ProfileForm` as the web, so
parity is structural rather than reimplemented — the remaining work is UI
field coverage, not contract work.

**Why this ordering mattered.** `NativeAccountSerializer.user` reads
`metadata["phone"]` and `metadata["notes"]` — the exact keys that admin
registration edits overwrote before the `registration_contact` namespace fix.
Adding a phone field to the profile screen before that fix would have
displayed temple-overwritten data to the patron as their own.

## Endpoint surface

| Group | Routes |
| --- | --- |
| Session | `POST login`, `DELETE logout`, `POST refresh`, `POST signup`, `GET bootstrap` |
| Password | `POST password/recovery`, `POST password/reset`, `POST profile/password` |
| OAuth | `POST oauth/start`, `POST oauth/exchange`, `GET oauth/resolution`, `POST oauth/resolution/new`, `POST oauth/resolution/existing` |
| Profile | `GET profile`, `PATCH profile` |
| Dependents | `GET`, `POST`, `GET/:id`, `PATCH/:id`, `DELETE/:id` |
| Registrations | `GET`, `POST`, `GET/:id`, `GET/new`, `GET/:id/edit`, `PATCH/:id` |
| Resources | `GET events`, `GET services`, `GET galleries`, `GET galleries/:id`, `GET certificates` |
| Preferences | `GET preferences`, `PATCH preferences` |
| Privacy | `GET privacy`, `POST privacy/:request_type`, `POST privacy/close` |
| Support | `POST assistance`, `POST contact` |

Native registration create/update posts a fixed field set, independent of any
temple's offering YAML: `quantity`, `registrant_scope`, `dependent_id`,
`contact_name`, `contact_phone`, `contact_email`, `household_notes`,
`arrival_window`, `ceremony_notes`. This is why the Expo app does **not**
depend on per-temple offering configuration — it consumes a stable contract.

## What is genuinely absent

- **Native checkout / payment handoff.** No native endpoint starts a checkout
  or handles browser return; `Account::RegistrationsController#start_checkout`
  and `#checkout_return` are HTML-only. The adapter has no payment method
  either. Absent on both ends.
- **Account payments history.** Only `GET /api/v1/account/payment_statuses/:reference`
  exists, which is per-registration, not a history list.
- **Linked-identity management.** OAuth resolution handles signup-time
  conflicts; there is no native list/link/unlink surface, and the server's
  last-login-method protection must be preserved if one is added.
- **Contact temple from the client.** `POST native/contact` exists; the
  adapter does not call it.

## Source

- `app/controllers/api/v1/account/native_base_controller.rb` — the authority
  boundary above.
- `app/controllers/api/v1/account/native_*_controller.rb` — the endpoints.
- `app/services/auth/refresh_token.rb`, `app/services/auth/jwt_service.rb` —
  session lifecycle.
- `mobile/app/real/adapter.js` — the client surface, with `/api/v1/account/native`
  as its base path.
- `ops/docs/reference/templemate_native_oauth.md` — the OAuth transaction in
  detail (start/exchange, `templemate://oauth/complete`).
- `ops/docs/plans/EXPO_ACCOUNT_APP_READINESS_AND_PARITY_PLAN.md` — still live
  for its product decisions, non-scope, and remaining payment/shell work; its
  gap register is superseded by this doc.
