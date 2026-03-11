# 🔐 SSH Access

```bash

# Droplet (digital ocean) templemate-web
ssh jimmy1768_user@174.138.18.211

```
---

## 📂 Project Directory & Logs

```bash
cd Projects/shengfukung-wenfu
# Puma
tail -f log/production.log
# Sidekiq
tail -f log/sidekiq.log
# Journal
sudo journalctl -u puma.service -f

set -a
source /etc/default/shengfukung-wenfu-env
set +a
RAILS_ENV=production rails console
```

## Production shell / restart

```bash
cd ~/Projects/shengfukung-wenfu/rails

set -a
source /etc/default/shengfukung-wenfu-env
set +a

RAILS_ENV=production rails console

sudo nano /etc/default/shengfukung-wenfu-env

# Restart services
sudo systemctl daemon-reload
sudo systemctl restart shengfukung-wenfu-puma
sudo systemctl restart shengfukung-wenfu-sidekiq
```

---

## 🔧 Git Commands

```bash

git add .
git commit -m "added rails/public/icons"
git push

git reset --hard HEAD
```

---

## Monorepo automation (run from repo root)

```bash
# Install all shared Node deps (adds root node_modules for the helper scripts)
npm install

# Regenerate CSS/JS token files + sync favicons/splash assets (Rails/Vue/Expo)
node bin/sync_design_system.js

# Regenerate Expo icon/adaptive-icon + splash assets from the synced packs
npm run generate:app-icon
# (Also emits mobile/assets/dev-icon.png + dev-adaptive-icon.png for the DEV client badge)

# Rebuild Rails public CSS bundles (account/admin/showcase)
bin/build_rails_css

# Inspect resolved project constants (slug, roots, service names)
bin/project_info

```

---

## Ops + deployment helpers

_The following commands mirror the production checklist: render configs, apply them on the droplet, deploy builds, and verify with smoke tests. When working on the server, run them in order._

```bash
# 1) Render nginx/systemd configs from templates
bin/stage_ops_configs

# 1.5) Preflight droplet/runtime checks before apply/deploy
bin/doctor_deploy <slug>

# 2) Copy rendered systemd units to /etc/systemd/system + restart services
sudo bin/apply_systemd_units

# 3) Copy rendered nginx config to /etc/nginx + run nginx -t && reload
sudo bin/apply_nginx_config

# 4) After certbot/manual edits on the droplet, capture the live configs back into ops/
sudo bin/capture_live_configs

# 5) After pulling those changes locally, update nginx templates from the rendered files
bin/update_conf_template_after_certbot

# Create first-time production env file from template (per temple slug)
SLUG=shengfukung-wenfu
sudo install -m 600 -o root -g root ops/env/template.temple.env /etc/default/${SLUG}-env
sudo nano /etc/default/${SLUG}-env

# One-time Rails setup on a new droplet (bundle install + db:setup + Vue deps)
bin/setup_backend_once --force

# Reset the Rails DB (drop/create/migrate/seed) when needed
bin/reset_backend

# Targeted subsystem reset (auth_core, session_preferences, messaging, admin_controls, cache_control,
# record_archives, config_entries, background_tasks, api_protection, compliance, analytics_exports)
bin/reset_subsystem <name>

> Each subsystem reset now seeds representative records (e.g., cache state, archived records, feature flag,
> background task stub, API logs, compliance artifacts, analytics payload). `bin/reset_subsystem config_entries`
> guarantees a default feature flag rollout record.

# Initialize Expo/EAS once (creates project + records projectId)
bin/setup_expo_once

# Vue deploy: builds + syncs dist for a single slug (loads /etc/default/<slug>-env when readable, else .env.development)
bin/deploy_vue <slug>

# Vue deploy for every slug listed in rails/app/lib/temples/manifest.yml
bin/deploy_vue_all

# Expo prebuild wrapper (loads env for the shared app, runs dev/prod presets, then flushes Metro cache)
bin/expo_prebuild <dev|prod> [-- --platform android]

# Expo/EAS build wrapper with presets (dev-client/apk/aab/ipa/custom)
bin/expo_build <preset> [-- extra eas args]

# Smoke tests: curl /api/v1/temples/:slug for every manifest entry (set SMOKE_BASE_URL for staging/prod)
bin/run_smoke_tests

# Registration period key governance (Phase B)
# Audit invalid service/registration period keys and write a remediation report
cd rails && bin/rails registration_period_keys:audit OUTPUT=tmp/registration_period_key_audit.json
cd rails && bin/rails registration_period_keys:audit SLUG=shengfukung-wenfu OUTPUT=tmp/registration_period_key_audit.json

# Dry-run fallback remap (no writes)
cd rails && bin/rails registration_period_keys:remap_invalid SLUG=shengfukung-wenfu FALLBACK_KEY=perennial

# Apply fallback remap (writes)
cd rails && bin/rails registration_period_keys:remap_invalid SLUG=shengfukung-wenfu FALLBACK_KEY=perennial APPLY=true

# Registration period support workflow (Phase C)
# 1) Edit rails/db/temples/<slug>.yml registration_periods (keys + labels)
# 2) Sync offering template metadata into temple offerings
ruby ops/scripts/sync_offering_configs.rb

# 3) Re-bootstrap temple identity + registration periods into DB for the target temple
cd rails && bin/rails "temples:bootstrap[shengfukung-wenfu]"

# 4) Validate no invalid period keys remain
cd rails && bin/rails registration_period_keys:audit SLUG=shengfukung-wenfu OUTPUT=tmp/registration_period_key_audit.json

# 5) Deploy updated app artifacts
bin/deploy_vue shengfukung-wenfu

# Registration period yearly rollover (Phase D)
# Dry-run one temple (default: no writes)
cd rails && bin/rails registration_period_keys:rollover_year SLUG=shengfukung-wenfu OUTPUT=tmp/registration_period_rollover.json

# Dry-run all temples
cd rails && bin/rails registration_period_keys:rollover_year OUTPUT=tmp/registration_period_rollover.json

# Apply YAML rollover for one temple
cd rails && bin/rails registration_period_keys:rollover_year SLUG=shengfukung-wenfu WRITE=true OUTPUT=tmp/registration_period_rollover_apply.json

# Apply YAML rollover + update existing services (explicit flag)
cd rails && bin/rails registration_period_keys:rollover_year SLUG=shengfukung-wenfu WRITE=true UPDATE_SERVICES=true OUTPUT=tmp/registration_period_rollover_apply.json

# Registration lifecycle expiry automation
# Runs expiring-soon notifications, cancels stale unpaid holds, then sends expired notifications.
cd rails && bin/rails registrations:expire_unpaid

# Optional dev recipient sink for app notifications/reminders
export DEV_APP_NOTIFICATION_EMAIL=jimmy.chuang@outlook.com

# API protection / abuse tooling (Phase E)
# Inspect counters, blocked decisions, and active blacklist state
cd rails && bin/rails api_protection:report WINDOW_MINUTES=60 LIMIT=25

# Retention cleanup (preview first)
cd rails && bin/rails api_protection:cleanup DRY_RUN=true
cd rails && bin/rails api_protection:cleanup LOW_SIGNAL_HOURS=48 HIGH_SIGNAL_DAYS=60

# Safe unblock workflows (require APPLY=true)
cd rails && bin/rails api_protection:unblock_ip IP=203.0.113.5 APPLY=true
cd rails && bin/rails api_protection:unblock_scope SCOPE_TYPE=User SCOPE_ID=123 APPLY=true

# Safe counter reset (must include filter + APPLY=true)
cd rails && bin/rails api_protection:reset_counters SCOPE_TYPE=User SCOPE_ID=123 ENDPOINT_CLASS=api.account.write APPLY=true

# Abuse spike threshold checks (alerts use Notifications::Alerts::AlertSender)
cd rails && bin/rails api_protection:alert_spikes DRY_RUN=true
cd rails && bin/rails api_protection:alert_spikes WINDOW_MINUTES=15 MIN_EVENTS=40 MIN_UNIQUE_SCOPES=10
```

---

## Vue marketing site (`/vue`)

```bash
cd vue
npm install

# Local dev server @ http://localhost:5173
npm run dev

# Production build artifacts in vue/dist
npm run build

# Preview the production build locally
npm run preview
```

---

## Rails admin (`/rails`)

```bash
cd rails
bundle install

# Setup DB (creates, migrates, seeds)
bin/rails db:setup

# Run Rails server (defaults to http://localhost:3001)
bundle exec rails server -p 3002 -b 0.0.0.0

# Run any pending migrations
bin/rails db:migrate
```

---

## Temple content API + seeds

- `bin/rails db:seed` now provisions a `Temple` record keyed by `AppConstants::Project.slug`, default pages/sections, and links the seeded owner admin to that temple. The temple-specific copy lives in `rails/db/temples/<slug>.yml`; add a file per client and run `bin/rails temples:seed[slug]` whenever you need to upsert another profile. Run that same command on the production droplet the first time you deploy a temple so the live DB matches the YAML baseline.
- Marketing/demo console (`/marketing/admin`) still uses the `PROJECT_DEFAULT_ADMIN_*` env vars (`admin@<project-slug>.local` / `GoldenTemplate!123` by default).
- The real temple admin console (`/admin`) now authenticates against the actual `User` records you seed (e.g., `bin/rails "admin_controls:seed_owner[shengfukung-wenfu,email@example.com,Password]"`). Use those seeded credentials when signing in.
- Admin console → “Profile” lets you edit the copy/contact info surfaced on the Vue site. Form submissions append a `SystemAuditLog`.
- The Vue app reads `http://localhost:3001/api/v1/temples/:slug` (set via `VITE_API_BASE_URL` + `VITE_TEMPLE_SLUG`). Copy `/vue/.env.example` into the repo root as `.env.development` (or merge into your existing `.env.development`) and adjust those keys when targeting another Rails host.
- Expo builds now read `EXPO_PROJECT_SLUG`, `EXPO_PROJECT_SCHEME`, `EXPO_ANDROID_PACKAGE`, and `EXPO_IOS_BUNDLE_IDENTIFIER` (falling back to the shared keys when absent), so add those to `.env.*` alongside `MOBILE_API_BASE_URL`, `MOBILE_JWT_LOGIN_PATH`, and `MOBILE_JWT_REFRESH_PATH`.
- Offering templates (per-temple form configs) live in `rails/db/temples/offerings/<slug>.yml`. Use `rails/db/temples/offerings/working-draft.yml` as the persistent staging scratch file for each new temple, then convert that draft into the finalized `<slug>.yml`. After editing the real temple YAML, run `ruby ops/scripts/sync_offering_configs.rb` to push the metadata (`form_fields`, defaults, options) into each `TempleOffering` so the admin form reflects the changes.

---

## Expo mobile shell (`/mobile`)

```bash
cd mobile
npm install

# Initialize Expo/EAS once (creates project + records projectId)
bin/setup_expo_once

# Start Expo/Metro bundler with the default platform prompts
npm run start

# Copy the shared Expo config plugins into mobile/plugins-local
bin/pull_expo_plugins ../expo-config-plugins

# Optional: copy straight into another repo (e.g., SourceGrid-Labs)
bin/pull_expo_plugins ../expo-config-plugins ../SourceGrid-Labs/mobile/plugins-local

# Sync local Expo config plugins into the shared expo-config-plugins repo
bin/local-only/sync_expo_plugins ../expo-config-plugins

# Optional helpers (platform-specific)
npm run ios
npm run android

# Prefer `bin/expo_prebuild <dev|prod>` to handle env + cache flush automatically.
# Manual reference: load the right env file before prebuild/EAS so the slug/bundle IDs match.
source .env.development && (cd mobile && npx expo prebuild --platform android)
source .env.production && (cd mobile && npx expo prebuild --platform android)
```

## 🧱 EAS CLI & Prebuild Setup

```bash
# Install EAS CLI globally and check
npm install -g eas-cli
npx expo-doctor

# Prebuild for Development
APP_ENV=dropletDev BUILD_MODE=development npx expo prebuild --clean
npx expo start -c

# Prebuild for Production
APP_ENV=production BUILD_MODE=production npx expo prebuild --clean
npx expo start -c

```

---

## 📦 Build Commands

```bash

# Prefer `bin/expo_build <preset>` for builds that already load the shared app env.

# Android .apk (Development)
eas build --platform android --local --profile development

# Android .apk (Production)
eas build --platform android --local --profile production

# Android .aab (Google Play)
eas build --platform android --local --profile production-aab

# iOS .ipa (let EAS handle ad hoc provision profile)
eas build --platform ios --profile development

# iOS .ipa (Production)
eas build --platform ios --local --profile production

# iOS Simulator
eas build --platform ios --local --profile simulator
## 🔐 SSH Access

```

---

## 📱 Android Debugging & Install

```bash
adb devices
adb reverse tcp:8081 tcp:8081
adb shell pidof com.jimmy1768.Thea
adb logcat --pid=8089

# Install build
adb install -r /Volumes/DevSSD/Projects/sourcegrid-labs/mobile/dev-client-2.apk
adb install -r /Volumes/DevSSD/Projects/sourcegrid-labs/mobilebuild-1765454955888.apk
```

---

```bash

# Droplet (digital ocean)
ssh jimmy1768_user@143.198.91.24

```
---

# Dummy Logins
```
Owner Admin  – owner@shengfukung-wenfu.local  /  DemoPassword!23
Staff Admin  – admin@shengfukung-wenfu.local  /  DemoPassword!23
Patron Tester – patron@shengfukung-wenfu.local /  DemoPassword!23
Dev Support  – dev@shengfukung-wenfu.local   /  DemoPassword!23
Demo Client  – demo@shengfukung-wenfu.local  /  DemoPassword!23
Guest Operator – guest@shengfukung-wenfu.local / DemoPassword!23
```

Client Domain Section: https://domains.squarespace.com
