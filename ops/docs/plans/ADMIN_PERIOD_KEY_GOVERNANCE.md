# ADMIN PERIOD KEY GOVERNANCE PLAN

## Background

- `registration_period_key` is required for service-cycle duplicate guardrails and reporting.
- Temple YAML is the source of truth for allowed period keys and labels.
- Offering template YAML must only reference keys defined in the matching temple YAML.
- `perennial` is a real evergreen period key, not a placeholder; use it for year-round services that are not tied to a specific seasonal cycle.
- Allowing ad-hoc "Other" keys in admin creates config drift and inconsistent patron labels.

## Scope

- Admin portal behavior only (no account-portal UX tasks here).

## Phase A — Remove Ad-Hoc Keys

- [x] Remove the "Other" period key input from `/admin/services/:id` create/edit forms.
- [x] Restrict selection to period keys defined in `rails/db/temples/<slug>.yml` `registration_periods`.
- [x] Reject unknown `registration_period_key` values server-side with a clear validation error.

## Phase B — Data Safety & Migration

- [x] Audit existing services for keys not present in temple YAML and produce a remediation list.
- [x] Define a safe fallback/remap process for invalid historical keys before strict validation is enforced.
- [x] Ensure admin filters/exports continue to support historical data without data loss.

### Phase B Runbook

- Audit invalid keys (all temples): `cd rails && bin/rails registration_period_keys:audit OUTPUT=tmp/registration_period_key_audit.json`
- Audit one temple: `cd rails && bin/rails registration_period_keys:audit SLUG=shengfukung-wenfu OUTPUT=tmp/registration_period_key_audit.json`
- Dry-run fallback remap: `cd rails && bin/rails registration_period_keys:remap_invalid SLUG=shengfukung-wenfu FALLBACK_KEY=perennial`
- Apply fallback remap: `cd rails && bin/rails registration_period_keys:remap_invalid SLUG=shengfukung-wenfu FALLBACK_KEY=perennial APPLY=true`
- Remap stores prior invalid keys in `metadata.legacy_registration_period_keys` on services + registrations before rewriting.

## Phase C — Ops Workflow

- [x] Document the support workflow for temples requesting new periods (YAML edit + sync + deploy).
- [x] Link yearly rollover automation commands/runbook once the rollover task ships.

### Phase C Support Workflow (Temples Requesting New Periods)

1. Edit `rails/db/temples/<slug>.yml` and update `registration_periods` with the new key + labels.
2. Edit `rails/db/temples/offerings/<slug>.yml` so every service `registration_period_key` still points at a valid key from step 1.
3. Sync offering template configs so existing DB-backed offerings stay aligned: `ruby ops/scripts/sync_offering_configs.rb`.
4. Re-seed that temple from YAML if temple profile records also changed: `cd rails && bin/rails "temples:seed[<slug>]"`.
5. Run governance audit for that temple and save report: `cd rails && bin/rails registration_period_keys:audit SLUG=<slug> OUTPUT=tmp/registration_period_key_audit.json`.
6. If audit finds historical invalid keys, run remap dry-run first, then apply using approved fallback key.
7. Deploy updated app artifacts (`bin/deploy_vue <slug>`) and complete normal backend deploy flow.

Reference commands: `ops/docs/reference/commands.md`.

## Phase D — Yearly Period Rollover Automation

- [x] Build a script/rake task that rolls temple YAML period keys and labels forward by year (e.g., `2026-ghost-month` -> `2027-ghost-month`).
- [x] Make dry-run the default so ops can preview changes before writing files (`WRITE=true` required to persist).
- [x] Support scope controls (`SLUG=<temple>` or all temples).
- [x] Optionally update existing services to the new `registration_period_key` after YAML rollover (explicit `UPDATE_SERVICES=true` flag).
- [x] Document the yearly rollover runbook in ops docs (timing, command examples, verification checklist).
- [x] Parse period keys with a year-prefix pattern (`^(\\d{4})-(.+)$`), increment only the year, and preserve the suffix exactly (script stays agnostic to custom slug text).
- [x] Update `label_zh` / `label_en` by replacing the year token only; keep non-year wording unchanged.
- [x] Skip and report keys that do not match the year-prefix pattern (no silent rewrites).
- [x] Validate post-rollover uniqueness of period keys per temple and fail fast on collisions.

### Phase D Rollover Runbook

1. Dry-run one temple and inspect report:
   - `cd rails && bin/rails registration_period_keys:rollover_year SLUG=shengfukung-wenfu OUTPUT=tmp/registration_period_rollover.json`
2. Dry-run all temples:
   - `cd rails && bin/rails registration_period_keys:rollover_year OUTPUT=tmp/registration_period_rollover.json`
3. Apply YAML rollover for one temple:
   - `cd rails && bin/rails registration_period_keys:rollover_year SLUG=shengfukung-wenfu WRITE=true OUTPUT=tmp/registration_period_rollover_apply.json`
4. Apply YAML rollover + service key updates (explicit flag):
   - `cd rails && bin/rails registration_period_keys:rollover_year SLUG=shengfukung-wenfu WRITE=true UPDATE_SERVICES=true OUTPUT=tmp/registration_period_rollover_apply.json`
5. Verify:
   - confirm `rails/db/temples/offerings/<slug>.yml` service `registration_period_key` values still match the rolled temple periods
   - run `registration_period_keys:audit` and confirm no unexpected invalid keys were introduced
   - review service list in admin for expected period labels/keys
   - deploy normally after verification

## Open Questions

- Should unknown historical keys remain readable-only in admin detail views, or be force-remapped immediately?
- Do we need an explicit "archive old period" action, or is yearly rollover + status changes sufficient?
