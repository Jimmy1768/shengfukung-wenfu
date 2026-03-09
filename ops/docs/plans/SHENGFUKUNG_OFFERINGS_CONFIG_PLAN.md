# Shengfukung Offerings Config Plan

## Purpose

- Replace the current dummy / placeholder offerings config for `shengfukung-wenfu` with the real temple offering definitions.
- Preserve YAML as the single source of truth for offering templates.
- Make the admin onboarding flow low-friction: prefill as much as possible, prefer selectors over free text, and keep repeated patron data flowing through user metadata.

## Product Rules

- `rails/db/temples/offerings/<slug>.yml` is the single source of truth for offering template shape.
- Admin offering creation should start from YAML-backed templates, not from blank forms.
- Predetermined values belong in YAML whenever possible:
  - `attributes` for core event/service columns
  - `defaults` for metadata defaults
  - `field_settings.options` for selector choices
  - `field_settings.allow_multiple` only where collecting reusable option history is actually helpful
- Registration forms should collect:
  - recurring patron/contact data once, then save it back to `users.metadata`
  - offering-specific ritual/logistics data only when needed for fulfillment
- Patron/admin registration entry should reuse saved patron metadata on future registrations.

## Current Repo Reality

- The active loader contract is `events:` + `services:` in [`Offerings::TemplateLoader`](/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/offerings/template_loader.rb:31).
- Legacy `offerings:` still parses only as a fallback and should not be the long-term format.
- `rails/db/temples/offerings/working-draft.yml` is now the persistent staging draft file for new temple onboarding.
- The current temple-specific file is misnamed as `rails/db/temples/offerings/shenfukung-wenfu.yml`; the real slug is `shengfukung-wenfu`, so the finalized source-of-truth file must become `rails/db/temples/offerings/shengfukung-wenfu.yml`.

## Goal State

Deliver a finalized `rails/db/temples/offerings/shengfukung-wenfu.yml` that:

- uses `events:` and `services:` top-level sections
- encodes the real Shengfukung offerings from `working-draft.yml`
- minimizes admin typing through defaults and selectors
- maps registration fields to the current admin/account registration schema
- syncs cleanly into offering metadata via `ruby ops/scripts/sync_offering_configs.rb`

## Phase 1: Source Mapping

- [x] Review every entry in `rails/db/temples/offerings/working-draft.yml`.
- [ ] Classify each offering into:
  - `events:` for scheduled/in-person participation
  - `services:` for proxy ritual / temple-handled fulfillment
- [ ] Translate draft `registration_period` values into real `registration_period_key` values that exist in `rails/db/temples/shengfukung-wenfu.yml`.
- [ ] Decide which draft catalogs become reusable selector lists in YAML `field_settings.options`.

### Known Mapping Notes

- `incense-donation` is a `service`.
- `lamp-service` is a `service`.
- `peace-opera-household` is a `service`.
- `ghost-festival-table` is a `service`.
- `liberation-ritual` is a `service`.
- If Shengfukung later adds real scheduled gatherings/events, those should be modeled separately instead of forcing ritual services into `events:`.

### Phase 1 Findings (2026-03-09)

- The current `working-draft.yml` is a domain-spec draft, not a loader-ready template file.
- The app currently consumes `events:` and `services:` via `Offerings::TemplateLoader`.
- The existing real temple template file is misnamed as `shenfukung-wenfu.yml`; this must be replaced by `shengfukung-wenfu.yml`.
- All five reviewed Shengfukung draft entries are better modeled as `services:` under the current product rules.

### Draft Entry Mapping

| Draft slug | Draft type | Real kind | Draft period | Candidate real `registration_period_key` | Notes |
| --- | --- | --- | --- | --- | --- |
| `incense-donation` | `donation` | `service` | `perennial` | `perennial` | Simple evergreen donation flow; should be the easiest service template. |
| `lamp-service` | `ritual_service` | `service` | `yearly` | `2026-lantern` | Best fit for current point-in-time temple periods. If temple later supports year-round lamp sales, split into perennial vs campaign-specific templates. |
| `peace-opera-household` | `ritual_service` | `service` | `yearly` | `perennial` or `2026-lantern` | Needs product decision. It is not clearly tied to ghost month; likely an evergreen/seasonal ritual service. |
| `ghost-festival-table` | `ritual_service` | `service` | `festival_specific` | `2026-ghost-month` | Strong direct mapping; should stay cycle-specific. |
| `liberation-ritual` | `ritual_service` | `service` | `event_specific` | `2026-ghost-month` or `perennial` | Needs product decision. If Shengfukung only performs拔薦 during a specific annual rite, tie it to that cycle; otherwise model as evergreen. |

### Draft Catalog Candidates For `field_settings.options`

- `lamp_types`
- `ritual_bucket_positions`
- `liberation_types`

These should become selector-backed field settings in the finalized YAML rather than free text wherever the current registration schema can support that shape cleanly.

## Phase 2: YAML Contract Conversion

- [ ] Create `rails/db/temples/offerings/shengfukung-wenfu.yml`.
- [ ] Convert draft entries from the current custom `catalogs:` / `offerings:` shape into the app-supported template shape:
  - `events:`
  - `services:`
  - `label`
  - `registration_period_key` for services
  - `defaults`
  - `attributes`
  - `form_fields`
  - `registration_form`
  - `field_settings`
- [ ] Keep `working-draft.yml` intact as the reusable scratch file.
- [ ] Remove dependency on the misspelled `shenfukung-wenfu.yml` once the real file is in place.

### Conversion Guidance

- Use `attributes` for fixed values like:
  - `price_cents`
  - `currency`
  - `description`
- Use `registration_form.sections` to separate:
  - `order`
  - `contact`
  - `logistics`
  - `ritual_metadata`
- Use `field_settings.options` for closed sets such as:
  - lamp types
  -斗位 / bucket positions
  - liberation types
- Prefer selectors first, then text only where the temple truly needs arbitrary input.

## Phase 3: Registration UX Design

- [ ] For each offering, decide which fields are:
  - reusable patron profile data
  - per-registration ritual data
  - temporary/transient scheduling data
- [ ] Ensure reusable patron data maps cleanly to the existing user metadata sync path.
- [ ] Avoid asking admins or patrons to type data that can be:
  - inferred
  - selected
  - defaulted
  - copied from prior registrations

### Reusable Data Candidates

- primary contact
- phone
- email
- address

### Usually Non-Reusable / Offering-Specific

- lamp choice for a specific order
- bucket position
- dedication message
- deceased / ancestor ritual metadata
- table number / ceremony placement

## Phase 4: Sync + Validation

- [ ] Run:
  ```bash
  ruby ops/scripts/sync_offering_configs.rb
  ```
- [ ] Confirm each Shengfukung offering receives updated metadata:
  - `form_fields`
  - `form_defaults`
  - `form_options`
  - `form_label`
  - `registration_form`
- [ ] Verify the admin offering form renders the expected controls with minimal manual typing.
- [ ] Verify registration creation pulls defaults correctly for both admin-assisted and patron-side flows.

## Phase 5: Manual QA

- [ ] Admin creates one offering from each real Shengfukung template family.
- [ ] Admin order form shows selector-based controls where expected.
- [ ] Patron registration form pre-fills saved user metadata.
- [ ] Completing a registration writes reusable contact/profile values back to `users.metadata`.
- [ ] Second registration for the same patron shows the saved values automatically.

## Open Decisions

- [ ] Which draft fields should map into normalized built-in columns versus remain inside `ritual_metadata`.
- [ ] Whether household/person-list ritual offerings need richer repeatable nested data than the current registration schema supports.
- [ ] Whether some Shengfukung services should be split into multiple simpler templates instead of one complex all-purpose template.

## Acceptance Criteria

- [ ] `rails/db/temples/offerings/shengfukung-wenfu.yml` exists and matches the real slug.
- [ ] YAML uses the current loader contract (`events:` / `services:`), not the legacy fallback shape.
- [ ] Admin forms are largely prefilled and selector-driven.
- [ ] Patron registration reuses saved profile data and persists reusable inputs back to user metadata.
- [ ] Dummy offerings config is fully replaced for Shengfukung.
