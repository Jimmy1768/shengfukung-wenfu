# OAuth Providers Setup Plan

This plan is intentionally split into phases.

- Current state: centralized auth service is not implemented yet.
- Decision: do not create temple-specific production OAuth clients now.
- Policy: keep production OAuth disabled in temple deployments until centralized auth is ready.

## Scope

- Define what can be done immediately without creating provider client drift.
- Freeze production OAuth client creation until central auth host/service exists.
- Prepare clean cutover steps for Google, Apple, Facebook later.

## Source Of Truth In Code

- Provider env keys: `rails/app/lib/app_constants/oauth.rb`
- OmniAuth middleware wiring: `rails/config/initializers/omniauth.rb`
- Callback routes: `rails/config/routes.rb`

## Provider Env Keys

- `OAUTH_GOOGLE_CLIENT_ID`
- `OAUTH_GOOGLE_CLIENT_SECRET`
- `OAUTH_APPLE_CLIENT_ID`
- `OAUTH_APPLE_CLIENT_SECRET`
- `OAUTH_FACEBOOK_CLIENT_ID`
- `OAUTH_FACEBOOK_CLIENT_SECRET`

Provider buttons appear only when both client id + secret are present.

## Phase A: Hold Pattern (Do Now)

### A1. Keep Production OAuth Disabled

- [ ] Ensure all `OAUTH_*` vars are empty in `/etc/default/shengfukung-wenfu-env`.
- [ ] Restart Puma after env updates:
  ```bash
  sudo systemctl restart shengfukung-wenfu-puma
  ```
- [ ] Confirm account/admin login still works via email/password.

### A2. Preserve Environment Separation

- [ ] Keep localhost-only OAuth client in dev project (`Golden-Template`) for local use only.
- [ ] Do not reuse dev credentials in production env.
- [ ] Do not create temple-domain production OAuth clients in this phase.

### A3. Document Central Auth Requirement

- [ ] Central callback host must be one stable HTTPS domain (example placeholder):
  - `https://<central-auth-host>/auth/google_oauth2/callback`
  - `https://<central-auth-host>/auth/apple/callback`
  - `https://<central-auth-host>/auth/facebook/callback`
- [ ] Temple domains will redirect into central auth flow and return to tenant origin after callback.

## Phase B: Centralized Auth Cutover (Blocked Until Service Exists)

Blocked by implementation in platform/core project.

### B1. Prerequisites

- [ ] Central auth service deployed and reachable.
- [ ] DNS + TLS active for central auth host.
- [ ] Tenant allowlist + signed state + nonce replay protection implemented.
- [ ] Callback endpoints verified in production (`/auth/:provider/callback`).

### B2. Provider Client Creation (Once)

- [ ] Create production Google OAuth web client with central callback host.
- [ ] Create production Apple web login config with central callback host.
- [ ] Create production Facebook login config with central callback host.
- [ ] Store secrets in centralized secret management + deployment env.

### B3. Runtime Wiring

- [ ] Set `OAUTH_*` vars only in the central auth runtime env.
- [ ] Keep temple runtimes free of provider secrets unless architecture explicitly requires otherwise.

### B4. Verification

- [ ] Start OAuth from at least two temple domains.
- [ ] Verify callback lands on central host.
- [ ] Verify post-login return redirects to correct tenant domain/slug.
- [ ] Verify audit logs and failure handling.

## Acceptance Criteria For Enabling OAuth In Temples

All must be true:

- [ ] Central auth host/service is live in production.
- [ ] Provider production clients point to central callback host.
- [ ] Signed state validation is enforced.
- [ ] Return URL allowlist is enforced per tenant.
- [ ] End-to-end login verified for multiple temple domains.

## Security Notes

- Never commit OAuth secrets.
- Keep dev and production OAuth credentials separate.
- Rotate secrets immediately if exposed.
- Prefer one clean production client set per provider for centralized auth.
