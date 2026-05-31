# Handoff: Offering Setup Admin Workflow

Handoff id: `shengfukung-2026-05-25-offering-setup-admin-workflow`

Created: 2026-05-25

Coordinator: Shengfukung Wenfu coordinator thread

Target: Shengfukung Wenfu implementation thread

Mode: prototype

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch role: use a scoped `codex/*` branch for implementation unless the receiving thread has a stronger local reason to stay on `main`.

## Goal

Build the first bounded admin-console workflow for temple offering setup intake.

The product decision is that temple offering onboarding should no longer depend on the owner manually interviewing temple staff, translating photos/documents into YAML, and waiting for external DOCX/form completion. The admin console should collect offering/service/item structure as draft/submission data, then provide a reviewable generated config/metadata preview before anything becomes live.

## Direction

Create a separate "Offering Setup" draft/submission lane. Do not simply unfreeze the existing live offering creation button.

The workflow should support:

- temple/admin creates an offering setup draft;
- draft captures offering category, item label, pricing, period, field requirements, options, and operational notes;
- draft can represent different field needs across offerings without asking temple staff to write YAML;
- draft has explicit status, at minimum draft/submitted/reviewed/applied or an equivalent small state set;
- reviewer/admin can inspect generated YAML-shaped or metadata-shaped output;
- apply is explicit and auditable;
- runtime/live offering config is not silently changed by draft submission.

YAML or YAML-shaped metadata can remain the structured output. The product change is that temple staff should not be expected to author or understand YAML.

## Current Architecture Findings

Offerings templates currently load from:

`/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/offerings/<temple-slug>.yml`

Relevant files:

- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/offerings/template_loader.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/offerings/template_parity.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offerings_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/helpers/admin/offerings_helper.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/services/registrations/form_schema.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/app/controllers/admin/offering_orders_controller.rb`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/offerings/shengfukung-wenfu.yml`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/rails/db/temples/offerings/working-draft.yml`

Observed shape:

- `Offerings::TemplateLoader` reads YAML templates and exposes event/service entries.
- `Admin::OfferingsController` can create offerings from templates and stores template-derived `form_fields`, `form_options`, `registration_form`, and related data in offering metadata.
- `Admin::BaseController#offerings_v1_frozen?` currently returns true, so the existing new-offering UI is intentionally frozen.
- `Admin::OfferingsHelper` renders dynamic sections, but the available field vocabulary is hard-coded in a case statement.
- `Registrations::FormSchema` supports schema-driven order/contact/logistics/ritual metadata forms, but also within a fixed field vocabulary.
- `Offerings::TemplateParity` can report and create missing DB offerings from YAML templates.
- There is no admin submission workflow that turns temple-entered offering setup data into reviewable YAML/config/metadata.

## Implementation Scope

Implement the smallest coherent prototype for offering setup intake.

Preferred shape:

1. Add a DB-backed draft/submission model for temple offering setup data.
2. Add admin routes/controller/views under the existing admin console.
3. Add navigation from the admin offerings area or admin nav.
4. Allow create/edit/submit of setup drafts.
5. Generate a preview of the output that could become the existing template metadata/YAML shape.
6. Add an explicit review/apply boundary.
7. Log apply/review actions through the existing audit pattern where practical.

The first version may keep "apply" conservative:

- acceptable: applied state records that a reviewer accepted the submission and shows copyable YAML/metadata output;
- acceptable: creates/updates a draft DB offering only when the action is explicit and tested;
- not acceptable: silently writes production YAML/config or changes live published offerings as a side effect of submission.

If direct implementation is riskier than expected, return a concrete implementation plan instead of forcing code through.

## Suggested Data Shape

Use repo conventions, but a useful first model would include fields equivalent to:

```text
temple_id
created_by_admin_id
reviewed_by_admin_id
applied_by_admin_id
status
offering_kind
slug
label
registration_period_key
price_cents
currency
setup_payload
generated_template
review_notes
submitted_at
reviewed_at
applied_at
```

Naming is up to the implementation thread if local conventions suggest a better name.

## Important Product Boundaries

Do not treat this as a full accounting QA task.

The accounting/payment/reporting system has real code paths, but only thin data-volume/usefulness validation was observed. Keep accounting QA separate unless the offering setup workflow directly touches payment/reporting behavior.

Do not make production-readiness claims. This is prototype mode.

Do not deploy, change server config, rotate/access secrets, change payment provider configuration, or touch production data.

Do not move existing `ops/docs/` plans, references, tickets, command notes, or deployment notes.

Leave the existing unstaged `ops/docs/commands.md` cleanup untouched.

## UX Requirements

The admin experience should make the workflow clear without requiring YAML knowledge:

- setup drafts are separate from live offerings;
- status is visible;
- required fields have clear labels;
- generated preview is inspectable;
- submission does not imply apply;
- apply/review boundary is explicit.

Avoid long explanatory marketing copy. This is an operational admin workflow.

## Permissions

Use existing admin permission patterns.

Initial assumption:

- creating/editing/submitting setup drafts should require `manage_offerings`;
- review/apply should require `manage_offerings`, and if a stronger existing owner/admin pattern applies, use it and report why.

Do not add broad new role concepts unless the existing system requires it.

## Verification Expectations

Run focused tests for the touched Rails paths.

Expected coverage if implementation is completed:

- model validation/status behavior;
- admin permission enforcement;
- draft create/edit/submit flow;
- generated template preview;
- apply/review boundary does not silently publish or mutate live offerings;
- existing offerings/admin views still work.

Run existing related tests where practical, especially:

- admin offerings tests;
- offerings template parity tests;
- registration form schema/order tests if touched;
- payment/accounting tests only if touched.

## Expected Return

Create a detailed return file under:

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
