# Deployment Readiness Plan

This is the go-live checklist for TempleMate (`shengfukung-wenfu`) staging deployment. Use this as a status-aware execution runbook, not just a reference note.

## Execution Rules

- Complete sections in order. Do not skip gates.
- Record command output links/log snippets in PR or deployment notes.
- If any gate fails, stop and resolve before continuing.
- Media uploads/S3 are out of scope for this rollout.

## Release Metadata

- Slug: `shengfukung-wenfu`
- Staging domain: `shengfukung.com.tw`
- Future production domain: `.org.tw` (pending client purchase)
- Target host: `jimmy1768_user@174.138.18.211`
- Ops owner: `jimmy1768`
- Date window: `2026-03 staging rollout`

## Current Status Split

Use these labels consistently when updating the checklist:

- `Done`: exercised and verified in this project already.
- `Blocked externally`: cannot complete inside this repo because an upstream dependency is still broken.
- `Untested`: not yet verified on this project, even if infrastructure exists.

Current interpretation after production Google OAuth validation and shared-DB cleanup:

- `Done`
  - staging host is live
  - nginx, Puma, and Sidekiq are running
  - Vue frontend is deployed and serving
  - Rails API is reachable from `https://shengfukung.com.tw`
  - account namespace is wired and reachable
  - central-auth Google OAuth works end-to-end
  - admin sign-in works after promoting a real OAuth-backed user
  - admin console pages/actions are reachable and responsive
  - shared production DB has been cleaned back to the intended baseline state
  - both temple rows remain present with only slug/name retained
  - blank unpublished temple profile is the correct pre-onboarding state
- `Blocked externally`
- `Untested`
  - email/password account flows
  - admin-driven temple profile/content entry from blank state
  - publish flow after admin content entry
  - one real registration flow after temple content is prepared
  - account linking manual validation with Apple as secondary provider
  - Facebook OAuth production validation
  - payments beyond fake provider mode
  - S3/media uploads
  - rollback drill timing
  - production `.org.tw` cutover

## 0. Preflight Gate (Local)

- [x] Owner: Ops
- [x] Repo is clean and up to date on intended release commit.
- [x] Required scripts are present and executable:
  - `bin/stage_ops_configs`
  - `bin/apply_systemd_units`
  - `bin/apply_nginx_config`
  - `bin/run_smoke_tests`
- [x] Nginx/systemd templates render for slug without placeholder leaks.
- [x] Pass criteria: no local blockers before touching infra.

## 1. Environment File Bootstrap + Deploy

- [x] Owner: Ops + App engineer
- [x] Copy values from `ops/env/template.temple.env` into `/etc/default/shengfukung-wenfu-env`.
- [x] Fill `/etc/default/shengfukung-wenfu-env` with real staging values:
  - project origins
  - payment provider settings (default `PAYMENTS_PROVIDER=fake` until real provider credentials are validated)
  - email provider keys
- [x] Validate env loads:
  ```bash
  bin/load_temple_env shengfukung-wenfu -- (cd rails && bundle exec rails runner "puts ENV.fetch('PROJECT_SLUG')")
  ```
- [x] Confirm remote file exists: `/etc/default/shengfukung-wenfu-env`
- [x] Pass criteria: env file installed with root-only permissions and expected key set.

## 2. Nginx Template Finalization

- [x] Owner: Ops
- [x] Ensure `ops/nginx/shengfukung-wenfu.conf` contains:
  - staging `server_name shengfukung.com.tw`
  - future production placeholder block/comments
  - upstream/socket references aligned with rendered systemd service names
  - correct Vue root (`/var/www/<slug>` style path)
- [x] Keep comments that indicate certbot-managed sections and future temple domain expansion path.
- [x] Pass criteria: config is syntactically valid and matches current architecture split (Vue static + Rails upstream).

## 3. Host Provisioning

- [x] Owner: Ops
- [x] Create dedicated DigitalOcean droplet under Core Projects.
- [x] SSH into host, clone repo, checkout release commit.
- [x] Run setup:
  ```bash
  bin/setup_backend_once --force
  ```
- [x] Render/apply service and nginx configs:
  ```bash
  bin/stage_ops_configs
  sudo bin/apply_systemd_units
  sudo bin/apply_nginx_config
  ```
- [x] Ensure Vue target directory exists:
  - `/var/www/shengfukung-wenfu` (or rendered equivalent)
- [x] Pass criteria: Puma/Sidekiq services installed and nginx reload succeeds.

## 4. DNS + TLS

- [x] Owner: Ops / DNS admin
- [x] Point `shengfukung.com.tw` A record to droplet IP.
- [x] Wait for DNS propagation.
- [x] Issue cert:
  ```bash
  sudo certbot --nginx -d shengfukung.com.tw
  ```
- [x] Capture live certbot-managed config back into repo:
  ```bash
  sudo bin/capture_live_configs
  bin/update_conf_template_after_certbot
  ```
- [x] Pass criteria: HTTPS loads successfully with valid certificate chain.

## 5. Application Deploy (Staging)

- [x] Owner: App engineer
- [x] Update manifest public URL for slug:
  - `rails/app/lib/temples/manifest.yml` -> `https://shengfukung.com.tw`
- [x] Deploy Vue:
  ```bash
  bin/deploy_vue shengfukung-wenfu
  ```
- [x] Restart services after env/config changes:
  ```bash
  sudo systemctl restart shengfukung-wenfu-puma
  sudo systemctl restart shengfukung-wenfu-sidekiq
  ```
- [ ] Optional: Expo builds via `bin/expo_prebuild` / `bin/expo_build` as release scope requires.
- [x] Pass criteria: site + API reachable from staging domain.

## 6. Verification + Smoke Tests

- [x] Owner: QA + App engineer
- [x] Run platform smoke tests:
  ```bash
  SMOKE_BASE_URL=https://shengfukung.com.tw bin/run_smoke_tests
  ```
- [x] Smoke result: `https://shengfukung.com.tw/api/v1/temples/shengfukung-wenfu` returned `200` and `bin/run_smoke_tests` completed successfully.
- [x] Manual checks:
  - public site and temple API load from the staging domain
  - `/api/v1/temples/shengfukung-wenfu` returns `200`
  - account sign-in flow is reachable and Google OAuth succeeds end-to-end
  - admin sign-in works with promoted account
  - admin console pages/buttons respond correctly
  - shared DB cleanup completed and temples are now intentionally blank/unpublished until onboarding
- [ ] Manual checks still pending:
  - admin-driven temple profile/content entry from blank baseline
  - publish flow for temple profile
  - one registration flow can be created in staging after onboarding content exists
  - email/password account flow
  - Apple OAuth on `www.shengfukung.com.tw`
  - Facebook OAuth end-to-end on `shengfukung.com.tw`
- [x] Payments gate for this phase:
  - keep `PAYMENTS_PROVIDER=fake` unless provider sandbox credentials are ready and validated
- [ ] Pass criteria: smoke tests pass and remaining manual critical path checks pass.

## 7. Rollback Preparedness

- [ ] Owner: Ops
- [x] Keep previous nginx config snapshot and known-good release SHA.
- [ ] Confirm ability to:
  - redeploy previous SHA
  - restore previous nginx config
  - restart puma/sidekiq cleanly
- [ ] Pass criteria: rollback can be executed in under 15 minutes.

## 8. Go/No-Go Signoff

- [ ] Ops signoff
- [ ] App signoff
- [ ] QA signoff
- [ ] Decision logged with timestamp and release SHA.

## Post-Staging Follow-Ups

- Use admin onboarding flow to populate temple profile/content, then publish when client is ready.
- Apple OAuth is working on `shengfukung.com.tw` after fixing the central auth Team ID; keep the SourceGrid env value at `APPLE_TEAM_ID=99GH38T5WW`.
- Run remaining manual provider tests:
  - Apple on `www.shengfukung.com.tw`
  - account linking with Apple as secondary provider
  - first-login vs repeat-login name capture behavior
  - Facebook provider start/callback/session validation in production
- Wire production `.org.tw` once client purchases domain.
- Repeat DNS/TLS/deploy/smoke flow for production hostnames.
- Enable live Stripe/LINE Pay only after provider credential validation and callback verification.
- Add S3/media upload rollout once bucket + IAM credentials are provisioned.
