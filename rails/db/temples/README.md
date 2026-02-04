## Temple profile configs

Use the YAML files here as developer tooling to get a temple online quickly. Production data still lives in Postgres; admins edit it via `/admin/temple/profile`.

### Recommended onboarding flow

1. **Intake form** – Send the prospective temple a hosted form (Typeform/Google Form/etc.) that captures email, slug preference, contact info, visit info, and any “about” copy. Export their responses as JSON/YAML and drop it under this directory.
2. **Scripted seed** – Run `bin/rails temples:seed[slug]` to upsert the temple locally. The rake task only reads the specified YAML, so you can rehearse the onboarding before touching production.
3. **Preview** – Spin up Vue + `/admin` and confirm the data renders correctly (hero images will still show placeholders unless you upload them).
4. **Client meeting** – Have the client OAuth a regular user account, then promote that user to `owner` for the new temple using the dev “god” account or a console command.
5. **Production cutover** – Copy the YAML to the server (or paste the JSON into a one-off script) and run `bin/rails temples:seed[slug]` once to create the temple record. After that, all edits happen in `/admin`.

### Notes & future tooling

- **Scripts** – If the intake form can POST JSON to your server, add a small script that writes the payload to `rails/db/temples/<slug>.yml` and optionally invokes `bin/rails temples:seed[slug]`. This removes manual transcription.
- **Dedicated form page** – A lightweight Rails/Vue form that lives behind basic auth could collect the same fields, write them to disk, and show the “next steps” instructions. Not required today, but it speeds up steps 1–3.
- **No per-client YAML in production** – Keep a single starter YAML checked into the repo for cloning/tests. Real clients are onboarded by running the seed once and then editing in the UI; you don’t commit their data.

`bin/rails db:seed` still auto-loads the profile for `AppConstants::Project.slug`. Use `bin/rails temples:seed[slug]` for any additional temples. These files remain developer-facing; treat them as input to the provisioning script, not as the source of truth once the temple is live.
