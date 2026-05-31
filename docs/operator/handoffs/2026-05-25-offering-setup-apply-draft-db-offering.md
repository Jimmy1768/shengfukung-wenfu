# Handoff: Apply Reviewed Offering Setup To Draft DB Offering

Handoff id: `shengfukung-2026-05-25-offering-setup-apply-draft-db-offering`

Created: 2026-05-25

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: prototype

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Expected branch: continue `offering-setup-admin-workflow` unless the implementation thread has a clear reason to branch again.

Expected base context:

- `a613e80 Add offering setup draft workflow`
- `d0f7742 Lock reviewed offering setup drafts`
- accepted with gaps in `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-05-25-offering-setup-admin-workflow-retry-acceptance.md`

## Goal

Implement the next step in the offering setup workflow:

```text
reviewed offering setup draft -> validated supported schema -> draft DB offering
```

The current apply action is intentionally conservative: it marks the setup draft applied but does not create, update, publish, or write live offering config. The next prototype should make apply useful by creating or updating a draft `TempleService` or `TempleEvent` record in Postgres, while keeping publishing and YAML writes out of scope.

## Product Decision

Best next option:

- do not write YAML from admin;
- do not publish live offerings;
- keep YAML-shaped preview as review/audit/developer convenience;
- apply reviewed setup drafts into draft DB offerings;
- validate staff-entered fields against the supported schema before apply.

The app should not accept arbitrary free-text field names as runtime-safe. Unsupported fields should block apply with visible errors.

## Current Architecture Context

Relevant files:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/temple_offering_setup_draft.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offering_setup_drafts_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/views/admin/offering_setup_drafts/show.html.erb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/temple_service.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/models/temple_event.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/helpers/admin/offerings_helper.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/registrations/form_schema.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/offerings/template_parity.rb`

Current behavior:

- setup drafts are temple-scoped;
- draft statuses are `draft`, `submitted`, `reviewed`, `applied`;
- reviewed drafts are locked from edit/update;
- generated YAML-shaped preview exists;
- apply currently marks the draft as applied only;
- live offering creation remains frozen from the existing admin offerings index.

## Required Apply Behavior

Apply should be explicit, auditable, and conservative.

When a reviewed setup draft is applied:

1. Validate generated setup fields against supported field vocabularies.
2. If validation fails, do not create/update any `TempleService` or `TempleEvent`; keep the setup draft reviewed; show errors in the admin UI.
3. If validation passes, create a draft DB offering with `status: "draft"`.
4. Store generated config in the same metadata shape used by the existing template-backed offering flow.
5. Mark the setup draft applied and record the applied target.
6. Log the apply action with the setup draft id and applied offering target.

Apply must not:

- publish the offering;
- write YAML files;
- modify production data outside the local request context;
- deploy or change server config;
- touch secrets or payment provider config;
- change accounting behavior.

## Target Record Tracking

Add a durable link from `TempleOfferingSetupDraft` to the applied offering target.

Preferred shape:

```text
applied_offering_type
applied_offering_id
```

or equivalent explicit fields that can point to `TempleService` or `TempleEvent`.

Apply should be idempotent:

- if the draft already points to an applied target, do not create duplicates;
- if the target remains a draft and the implementation allows re-apply, update only that linked draft target;
- if there is an unrelated existing offering with the same slug, block apply with a clear error instead of overwriting it.

## Schema Validation

Before creating/updating a DB offering, validate all generated field names.

At minimum, validate:

- admin offering setup fields intended for `metadata["form_fields"]`;
- registration form fields intended for `metadata["registration_form"]` if the implementation generates them;
- options only attach to supported option-bearing fields.

Existing supported registration form fields are defined in `Registrations::FormSchema::DEFAULT_SECTIONS`:

```text
order: quantity, unit_price_cents, currency, certificate_number
contact: primary_contact, phone, email, dependents_notes, notes
logistics: preferred_date, preferred_slot, arrival_window, ceremony_location
ritual_metadata: ancestor_placard_name, dedication_message, incense_option, certificate_notes
```

Existing admin offering metadata fields are rendered through `Admin::OfferingsHelper#render_offering_field`. Do not rely on arbitrary free-text fields unless the renderer is extended and tested.

Implementation can introduce a small service or model helper to centralize supported setup field validation. Prefer a testable non-view service over parsing helper code indirectly.

## Service Versus Event Scope

Services are the safest first target because `TempleService` does not require event dates.

`TempleEvent` has event-specific scheduling requirements. If event apply cannot be made safe in this pass, block event-kind apply with a clear message and return that event support requires capturing `starts_on` and `ends_on` or equivalent scheduling fields.

Do not fake event dates just to pass validations.

## Metadata Shape

The applied DB offering should use the existing template-backed metadata conventions where applicable:

```text
metadata["offering_type"]
metadata["form_fields"]
metadata["form_defaults"]
metadata["form_options"]
metadata["form_ui"]
metadata["form_label"]
metadata["registration_form"]
metadata["allow_repeat_registrations"]
```

Do not invent a parallel metadata shape unless there is a strong reason and the return explains it.

## UI Requirements

In the setup draft show/apply UI:

- keep the generated preview visible;
- show whether the draft has already been applied;
- show the linked draft offering when applied;
- show validation errors when apply is blocked;
- make it clear that apply creates a draft offering, not a published/live offering.

## Permissions

Use existing `manage_offerings` for this prototype unless the implementation discovers an existing stronger owner-only pattern that fits naturally.

Do not add a new role system in this pass.

## Non-Goals

- Do not write YAML files from admin.
- Do not publish offerings.
- Do not unfreeze existing live offering creation.
- Do not redesign the offering setup intake UI beyond what is required for supported-schema apply.
- Do not QA or redesign accounting.
- Do not deploy.
- Do not change server config.
- Do not rotate/access secrets.
- Do not touch payment provider configuration.
- Do not touch production data.
- Do not move existing `ops/docs/` history or the current unstaged `ops/docs/commands.md` cleanup.

## Verification Expectations

Run focused Rails tests covering:

- successful apply creates a `TempleService` draft for a valid reviewed service setup;
- applied service metadata matches existing template-backed metadata conventions;
- apply does not publish the offering;
- apply does not write YAML;
- apply records the linked applied offering target;
- re-applying does not create duplicates;
- apply blocks unsupported field names and leaves live/draft offerings unchanged;
- apply blocks unrelated slug collisions;
- reviewed draft locking still holds;
- permission enforcement still holds.

If event apply is blocked for now, add a test proving event-kind apply is blocked clearly.

Also run the existing related tests:

```bash
bin/rails test test/models/temple_offering_setup_draft_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb
```

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
