## 🔧 Git Commands

```bash

git add .
git commit -m ""
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

```bash
# Render nginx/systemd configs from templates
bin/stage_ops_configs

# Copy rendered systemd units to /etc/systemd/system + restart services
sudo bin/apply_systemd_units

# Copy rendered nginx config to /etc/nginx + run nginx -t && reload
sudo bin/apply_nginx_config

# After certbot/manual edits on the droplet, capture the live configs back into ops/
sudo bin/capture_live_configs

# After pulling those changes locally, update nginx templates from the rendered files
bin/update_conf_template_after_certbot

# First-time Rails setup (bundle install + db:setup + Vue deps + template rename)
bin/setup_backend_once --force

# Reset the Rails DB (drop/create/migrate/seed)
bin/reset_backend

# Targeted subsystem reset (auth_core, session_preferences, messaging, admin_controls, cache_control, record_archives, config_entries, background_tasks, api_protection, compliance, analytics_exports)
bin/reset_subsystem <name>

> Each subsystem reset now seeds representative records (e.g., a cache state/metric, archived records, a config entry + feature flag, background task stub, API logs + blacklist entry, compliance artifacts, analytics job/payload) so you can inspect the schema in development. `bin/reset_subsystem config_entries` in particular now guarantees a default feature flag rollout record.

# Initialize Expo/EAS once (creates project + records projectId)
bin/setup_expo_once
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
bundle exec rails server -p 3001 -b 0.0.0.0

# Run any pending migrations
bin/rails db:migrate
```

---

## Temple content API + seeds

- `bin/rails db:seed` now provisions a `Temple` record keyed by `AppConstants::Project.slug`, default pages/sections, and links the seeded owner admin to that temple. The temple-specific copy lives in `rails/db/temples/<slug>.yml`; add a file per client and run `bin/rails temples:seed[slug]` whenever you need to upsert another profile. Run that same command on the production droplet the first time you deploy a temple so the live DB matches the YAML baseline.
- Marketing/demo console (`/marketing/admin`) still uses the `PROJECT_DEFAULT_ADMIN_*` env vars (`admin@<project-slug>.local` / `GoldenTemplate!123` by default).
- The real temple admin console (`/admin`) now authenticates against the actual `User` records you seed (e.g., `bin/rails "admin_controls:seed_owner[shenfukung-wenfu,email@example.com,Password]"`). Use those seeded credentials when signing in.
- Admin console → “Profile” lets you edit the copy/contact info surfaced on the Vue site. Form submissions append a `SystemAuditLog`.
- The Vue app reads `http://localhost:3001/api/v1/temples/:slug` (set via `VITE_API_BASE_URL` + `VITE_TEMPLE_SLUG`). Copy `/vue/.env.example` into the repo root as `.env.development` (or merge into your existing `.env.development`) and adjust those keys when targeting another Rails host.
- Expo builds now read `EXPO_PROJECT_SLUG`, `EXPO_PROJECT_SCHEME`, `EXPO_ANDROID_PACKAGE`, and `EXPO_IOS_BUNDLE_IDENTIFIER` (falling back to the shared keys when absent), so add those to `.env.*` alongside `MOBILE_API_BASE_URL`, `MOBILE_JWT_LOGIN_PATH`, and `MOBILE_JWT_REFRESH_PATH`.
- Offering templates (per-temple form configs) live in `rails/db/temples/offerings/<slug>.yml`. After editing those YAML files, run `ruby ops/scripts/sync_offering_configs.rb` to push the metadata (`form_fields`, defaults, options) into each `TempleOffering` so the admin form reflects the changes.

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

# Load the right env file before prebuild/EAS so the slug/bundle IDs match the build target
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
```bash
admin@shenfukung-wenfu.local
GoldenTemplate!123

demo@shenfukung-wenfu.local
guest@shenfukung-wenfu.local
DemoPassword!23
```

cd Projects/sourcegrid-labs

set -a
source /etc/default/sourcegrid-labs-env
set +a

RAILS_ENV=production bundle exec rails c

sudo nano /etc/default/sourcegrid-labs-env

# Restart services
sudo systemctl daemon-reload
sudo systemctl restart sourcegrid-labs-puma
sudo systemctl restart sourcegrid-labs-sidekiq

sudo -u postgres psql -c "ALTER ROLE sourcegrid_prod WITH CREATEDB;"

Client Domain Section: https://domains.squarespace.com
