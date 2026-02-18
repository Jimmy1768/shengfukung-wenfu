# ADMIN PERIOD KEY GOVERNANCE PLAN

## Background

- `registration_period_key` is required for service-cycle duplicate guardrails and reporting.
- Temple YAML is the source of truth for allowed period keys and labels.
- Allowing ad-hoc "Other" keys in admin creates config drift and inconsistent patron labels.

## Scope

- Admin portal behavior only (no account-portal UX tasks here).

## Phase A — Remove Ad-Hoc Keys

- [ ] Remove the "Other" period key input from `/admin/services/:id` create/edit forms.
- [ ] Restrict selection to period keys defined in `rails/db/temples/<slug>.yml` `registration_periods`.
- [ ] Reject unknown `registration_period_key` values server-side with a clear validation error.

## Phase B — Data Safety & Migration

- [ ] Audit existing services for keys not present in temple YAML and produce a remediation list.
- [ ] Define a safe fallback/remap process for invalid historical keys before strict validation is enforced.
- [ ] Ensure admin filters/exports continue to support historical data without data loss.

## Phase C — Ops Workflow

- [ ] Document the support workflow for temples requesting new periods (YAML edit + sync + deploy).
- [ ] Link yearly rollover automation commands/runbook once the rollover task ships.

## Phase D — Yearly Period Rollover Automation

- [ ] Build a script/rake task that rolls temple YAML period keys and labels forward by year (e.g., `2026-ghost-month` -> `2027-ghost-month`).
- [ ] Make `--dry-run` the default so ops can preview changes before writing files (`--write` required to persist).
- [ ] Support scope controls (`--slug <temple>` or all temples).
- [ ] Optionally update existing services to the new `registration_period_key` after YAML rollover (with explicit confirmation flag).
- [ ] Document the yearly rollover runbook in ops docs (timing, command examples, verification checklist).
- [ ] Parse period keys with a year-prefix pattern (`^(\\d{4})-(.+)$`), increment only the year, and preserve the suffix exactly (script stays agnostic to custom slug text).
- [ ] Update `label_zh` / `label_en` by replacing the year token only; keep non-year wording unchanged.
- [ ] Skip and report keys that do not match the year-prefix pattern (no silent rewrites).
- [ ] Validate post-rollover uniqueness of period keys per temple and fail fast on collisions.

## Open Questions

- Should unknown historical keys remain readable-only in admin detail views, or be force-remapped immediately?
- Do we need an explicit "archive old period" action, or is yearly rollover + status changes sufficient?
