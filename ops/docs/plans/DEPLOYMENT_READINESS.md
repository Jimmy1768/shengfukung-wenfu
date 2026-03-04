# Deployment Readiness Plan

This is the go-live checklist for TempleMate (`shengfukung-wenfu`) staging deployment. Use this as an execution runbook, not just a reference note.

## Execution Rules

- Complete sections in order. Do not skip gates.
- Record command output links/log snippets in PR or deployment notes.
- If any gate fails, stop and resolve before continuing.
- Media uploads/S3 are out of scope for this rollout.

## Release Metadata

- Slug: `shengfukung-wenfu`
- Staging domain: `shengfukung.com.tw`
- Future production domain: `.org.tw` (pending client purchase)
- Target host: `<user@host>`
- Ops owner: `<name>`
- Date window: `<yyyy-mm-dd>`

## 0. Preflight Gate (Local)

- [ ] Owner: Ops
- [ ] Repo is clean and up to date on intended release commit.
- [ ] Required scripts are present and executable:
  - `bin/stage_ops_configs`
  - `bin/apply_systemd_units`
  - `bin/apply_nginx_config`
  - `bin/run_smoke_tests`
- [ ] Nginx/systemd templates render for slug without placeholder leaks.
- [ ] Pass criteria: no local blockers before touching infra.

## 1. Environment File Bootstrap + Deploy

- [ ] Owner: Ops + App engineer
- [ ] Copy values from `ops/env/template.temple.env` into `/etc/default/shengfukung-wenfu-env`.
- [ ] Fill `/etc/default/shengfukung-wenfu-env` with real staging values:
  - project origins
  - payment provider settings (default `PAYMENTS_PROVIDER=fake` until real provider credentials are validated)
  - email provider keys
- [ ] Validate env loads:
  ```bash
  bin/load_temple_env shengfukung-wenfu -- (cd rails && bundle exec rails runner "puts ENV.fetch('PROJECT_SLUG')")
  ```
- [ ] Confirm remote file exists: `/etc/default/shengfukung-wenfu-env`
- [ ] Pass criteria: env file installed with root-only permissions and expected key set.

## 2. Nginx Template Finalization

- [ ] Owner: Ops
- [ ] Ensure `ops/nginx/shengfukung-wenfu.conf` contains:
  - staging `server_name shengfukung.com.tw`
  - future production placeholder block/comments
  - upstream/socket references aligned with rendered systemd service names
  - correct Vue root (`/var/www/<slug>` style path)
- [ ] Keep comments that indicate certbot-managed sections and future temple domain expansion path.
- [ ] Pass criteria: config is syntactically valid and matches current architecture split (Vue static + Rails upstream).

## 3. Host Provisioning

- [ ] Owner: Ops
- [ ] Create dedicated DigitalOcean droplet under Core Projects.
- [ ] SSH into host, clone repo, checkout release commit.
- [ ] Run setup:
  ```bash
  bin/setup_backend_once --force
  ```
- [ ] Render/apply service and nginx configs:
  ```bash
  bin/stage_ops_configs
  sudo bin/apply_systemd_units
  sudo bin/apply_nginx_config
  ```
- [ ] Ensure Vue target directory exists:
  - `/var/www/shengfukung-wenfu` (or rendered equivalent)
- [ ] Pass criteria: Puma/Sidekiq services installed and nginx reload succeeds.

## 4. DNS + TLS

- [ ] Owner: Ops / DNS admin
- [ ] Point `shengfukung.com.tw` A record to droplet IP.
- [ ] Wait for DNS propagation.
- [ ] Issue cert:
  ```bash
  sudo certbot --nginx -d shengfukung.com.tw
  ```
- [ ] Capture live certbot-managed config back into repo:
  ```bash
  sudo bin/capture_live_configs
  bin/update_conf_template_after_certbot
  ```
- [ ] Pass criteria: HTTPS loads successfully with valid certificate chain.

## 5. Application Deploy (Staging)

- [ ] Owner: App engineer
- [ ] Update manifest public URL for slug:
  - `rails/app/lib/temples/manifest.yml` -> `https://shengfukung.com.tw`
- [ ] Deploy Vue:
  ```bash
  bin/deploy_vue shengfukung-wenfu
  ```
- [ ] Restart services after env/config changes:
  ```bash
  sudo systemctl restart shengfukung-wenfu-puma
  sudo systemctl restart shengfukung-wenfu-sidekiq
  ```
- [ ] Optional: Expo builds via `bin/expo_prebuild` / `bin/expo_build` as release scope requires.
- [ ] Pass criteria: site + API reachable from staging domain.

## 6. Verification + Smoke Tests

- [ ] Owner: QA + App engineer
- [ ] Run platform smoke tests:
  ```bash
  SMOKE_BASE_URL=https://shengfukung.com.tw bin/run_smoke_tests
  ```
- [ ] Manual checks:
  - home page loads with expected temple content
  - `/api/v1/temples/shengfukung-wenfu` returns `200`
  - admin sign-in page reachable
  - one registration flow can be created in staging
- [ ] Payments gate for this phase:
  - keep `PAYMENTS_PROVIDER=fake` unless provider sandbox credentials are ready and validated
- [ ] Pass criteria: smoke tests pass and manual critical path checks pass.

## 7. Rollback Preparedness

- [ ] Owner: Ops
- [ ] Keep previous nginx config snapshot and known-good release SHA.
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

- Wire production `.org.tw` once client purchases domain.
- Repeat DNS/TLS/deploy/smoke flow for production hostnames.
- Enable live Stripe/LINE Pay only after provider credential validation and callback verification.
- Add S3/media upload rollout once bucket + IAM credentials are provisioned.
