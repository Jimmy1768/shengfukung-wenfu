# Handoff: Offering Setup Supported Field Catalog

Handoff id: `shengfukung-2026-05-25-offering-setup-supported-field-catalog`

Created: 2026-05-25

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: prototype

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow` unless the implementation thread has a clear reason to branch again.

Expected base context:

- `a613e80 Add offering setup draft workflow`
- `d0f7742 Lock reviewed offering setup drafts`
- `b061592 Apply reviewed setup drafts to draft services`
- `2d1d6d4 Remove unsafe setup draft apply bypass`
- apply-stage accepted with gaps in `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-apply-draft-db-offering-retry-acceptance.md`

## Goal

Make the offering setup workflow usable by temple admins by replacing raw free-text runtime field entry with a supported field catalog.

The current apply path is safe, but the setup intake is still too close to implementation vocabulary. Temple staff should choose from understandable field labels and option controls. The app should store internal field keys only after mapping them from supported choices.

## Product Decision

The next iteration should improve staff-friendly field mapping before expanding event apply or richer offering types.

Reason:

- applying setup drafts into draft DB services is now possible;
- arbitrary free-text field names are unsafe and not usable by nontechnical temple staff;
- event apply and richer registration authoring both depend on a better field catalog;
- YAML should remain preview/export only, not the production write path.

## Current Architecture Context

Relevant files:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/offerings/setup_draft_applier.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/temple_offering_setup_draft.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offering_setup_drafts_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/_form.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/show.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/helpers/admin/offerings_helper.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/registrations/form_schema.rb`

Observed current behavior:

- `Offerings::SetupDraftApplier` owns `SUPPORTED_ADMIN_FIELDS` and `OPTION_BEARING_FIELDS`.
- setup draft form captures `field_requirements_text` as raw lines.
- setup draft form captures `options_text` as text.
- controller now parses options as `field | label | value`.
- the existing form display for saved options should be reviewed because the form originally displayed only label/value lines.
- apply validates supported fields and creates draft `TempleService` records.

## Required Build

Add a small supported field catalog for offering setup.

Preferred shape:

```text
Offerings::SetupFieldCatalog
```

The catalog should be the shared source of truth for:

- supported admin offering field keys;
- staff-facing label;
- short hint/description;
- grouping/category;
- whether the field accepts options;
- maybe field kind such as text/select/date/boolean/number.

The applier should use this catalog instead of maintaining separate constants.

The setup form should use this catalog instead of asking admins to type raw field keys.

## UI Requirements

In the setup draft form:

- replace or supplement the `field_requirements_text` textarea with selectable supported fields;
- show staff-facing labels and short hints;
- store selected field keys in `setup_payload["field_requirements"]`;
- make option entry attach to explicit option-bearing fields;
- prevent option entry for fields that do not accept options where practical;
- preserve existing draft data display/editing enough that old prototype drafts do not become unreadable.

This does not need to be a sophisticated drag-and-drop form builder. A clean checkbox/multi-select field catalog and structured option textarea/select controls are enough for the prototype.

## Supported Field Scope

Start with the fields currently supported by `Admin::OfferingsHelper#render_offering_field` and `Offerings::SetupDraftApplier`.

The catalog should include at least:

```text
fulfillment_method
logistics_notes
lamp_type
lamp_location
blessing_target_type
certificate_hint
blessing_names
ancestor_placard_name if supported by registration form, not admin offering form
table_size
table_items
description
price_cents
currency
```

Be careful to distinguish:

- admin offering setup/display fields rendered by `Admin::OfferingsHelper`;
- registration/order fields supported by `Registrations::FormSchema`;
- fields not currently rendered anywhere.

Do not add fields to the catalog if they cannot render or be consumed safely.

If adding a catalog requires changing supported helper behavior, keep that change tightly scoped and tested.

## Registration Form Boundary

Do not build a full registration form designer in this pass.

However, the implementation may expose a small future-proof distinction:

- "Offering setup fields" for the admin offering record metadata;
- "Registration intake fields" for future order/contact/logistics/ritual metadata.

If this distinction would slow the build, prioritize offering setup fields first and return the registration intake authoring gap clearly.

## Apply Behavior Requirements

Preserve accepted apply behavior:

- only reviewed drafts can apply;
- service drafts apply to `TempleService`;
- event apply remains blocked until scheduling fields are supported;
- applied service remains `status: "draft"`;
- YAML writes remain avoided;
- unsupported field keys still block apply;
- unrelated slug collisions still block apply;
- repeated apply does not create duplicates.

The catalog should make unsupported field errors less likely, but validation must remain in the applier.

## Backward Compatibility

Existing prototype setup drafts may already store:

```text
setup_payload["field_requirements"]
setup_payload["options"]
```

Do not break them.

At minimum:

- show existing selected fields in the new catalog UI when keys are supported;
- preserve unsupported existing fields as visible validation blockers rather than silently dropping them;
- preserve existing option entries or show them in a structured way.

## Tests Expected

Add or update focused tests for:

- field catalog exposes supported field keys, labels, groups, and option-bearing metadata;
- setup draft form can create/update selected fields without raw field-key typing;
- selected catalog fields are persisted to `setup_payload["field_requirements"]`;
- options attach to an option-bearing field and persist as structured data with `field`, `label`, and `value`;
- non-option-bearing option attempts are blocked or rejected before/at apply with visible errors;
- applier uses the catalog for supported field validation;
- old draft payloads with supported keys still display and apply;
- unsupported old draft payloads are visible and still block apply;
- existing apply behavior remains intact.

Run the existing focused suite:

```bash
bin/rails test test/services/offerings/setup_draft_applier_test.rb test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

Also run any new catalog/form tests added.

If the implementation meaningfully changes admin UI rendering, do at least one local manual/browser check if practical and report whether it was run.

## Non-Goals

- Do not write YAML files from admin.
- Do not publish offerings.
- Do not unfreeze existing live offering creation.
- Do not implement event apply in this pass unless it is trivial after catalog work.
- Do not build a full drag-and-drop form builder.
- Do not QA or redesign accounting.
- Do not deploy.
- Do not change server config.
- Do not rotate/access secrets.
- Do not touch payment provider configuration.
- Do not touch production data.
- Do not move existing `ops/docs/` history or the current unstaged `ops/docs/commands.md` cleanup.

## Expected Return

Create or update a detailed return file under:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/`

Do not paste the full return in chat.

Return must include:

- objective;
- completed work or concrete implementation plan;
- repo path;
- branch role and branch name;
- latest commit hash and subject;
- staged, unstaged, untracked, committed, and pushed state;
- ahead/behind state if known;
- files changed;
- verification commands and pass/fail output;
- skipped checks and reasons;
- Rails/Vue/Expo boundary confirmation if touched;
- payment, accounting, temple, and admin boundary confirmation if touched;
- deployment, server, OTA, or public-site impact;
- whether `ops/docs/commands.md` was left untouched;
- whether YAML writes were avoided;
- whether applied offerings remain draft-only;
- whether event apply remains blocked or was safely implemented;
- residual risk;
- production gaps;
- next owner.

## Pointer Chat Format

When returning to the coordinator, use:

```text
Done.

File:
<absolute path to return record>

Next:
<who should review or what should happen next>
```
