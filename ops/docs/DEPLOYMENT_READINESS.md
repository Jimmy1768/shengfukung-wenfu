# Deployment Readiness Plan

This checklist covers the steps needed to move TempleMate (shenfukung-wenfu) onto its dedicated droplet, wire nginx/SSL, and validate the stack via smoke tests. Amazon S3/media uploads remain out of scope until buckets are provisioned.

---

## 1. Finalize nginx template

- Update `ops/nginx/shenfukung-wenfu.conf` with separate `server` blocks for staging (`shenfukung.com.tw`) and the eventual production domain (placeholder for `.org.tw`).
- Document upstreams, asset roots, and where certbot paths will be inserted. Add comments describing how to append additional temple domains later.

## 2. Provision TempleMate droplet

- Create a new droplet under the “Core Projects” DigitalOcean account dedicated to TempleMate.
- SSH in, clone the repo, and run `bin/setup_backend_once --force` to install Rails deps, seeds, and Vue/Expo prerequisites.
- Render/apply systemd + nginx configs:
  ```bash
  bin/stage_ops_configs
  sudo bin/apply_systemd_units
  sudo bin/apply_nginx_config
  ```
- Ensure `/var/www/<slug>` directories exist for Vue deployments.

## 3. Point staging DNS + issue TLS cert

- Update DNS so `shenfukung.com.tw` points to the new droplet.
- Once DNS propagates, run certbot:
  ```bash
  sudo certbot --nginx -d shenfukung.com.tw
  ```
- Capture the live nginx config + cert paths back into the repo:
  ```bash
  sudo bin/capture_live_configs
  bin/update_conf_template_after_certbot
  ```

## 4. Deploy + smoke test staging

- Update `rails/app/lib/temples/manifest.yml` so the `shenfukung-wenfu` entry lists `https://shenfukung.com.tw` as `public_url`.
- Deploy the Vue site + Expo app (if needed):
  ```bash
  bin/deploy_vue shenfukung-wenfu
  # Expo builds remain manual (dev-client/APK/AAB/IPA) via bin/expo_prebuild / bin/expo_build
  ```
- Run smoke tests to confirm `/api/v1/temples/:slug` responds with 200:
  ```bash
  SMOKE_BASE_URL=https://shenfukung.com.tw bin/run_smoke_tests
  ```
- Document results (success/failure, follow-up tasks).

---

### Future work (after staging verified)

- Wire the production `.org.tw` domain once the client purchases it: add a new `server` block + manifest entry, run certbot for the new host, and repeat the smoke-test flow.
- Integrate Amazon S3/media uploads once buckets and credentials are ready.
