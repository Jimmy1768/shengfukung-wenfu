# Shared App Constants

`project.json` is the single source of truth for values that every surface
consumes (Rails, Vue, Expo, ops scripts, etc.). Keep only stack-level metadata
here (slug, name, bundle prefixes, deploy roots, etc.). Temple-specific profile
data now lives in `rails/db/temples/<slug>.yml`.

`temple_profile_placeholders.json` holds one value: the hero image a temple
shows when a hero tab has none of its own, read by `rails/app/models/temple.rb`.
It is deliberately not a store of placeholder UI copy any more. It used to carry
contact, service_times, visit_info and about defaults written for an admin --
"尚未設定地址（請至後台「Temple Profile」更新）" and similar -- which the serializer
returned for any temple that had written nothing, so the public API and then the
public site showed visitors instructions they could not act on. Removed
2026-09-25. A temple with no data returns nothing and the site hides the region.
Do not reintroduce a default here that is addressed to somebody who is not the
reader: a guard in `rails/test/lib/public_site_placeholder_scan_test.rb` fails if
the site falls back to one.

The accompanying helper `projectConfig.js` loads the JSON, applies `PROJECT_*`
environment overrides, and exposes the resolved values (slug, name, marketing
root, systemd env file, service names, etc.).

- Rails uses `AppConstants::Project` to read the same file.
- Vue/ops tooling can `require("../shared/app_constants/projectConfig.js")`
  or run `bin/project_info` to inspect the resolved config.

Keep new cross-surface settings in `project.json` so every deployment stays
aligned automatically. Rails-only constants still belong under
`rails/app/lib/app_constants/`.
