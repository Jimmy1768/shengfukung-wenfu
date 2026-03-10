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
- Offerings split into `services` and `events`, and can also be treated as either:
  - fixed-price products
  - donations
- V1 pricing rule:
  - if the temple supplied a concrete amount in YAML, treat it as a fixed-price product and prefill/lock that commercial intent into the offering
  - if the amount is blank in YAML, treat it as a donation-style offering where the amount may be entered later by staff/donor
  - YAML remains the source of truth, so future pricing-policy changes should happen by editing YAML and re-syncing offerings rather than ad hoc runtime drift
- One real registrant maps to one registration:
  - one account/self registrant = one registration
  - one dependent registrant = one registration
- Registration and payment should stay effectively one-to-one for clean accounting.
- If a ritual needs extra names or offline execution notes beyond the core registrant, capture them as offering-specific metadata fields in the template/registration form. Do not extend base code with nested multi-person registration structures for temple-specific edge cases.

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

## Status Summary

- [x] Shengfukung V1 offerings YAML is in place and replaces the dummy file.
- [x] Admin offering creation now reads the YAML correctly, with template-owned lifecycle UI and TWD whole-unit pricing input.
- [x] Duplicate-policy behavior is now modeled as an offering-level template/runtime flag (`allow_repeat_registrations`).
- [ ] Duplicate-policy behavior still needs end-to-end validation on the patron registration path.
- [ ] Patron-side registration reuse / write-back still needs full validation against the finalized Shengfukung templates.
- [ ] Production rollout still needs temple bootstrap + first real offering creation on the droplet.

## Phase 1: Source Mapping

- [x] Review every entry in `rails/db/temples/offerings/working-draft.yml`.
- [x] Classify each offering into:
  - `events:` for scheduled/in-person participation
  - `services:` for proxy ritual / temple-handled fulfillment
- [x] Translate draft `registration_period` values into real `registration_period_key` values that exist in `rails/db/temples/shengfukung-wenfu.yml`.
- [x] Decide which draft catalogs become reusable selector lists in YAML `field_settings.options`.

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

- [x] Create `rails/db/temples/offerings/shengfukung-wenfu.yml`.
- [x] Convert draft entries from the current custom `catalogs:` / `offerings:` shape into the app-supported template shape:
  - `events:`
  - `services:`
  - `label`
  - `registration_period_key` for services
  - `defaults`
  - `attributes`
  - `form_fields`
  - `registration_form`
  - `field_settings`
- [x] Keep `working-draft.yml` intact as the reusable scratch file.
- [x] Remove dependency on the misspelled `shenfukung-wenfu.yml` once the real file is in place.

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

- [x] For each offering, decide which fields are:
  - reusable patron profile data
  - per-registration ritual data
  - temporary/transient scheduling data
- [x] Ensure reusable patron data maps cleanly to the existing user metadata sync path.
- [x] Avoid asking admins or patrons to type data that can be:
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

### Shengfukung Phase 3 Decisions

- Reusable patron/profile data for V1:
  - `primary_contact`
  - `phone`
  - `email`
  - `address`
- These fields should be treated as account/dependent-facing identity/contact data and saved back into `users.metadata` for later prefill.
- Per-registration ritual metadata for V1:
  - `dedication_message`
  - `blessing_names`
  - `ancestor_placard_name`
  - `blessing_target_type`
  - `certificate_notes`
  - `table_items`
  - `table_size`
  - `lamp_type`
  - `lamp_location`
  - `certificate_hint`
- Temporary scheduling / fulfillment data for V1:
  - `preferred_date`
  - `preferred_slot`
  - `ceremony_location`
  - `fulfillment_method`
  - `logistics_notes`
- Shengfukung V1 keeps all extra family / ancestor / household / deceased names inside ritual metadata fields rather than expanding the base registration model.
- The registration form should prefer selector-backed values first and free text second. Free text remains acceptable where temple staff simply need something to copy into offline ritual prep.

### First-Pass Duplicate Policy

- Duplicate guard should not be universal. It must follow offering intent, not just `registration_period_key`.
- V1 implementation uses `allow_repeat_registrations: true` on templates that should bypass duplicate lookup at runtime.
- V1 policy for Shengfukung:
  - `incense-donation`: allow repeated registrations
  - `lamp-service`: allow repeated registrations
  - `peace-opera-household`: keep duplicate guard
  - `ghost-festival-table`: keep duplicate guard and rely on `quantity` for multi-table sponsorship
  - `liberation-ritual`: allow repeated registrations
- Rationale:
  - donation and case-based ritual requests can recur for the same registrant within the same period
  - household/cycle-bound offerings should remain one-per-registrant unless the temple later says otherwise
  - `lamp-service` uses one shared offering template with multiple lamp types, so repeated registrations must be allowed unless lamp types are later split into separate offerings

## Complex Offering Review Tracks

Treat these three as explicit review items before calling the Shengfukung config stable. If the answer is unknown, capture it as a clarification question for the temple admin rather than guessing.

### A. `lamp-service`

Current concern:

- The raw draft implies one registration may include multiple people plus lamp-specific ritual details, but the v1 design should keep one real registrant per registration and move extra names into ritual metadata / notes.

Review goals:

- [x] Keep one order = one registrant = one registration.
- [x] Decide which extra ritual names/details, if any, still need to be captured as freeform metadata for temple staff.
- [ ] Confirm whether certificate mailing is a per-order flag.
- [x] Confirm whether lamp selection is one lamp type per registration.

Temple-admin clarification questions:

- [x] One 點燈 registration should represent one real registrant only.
- [x] What extra names or notes, if any, does the temple still need staff to write down outside the core registrant identity?
- [ ] Is `mail_certificate` handled once per registration?
- [x] Is lamp type chosen once per registration?

Phase 3 decision:

- `lamp-service` keeps one real registrant.
- Any extra names the temple still wants written down should live in `blessing_names`.
- Lamp selection stays one choice per registration.
- Certificate handling remains one-per-registration unless temple later says otherwise.

### B. `peace-opera-household`

Current concern:

- The raw draft implies household-level registration plus multiple named family members, but the v1 design should keep one real registrant per registration and move extra family names into ritual metadata / notes.

Review goals:

- [x] Keep one order = one registrant = one registration.
- [x] Decide what extra family/member names or details should be captured as freeform metadata only.
- [ ] Confirm whether bucket position is:
  - required
  - selected from a fixed list
  - one per order only
- [x] Confirm whether the amount is fixed at `1500` or configurable.
- [x] Extra household/member names should live in freeform offering / ritual metadata, not in a nested repeated people structure.

Temple-admin clarification questions:

- [x] 平安戲丁口捐 should stay one registrant per registration.
- [x] What additional family/member names, if any, should staff still record as freeform notes on the registration?
- [ ] Is the斗位 always chosen from the current fixed list, or can staff type a custom value?
- [x] Is `1500` the fixed standard amount for every order?

Phase 3 decision:

- `peace-opera-household` keeps one real registrant.
- Extra household/member names stay in `blessing_names` / ritual notes only.
- `1500` is treated as the temple-supplied fixed-price default for V1.
- Different pricing should be modeled by a different offering or later YAML revision, not by drifting per-registration structure.

### C. `liberation-ritual`

Current concern:

- The draft contains multiple variant types with different data requirements, especially for `拔薦親友亡魂`, but the v1 design should keep one real registrant per registration and prefer variant selector + ritual notes over new base-schema fields.

Review goals:

- [x] Keep one order = one registrant = one registration.
- [x] Make variant type a required selector-backed choice.
- [x] Confirm whether deceased details can stay as formatted ritual notes instead of new base-schema fields.
- [ ] Confirm whether this service is always tied to ghost-month cycle or can also be perennial.

Temple-admin clarification questions:

- [ ] Must the user explicitly choose among:
  - `拔薦歷代祖先`
  - `拔薦親友亡魂`
  - `拔薦冤親債主`
  - `拔薦嬰靈`
- [ ] For `拔薦親友亡魂`, which deceased details are operationally required?
- [x] Are those deceased details used for internal ritual preparation only, or also shown on any public/admin-facing printout?
- [ ] Is 拔薦 only offered during `2026-ghost-month` style cycles, or can it be ordered year-round?

Phase 3 decision:

- `liberation-ritual` keeps one real registrant.
- The specific拔薦類別 should remain a selector-backed choice.
- Deceased / ancestor / related extra names stay in ritual metadata (`blessing_names`, `ancestor_placard_name`, `dedication_message`, `certificate_notes`) rather than new base-schema fields.
- For V1, treat those details as operational ritual-prep notes, not as a new normalized record type.

## Phase 4: Sync + Validation

- [ ] Run, only if updating already-created local/dev offering rows instead of creating fresh ones:
  ```bash
  ruby ops/scripts/sync_offering_configs.rb
  ```
- [x] Confirm fresh Shengfukung offering creation reads updated template metadata:
  - `form_fields`
  - `form_defaults`
  - `form_options`
  - `form_label`
  - `registration_form`
- [x] Verify the admin offering form renders the expected controls with minimal manual typing.
- [ ] Verify registration creation pulls defaults correctly for both admin-assisted and patron-side flows.
- [x] Implement offering-level repeat policy flag for offerings that should not be duplicate-guarded (`incense-donation`, `lamp-service`, `liberation-ritual`).
- [ ] Verify repeatable-registration behavior end to end for the repeat-enabled offerings.

## Phase 5: Manual QA

- [ ] Admin creates one offering from each real Shengfukung template family.
- [ ] Admin order form shows selector-based controls where expected.
- [ ] Patron registration form pre-fills saved user metadata.
- [ ] Completing a registration writes reusable contact/profile values back to `users.metadata`.
- [ ] Second registration for the same patron shows the saved values automatically.

## Open Decisions

- [ ] Which draft fields should map into normalized built-in columns versus remain inside `ritual_metadata`.
- [x] Keep household/person-list ritual offerings inside the current one-registrant model; do not add richer repeatable nested registration structures in v1.
- [ ] Whether some Shengfukung services should be split into multiple simpler templates instead of one complex all-purpose template.
- [ ] Whether `incense-donation` should eventually rename its registration field concept from `dedication_message` to a clearer semantic like `donation_purpose`.

## Acceptance Criteria

- [x] `rails/db/temples/offerings/shengfukung-wenfu.yml` exists and matches the real slug.
- [x] YAML uses the current loader contract (`events:` / `services:`), not the legacy fallback shape.
- [x] Admin forms are largely prefilled and selector-driven.
- [ ] Patron registration reuses saved profile data and persists reusable inputs back to user metadata.
- [x] Dummy offerings config is fully replaced for Shengfukung.
