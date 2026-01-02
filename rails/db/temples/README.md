## Temple profile configs

1. Add one YAML file per temple under this directory. Name it after the slug (e.g., `shenfukung-wenfu.yml`).
2. Populate the required keys: `slug`, `name`, `contact` (hash), and `service_times` (hash). Optional keys include `tagline`, `hero_copy`, `primary_image_url`, `about_html`, and `metadata`.
3. Run `bin/rails temples:seed[slug]` to upsert that temple locally. The task only touches the YAML you specify, so you can onboard temples one at a time.
4. When deploying to a droplet, copy the same YAML file to the server and run `bin/rails temples:seed[slug]` there once so production matches the baseline.

`bin/rails db:seed` automatically loads the profile matching `AppConstants::Project.slug`, but day-to-day edits happen through `/admin/temple/profile`; the YAML + rake task are only for provisioning or resetting a temple.

These configs are developer-facing (not user editable). Admins update temple copy via `/admin/temple/profile` after the initial seed.
