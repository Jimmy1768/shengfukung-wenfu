# Shared App Constants

`project.json` is the single source of truth for values that every surface
consumes (Rails, Vue, Expo, ops scripts, etc.). Keep only stack-level metadata
here (slug, name, bundle prefixes, deploy roots, etc.). Temple-specific profile
data now lives in `rails/db/temples/<slug>.yml` and placeholder UI copy sits in
`shared/app_constants/temple_profile_placeholders.json`.

The accompanying helper `projectConfig.js` loads the JSON, applies `PROJECT_*`
environment overrides, and exposes the resolved values (slug, name, marketing
root, systemd env file, service names, etc.).

- Rails uses `AppConstants::Project` to read the same file.
- Vue/ops tooling can `require("../shared/app_constants/projectConfig.js")`
  or run `bin/project_info` to inspect the resolved config.

Keep new cross-surface settings in `project.json` so every deployment stays
aligned automatically. Rails-only constants still belong under
`rails/app/lib/app_constants/`.
