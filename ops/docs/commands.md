# 🔐 SSH Access

```bash

# Droplet (DigitalOcean) taiwan-01-web -- same as its shell hostname.
# Two checkouts live on it: shengfukung-wenfu (production, 4003) and
# shengfukung-wenfu-staging (staging, 4002).
ssh jimmy1768_user@174.138.18.211

```
---

## 📂 Project Directory & Logs

```bash
cd ~/Projects/shengfukung-wenfu

# Rails writes its own log; Sidekiq writes nothing to disk and goes to the
# journal. Both corrected 2026-09-25 -- this block said log/production.log and
# log/sidekiq.log at the repository root, neither of which exists.
tail -f rails/log/production.log
sudo journalctl -u shengfukung-wenfu-puma -f
sudo journalctl -u shengfukung-wenfu-sidekiq -f

# LOAD BOTH ENV FILES, shared first and then this checkout's instance.env --
# the same order systemd uses. Since the environment partition (2026-09-14),
# RAILS_ENV, RACK_ENV, PUMA_PORT, PGDATABASE and S3_OBJECT_PREFIX live only in
# instance.env. The shared file alone leaves Rails with no database. No inline
# RAILS_ENV=production either: instance.env supplies it, and a second source is
# the precedence surface the partition removed.
cd ~/Projects/shengfukung-wenfu/rails
set -a && . /etc/default/shengfukung-wenfu-env && . ~/Projects/shengfukung-wenfu/instance.env && set +a
~/.rbenv/bin/rbenv exec bundle exec rails console
```

## Production shell / restart

```bash
cd ~/Projects/shengfukung-wenfu/rails

sudo nano /etc/default/shengfukung-wenfu-env

# Restart services
sudo systemctl daemon-reload
sudo systemctl restart shengfukung-wenfu-puma
sudo systemctl restart shengfukung-wenfu-sidekiq
```

## Internal operator pages

- Internal temple access dashboard: `http://localhost:4001/internal/temples/access`
- Intended use:
  - internal-only ops page
  - review whether your platform operator account already has temple membership
  - later used to grant/revoke temple-scoped admin access
- Access is restricted to the admin email configured in `INTERNAL_PLATFORM_OPERATOR_EMAIL`

---

## 🔧 Git Commands

```bash

git add .
git commit -m "built internal access"
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

# 3.5) Ask whether the copies on this host still match what is committed.
# Read-only, no sudo, exits non-zero if anything differs or is missing, so a
# deploy script can gate on it. Run it ON the droplet, from the checkout you
# care about -- both checkouts hold the same ops/ at different commits, and the
# report names which one it ran from.
#
# Run it after step 2 or 3 to confirm the copy landed, and before starting work
# on a unit or a config to confirm you are editing what is actually running.
# It found nothing for a long time because nothing looked: on 2026-09-14 both
# staging units were missing S3_OBJECT_PREFIX=staging, committed here for some
# time, so staging was writing uploads into production's S3 namespace. The
# nginx configs were identical the same day -- the problem was never that
# everything had drifted, it was that nobody could tell either way.
#
# It reports and never repairs. Fixing drift is step 2 or 3, which is a deploy.
bin/check_ops_drift

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
npx expo prebuild --clean   # run from mobile/; bin/expo_prebuild removed 2026-09-13

# Expo/EAS build wrapper with presets (dev-client/apk/aab/ipa/custom)
npm --prefix mobile run build:testflight   # ios, the live lane

# Smoke tests: curl each tenant deployment's /api/v1/temple endpoint.
# The manifest selects deployment base URLs only; a browser/API URL never includes a slug.
# Set SMOKE_BASE_URL for one selected local, staging, or production deployment.
bin/run_smoke_tests

# Production deploy (the Director's own sequence, recorded 2026-08-19)
#
# There is no automated pipeline and there should not be one: on 2026-08-19
# `sudo bin/apply_systemd_units` re-rendered the units from a template instead
# of using the committed files, and took production down for five minutes.
# Deploy is run by hand, in this order.
cd ~/Projects/shengfukung-wenfu
git fetch origin && git reset --hard origin/release/current

cd rails

# NOTHING RUBY IS ON THE INTERACTIVE PATH ON THIS HOST. Not `bundle`, not
# `ruby`, and not `rbenv` itself. `bin/rails` and `bin/bundle` are
# `#!/usr/bin/env ruby` binstubs and fail the same way. Every unit file calls
# rbenv by absolute path for exactly this reason -- see
# ops/systemd/shengfukung-wenfu-puma.service:18 -- so prefix every Ruby command
# here with the same path:
#
#     ~/.rbenv/bin/rbenv exec <command>
#
# Using any other Ruby installs gems somewhere Puma will not look, which
# reproduces the error below instead of fixing it. Observed 2026-09-14:
# `bundle install` gives "Command 'bundle' not found", and `rbenv version`
# gives "Command 'rbenv' not found, but can be installed with: sudo apt install
# rbenv" -- following that suggestion installs a SECOND rbenv and is not the
# fix. This note said plain `bundle install` until 2026-09-14: it described
# this exact failure two lines above itself and then gave the command that
# causes it.
#
# Run from rails/, NOT the repo root -- the Gemfile lives here, and from the
# root bundler exits with "Could not locate Gemfile". This note said the repo
# root until 2026-09-06, which went unnoticed because no deploy before then had
# changed the Gemfile.
#
# Needed in two cases:
#   1. Gemfile/Gemfile.lock changed in this deploy. Not optional -- Puma boots
#      without the new gem and fails at the first line that requires it.
#   2. This checkout does not have the gems systemd's `rbenv exec` path finds
#      for Puma:
#        Could not find rails-7.1.6, puma-... in locally installed gems
~/.rbenv/bin/rbenv exec bundle install

# Sourcing the env files is what an interactive shell needs and systemd gets
# for free from its two EnvironmentFile= lines. Both, in that order: since the
# environment partition, RAILS_ENV and PGDATABASE are only in instance.env, so
# sourcing the shared file alone -- which is what this said until 2026-09-25 --
# migrates against no database. Without the shared file: "Missing
# JWT_SECRET_KEY in production".
#
# db:migrate, never db:schema:load, db:reset or db:setup on a live database. A
# schema load records every migration up to schema.rb's version as applied
# without running it, which silently skips data migrations such as the
# 2026-09-25 demo temple rename.
set -a && . /etc/default/shengfukung-wenfu-env && . ~/Projects/shengfukung-wenfu/instance.env && set +a
~/.rbenv/bin/rbenv exec bundle exec rails db:migrate   # when there are migrations
~/.rbenv/bin/rbenv exec bundle exec rails <task>       # any other rake task

# Ad-hoc Ruby against production: put it in a file and scp it. Inlining Ruby in
# `bin/rails runner "..."` through ssh has to survive both the local and remote
# shells plus Ruby's own quoting, and silently mangles anything containing
# quotes, #{} or $ -- it fails as a Ruby syntax error that looks like a code
# bug rather than a quoting one.
#   scp check.rb jimmy1768_user@<host>:/tmp/check.rb
#   ssh ... 'cd ~/Projects/shengfukung-wenfu/rails && set -a && . /etc/default/shengfukung-wenfu-env && . ~/Projects/shengfukung-wenfu/instance.env && set +a && ~/.rbenv/bin/rbenv exec bundle exec rails runner /tmp/check.rb; rm -f /tmp/check.rb'

# Frontend, when vue/ changed. No sudo -- /var/www is owned by the deploy user,
# and building as root leaves files Puma's user cannot replace.
cd ~/Projects/shengfukung-wenfu && bin/deploy_vue shengfukung-wenfu

sudo systemctl restart shengfukung-wenfu-puma
sudo systemctl restart shengfukung-wenfu-sidekiq

# Verify from the journal, not `systemctl status` -- during the 2026-08-19
# outage status showed "active (running)" while Puma was crash-looping.
sudo journalctl -u shengfukung-wenfu-puma -n 40 --no-pager

# Staging bring-up (recorded 2026-09-14, the first time staging was started
# after being disabled 2026-09-05).
#
# Staging is a SECOND CHECKOUT on the same droplet, with its own gems, its own
# database and its own units. It tracks `main`, not `release/current`: main is
# the verified integration branch and is what staging runs. Everything below
# is the production sequence pointed at the other checkout -- there is no
# separate procedure, and inventing one is how the two drift.
cd ~/Projects/shengfukung-wenfu-staging
git fetch origin && git reset --hard origin/main

# Its gems are separate from production's. A staging checkout left down while
# main moves will be missing whatever the newer Gemfile.lock wants, and Puma
# fails at boot with "Could not find rails-... in locally installed gems"
# naming the STAGING Gemfile path. Same absolute rbenv path as everywhere else.
cd rails && ~/.rbenv/bin/rbenv exec bundle install

# Migrate before restarting. Staging's database moves only when this runs, and
# skipping it leaves the code ahead of the schema: on 2026-09-14 the checkout
# was moved to main without it, and staging ran for eleven days without the
# temple_gallery_photos table its gallery needs. db:migrate, never
# db:schema:load -- a schema load marks pending data migrations as done
# without running them.
cd ~/Projects/shengfukung-wenfu-staging && bin/staging rails db:migrate

sudo systemctl enable --now shengfukung-wenfu-staging-puma shengfukung-wenfu-staging-sidekiq
sudo systemctl restart shengfukung-wenfu-staging-puma shengfukung-wenfu-staging-sidekiq
systemctl is-active shengfukung-wenfu-staging-puma shengfukung-wenfu-staging-sidekiq

# `enable --now` reports the symlink even when the service then dies, so check
# is-active, and read the journal rather than `systemctl status`.
sudo journalctl -u shengfukung-wenfu-staging-puma -n 40 --no-pager

# What staging actually connected to. This is the check the whole environment
# partition exists for: staging must resolve templemate_data_staging, never
# production's templemate_data.
cd ~/Projects/shengfukung-wenfu-staging/rails && RAILS_ENV=staging ~/.rbenv/bin/rbenv exec bundle exec rails runner 'puts ActiveRecord::Base.connection.execute(%q{SELECT current_database()}).first'

curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:4002/up

# Phase 0 media prefix migration (dry run by default; apply=1 writes)
# See ops/docs/plans/MEDIA_ASSET_REMOVAL_AND_ORPHAN_RECLAMATION_PLAN.md
~/.rbenv/bin/rbenv exec bundle exec rails media:migrate_prefix             # after loading both env files, as above
~/.rbenv/bin/rbenv exec bundle exec rails media:migrate_prefix apply=1   # after loading both env files, as above

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
cd rails && bin/rails "temples:cleanup[shengfukung-wenfu]"
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

# Run Rails server (defaults to http://localhost:4001)
bundle exec rails server -p 4001 -b 0.0.0.0

# Run any pending migrations
bin/rails db:migrate
```

---

## Temple content API + seeds

- `bin/rails db:seed` now provisions a `Temple` record keyed by `AppConstants::Project.slug`, default pages/sections, and links the seeded owner admin to that temple. The temple-specific copy lives in `rails/db/temples/<slug>.yml`; add a file per client and run `bin/rails temples:seed[slug]` whenever you need to upsert another profile. Run that same command on the production droplet the first time you deploy a temple so the live DB matches the YAML baseline.
- Marketing/demo console (`/marketing/admin`) still uses the `PROJECT_DEFAULT_ADMIN_*` env vars (`admin@<project-slug>.local` / `GoldenTemplate!123` by default).
- The real temple admin console (`/admin`) now authenticates against the actual `User` records you seed (e.g., `bin/rails "admin_controls:seed_owner[shengfukung-wenfu,email@example.com,Password]"`). Use those seeded credentials when signing in.
- Admin console → “Profile” lets you edit the copy/contact info surfaced on the Vue site. Form submissions append a `SystemAuditLog`.
- The Vue app calls relative tenant-local `/api/v1/temple` paths. In local development, Vite proxies those paths to Rails on `http://localhost:4001`; there is no public API-base or temple-selector environment setting.
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

# bin/expo_prebuild was removed 2026-09-13, having never run; use expo prebuild directly.
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

# Builds are npm scripts; bin/expo_build was removed 2026-09-13, having never run.

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
