# OAuth Providers Setup Plan

This plan is intentionally split into phases.

- Current decision: use centralized auth service (no per-temple provider clients).
- Temple policy: temple runtimes must not store Google/Apple/Facebook provider secrets.
- Temple runtimes only store central auth tenant credentials.

## Status Snapshot (2026-03-05)

- [x] Agreed: no temple-specific production OAuth clients for `shengfukung-wenfu`.
- [x] Agreed: keep localhost-only OAuth credentials in dev scope only.
- [x] Central auth handoff started in platform/sourcegrid project.
- [x] Tenant registered in central auth DB for `shengfukung`.
- [ ] Temple-side runtime wiring and verification still pending.

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
- [ ] Signed state/nonce replay controls validated end-to-end.
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

- [ ] Login start path calls central `POST /oauth/start` from temple backend.
- [ ] Temple callback endpoint receives auth code/token payload and calls central `POST /oauth/token/exchange` server-to-server.
- [ ] Temple creates/updates session from exchanged claims.

### C3. Return URL Rules

Use only allowlisted return URLs for this tenant:

- `https://shengfukung.com.tw/auth/callback`
- `https://www.shengfukung.com.tw/auth/callback`

Do not use unregistered callback URLs.

### C4. Verification Checklist

- [ ] `/account/login` starts OAuth through central auth.
- [ ] Provider login returns to temple callback URL.
- [ ] Session established after token exchange.
- [ ] Admin/account pages load authenticated state correctly.
- [ ] Logs show successful `/oauth/start` and `/oauth/token/exchange` with no 500s.

## Acceptance Criteria

All must be true before marking OAuth done for this temple:

- [ ] Temple runtime contains only `AUTH_*` client credentials (no provider secrets).
- [ ] Central auth flow works for both `shengfukung.com.tw` and `www.shengfukung.com.tw`.
- [ ] Token exchange and session establishment are stable.
- [ ] Error/denial paths are user-safe and logged.

## Security Notes

- Never commit secrets.
- Keep dev and production credentials separate.
- Rotate credentials immediately if exposed.
- Prefer one clean centralized provider client set per provider.
