# TempleMate native OAuth reference

## Scope and authority

TempleMate (internal project `komainu`) uses the Wenfu account-native OAuth
transaction as its first Expo OAuth implementation. Google and Apple both open
the authorization URL returned by Wenfu Rails; the Expo client never calls a
provider or SourceGrid central-auth directly. The client calls only:

- `POST /api/v1/account/native/oauth/start?temple_slug=...`
- `POST /api/v1/account/native/oauth/exchange?temple_slug=...`

Rails selects `templemate://oauth/complete` and returns it in the start
response. The client verifies that exact scheme/host/path before it exchanges a
returned code. It does not invent a production domain, universal link, or
provider callback.

## Reusable mechanism

`mobile/app/oauth/transaction.js` is provider-independent. Each attempt:

1. creates a fresh 256-bit verifier and S256 challenge with `expo-crypto`;
2. sends the provider, challenge, and `S256` to Rails;
3. stores only provider, expected return, opaque transaction token, verifier,
   and creation/expiry timestamps in the existing environment-and-tenant
   scoped secure storage;
4. opens the Rails-provided URL with `expo-auth-session` and
   `expo-web-browser`; and
5. consumes the pending record before exchange, stores only the resulting
   account session, and clears the pending record on every terminal outcome.

Unsolicited or mismatched callbacks, invalid/missing codes, expiry, replay,
provider denial, cancellation, exchange failure, logout, account closure,
tenant switch, and reset all fail closed. An app restart can report one valid,
unexpired browser interruption, but beginning again replaces the old pending
record. No code is written to storage or logs.

## TempleMate-specific behavior

The visible account-only buttons, localized copy, demo disclosure, existing
email sign-in/signup/recovery, profile-completion screen, and the
environment-plus-tenant storage scope belong to TempleMate. Later apps must
choose their own account UI, tenant binding, return allowlisting, and
profile-completion behavior; they should reuse the transaction boundary, not
copy this UI or its fixture tenant values blindly.

## Public configuration matrix

| Mode | Public inputs | Known values | Deferred external values |
| --- | --- | --- | --- |
| Development | local API base URL, tenant slug, environment, return URI | one mode, real: every build talks to a real server (`app/real/config.js`); return URI is `templemate://oauth/complete` | provider registration and deployed return allowlist |
| Production | API origin and return URI | the origin is pinned; no tenant is compiled in — the temple is loaded at runtime from a scanned code, and signing in needs none. Return URI remains `templemate://oauth/complete`. The central auth tenant is `AUTH_TENANT_SLUG`, the app's own registration and never a temple slug | provider registration, universal/app links |

The public configuration contains no client secret, provider token, ID token,
refresh token, provider client ID, central response body, or redirect code.

## Operating and build boundary

The SDK-54 source set is `expo-auth-session@7.0.11`,
`expo-web-browser@15.0.11`, and `expo-crypto@15.0.9`, with their Yarn lock
closure. The existing `templemate` scheme must be in a compatible native
binary. A new development binary may therefore be needed, but Expo prebuild,
local native builds, EAS builds, provider setup, live sign-in, device testing,
deployment, and release are separately authorized later work.
