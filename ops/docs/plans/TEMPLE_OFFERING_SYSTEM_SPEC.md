# Temple Offering System Spec

## Purpose

- Define the canonical offering-model vocabulary used when onboarding a temple from filled-in offering worksheets.
- Prevent template drift, year-coupled naming, and accidental mixing of unrelated offerings into one form.
- Keep the current YAML migration path conservative while making the long-term model explicit.

## Core Entities

### 1. `offering_family`

High-level classification shared across temples.

Recommended families:

- `donation`
- `lamp`
- `ritual_registry`
- `altar_bucket`
- `offering_table`
- `memorial_rite`
- `gathering`

### 2. `offering_template`

Canonical temple-defined offering.

Responsibilities:

- owns form structure
- owns conditional logic
- owns shared option references
- owns output artifact policy

Rules:

- do not encode year inside template names
- do not collapse unrelated offerings into one template
- template name should match the temple’s canonical offering identity

### 3. `offering_variant`

Selectable subtype within an offering template.

Examples:

- `點燈作業` -> `光明燈` / `文昌燈` / `財神燈` / `太歲燈`
- `祖先拔薦` -> `歷代祖先` / `親友亡魂` / `冤親債主` / `嬰靈`

Rules:

- variants stay inside one template only when they are true subtypes of the same offering
- variants should not be used to hide multiple unrelated business processes inside one offering

### 4. `offering_instance`

Real-world publishable run of a template.

Possible fields:

- `year`
- `period_name`
- `starts_on`
- `ends_on`
- `status`
- `price_override`
- `capacity`

Examples:

- `普渡供桌 114年`
- `禮斗法會 114年正月`
- `點燈作業 114年`

Rules:

- year belongs on the instance, not the template
- period-specific publication belongs on the instance

### 5. `registration`

User submission attached to one `offering_instance`.

Rules:

- registration data should be driven by the template and, where needed, the selected variant
- registration should not be overloaded with generated print/output concerns

### 6. `output_artifact`

Generated after registration.

Examples:

- `receipt`
- `certificate`
- `lamp_placard`
- `table_placard`
- `ritual_list`
- `memorial_document`

Rules:

- output artifacts are not registration fields
- output artifacts are generated from registration data plus template/instance context

## Offering Type Distinctions

### Offering Event

Temple offering with a designated time period.

Examples:

- period-bound ritual cycle
- ceremony window with explicit start/end dates

### Offering Service

Temple offering without a fixed meetup time, often ongoing or temple-handled.

Examples:

- 點燈
- long-running prayer/service workflows

### Gathering

Non-offering event with time/location. May be temple or offsite, free or paid.

Rule:

- gatherings are not interchangeable with offering events/services

## Shared Catalog Rule

Shared option catalogs must be centralized and referenced, not duplicated ad hoc inside multiple offerings.

Examples:

- deity lists
- bucket-position lists
- memorial-type lists

## Shengfukung Canonical Templates

Current canonical temple-defined offering templates:

1. `香油捐獻`
2. `平安戲丁口捐`
3. `點燈作業`
4. `祖先拔薦`
5. `禮斗法會`
6. `普渡供桌`

## Shengfukung-Specific Clarifications

- `平安戲丁口捐` and `禮斗法會` must remain separate offerings.
- `ritual_bucket_positions` belong to `禮斗法會`, not `平安戲丁口捐`.
- `平安戲丁口捐` remains a simpler household-based offering.
- `禮斗法會` is period-specific and owns deity / bucket selection behavior.
- `zodiac` and `heavenly_stem_earthly_branch` are derived values, not canonical stored fields.
- lunar calendar should default to `true` where ritual logic requires it.

## Conservative YAML Guidance

- keep YAML draft style conservative
- preserve minimum-change migration path from current draft/templates
- do not refactor unrelated offerings while clarifying one temple’s model
- leave `TODO` notes where temple admins must confirm exact fields instead of inventing certainty

## Onboarding Rule For Temple-Filled Forms

When a temple returns a filled offering worksheet:

1. resolve each row into a canonical `offering_template`
2. classify it into an `offering_family`
3. determine whether subtypes are true `offering_variants`
4. keep year/season/time-window details on `offering_instance`
5. keep generated printouts under `output_artifact`, not registration fields
6. centralize any repeated selector catalog before updating temple YAML

This worksheet-to-model pass should happen before sync/import work so the YAML stays structurally clean.
