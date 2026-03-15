# OAuth Providers Setup Plan

This plan is intentionally split into phases.

- Current decision: use centralized auth service (no per-temple provider clients).
- Temple policy: temple runtimes must not store Google/Apple/Facebook provider secrets.
- Temple runtimes only store central auth tenant credentials.

## Status Snapshot (2026-03-08)

- [x] Agreed: no temple-specific production OAuth clients for `shengfukung-wenfu`.
- [x] Agreed: keep localhost-only OAuth credentials in dev scope only.
- [x] Central auth handoff started in platform/sourcegrid project.
- [x] Tenant registered in central auth DB for `shengfukung`.
- [x] Temple-side runtime wiring is active and verified for Google end-to-end.
- [x] Apple provider is configured in Apple Developer + central auth `/oauth/start` returns `authorize_url`.
- [x] Apple full callback sign-in success is working in production after correcting SourceGrid central auth `APPLE_TEAM_ID` to `99GH38T5WW` and restarting the platform services.

## Current State

Use this interpretation when reading the checklist below:

- `Done in this repo`
  - temple runtime is using centralized auth correctly
  - Google OAuth is working end-to-end in production
  - Apple start path, tenant resolution, and return URL wiring are correct
- `Done in platform`
  - Apple final callback completion inside SourceGrid central auth
- `Not required for this repo`
  - temple-side provider secret management for Google/Apple/Facebook production clients

## Source Of Truth In Code

- Local provider env keys (legacy direct OmniAuth): `rails/app/lib/app_constants/oauth.rb`
- Local callback routes (legacy direct OmniAuth): `rails/config/routes.rb`
- Central auth endpoints (new flow):
  - `POST /oauth/start`
  - `POST /oauth/token/exchange`

## Phase A: Hold Pattern (Completed)

### A1. Keep Direct Provider OAuth Disabled In Temple Runtime

- [x] Do not create temple-domain production OAuth clients.
- [x] Do not put provider secrets (`OAUTH_*`) into temple production env.

### A2. Preserve Environment Separation

- [x] Keep localhost-only OAuth client in dev project (`Golden-Template`) for local use only.
- [x] Do not reuse dev credentials in production env.

## Phase B: Centralized Auth Platform Work (Owned By Platform Project)

### B1. Prerequisites

- [x] Central auth service deployed and reachable.
- [x] Central auth tenant created for shengfukung.
- [x] Central auth Apple callback path fixed in platform/sourcegrid production (`/auth/apple/callback` now reaches `/oauth/token/exchange` successfully).
- [x] Signed state/nonce replay controls are present in the platform handoff design.
- [ ] Final production monitoring/audit checks validated.

### B2. Platform Contracts

- [x] Tenant backend must call:
  - `POST /oauth/start`
  - `POST /oauth/token/exchange`
- [x] Tenant has allowlisted return URLs at central auth.

## Phase C: Temple Runtime Wiring (This Repo)

### C1. Add Central Auth Env Keys (Temple Runtime)

Add only these to `/etc/default/shengfukung-wenfu-env`:

- `AUTH_BASE_URL`
- `AUTH_CLIENT_ID`
- `AUTH_CLIENT_SECRET`

Notes:

- Keep `OAUTH_GOOGLE_*`, `OAUTH_APPLE_*`, `OAUTH_FACEBOOK_*` empty in this temple runtime.
- Rotate `AUTH_CLIENT_SECRET` if shared in plaintext outside secure channel.

### C2. Wire Temple Login Flow To Central Auth

- [x] Login start path calls central `POST /oauth/start` from temple backend.
- [x] Temple callback endpoint is wired to receive provider return payload and call central `POST /oauth/token/exchange` server-to-server.
- [x] Temple creates/updates session from exchanged claims for successful providers (Google verified in production).

### C3. Return URL Rules

Use only allowlisted return URLs for this tenant:

- `https://shengfukung.com.tw/auth/callback`
- `https://www.shengfukung.com.tw/auth/callback`

Do not use unregistered callback URLs.

### C4. Verification Checklist

- [x] `/account/login` starts OAuth through central auth.
- [x] Google login returns to temple callback URL.
- [x] Google session established after token exchange.
- [x] Admin/account pages load authenticated state correctly for Google flow.
- [x] Logs show successful `/oauth/start` and `/oauth/token/exchange` with no 500s for Google flow.
- [x] Apple `/oauth/start` returns valid `authorize_url` from central auth.
- [x] Apple central auth request uses the correct tenant (`shengfukung`) and return URL (`https://shengfukung.com.tw/auth/callback`).
- [x] Apple posts back to central auth first (`POST /auth/apple/callback`) as designed.
- [x] Apple callback reaches temple `/auth/callback` and temple `/oauth/token/exchange` successfully in production.
- [x] Apple sign-in establishes a temple session end-to-end in production.
- [x] If the provider does not return a usable name, the temple app now redirects the user to profile edit instead of leaving the account at `OAuth User`.

## Acceptance Criteria

All must be true before marking OAuth done for this temple:

- [x] Temple runtime contains only `AUTH_*` client credentials (no provider secrets).
- [ ] Central auth flow works for both `shengfukung.com.tw` and `www.shengfukung.com.tw`.
- [x] Token exchange and session establishment are stable for Google.
- [x] Error/denial paths are user-safe and logged for all enabled providers.

## Remaining Follow-Up

- Apple callback remediation is complete for `shengfukung.com.tw`.
- Still validate:
  - Apple sign-in success on `www.shengfukung.com.tw`
  - account-linking manual flows that depend on Apple as the second provider
  - first-time Apple authorization behavior vs later logins with no returned name

## Security Notes

- Never commit secrets.
- Keep dev and production credentials separate.
- Rotate credentials immediately if exposed.
- Prefer one clean centralized provider client set per provider.
