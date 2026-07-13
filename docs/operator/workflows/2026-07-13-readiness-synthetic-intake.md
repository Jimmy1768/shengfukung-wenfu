# Workflow Record: Readiness Synthetic Intake

Record id: `shengfukung-2026-07-13-readiness-synthetic-intake`

Created: 2026-07-13

Owner: Wenfu Handoff `019f55bd-3447-74f3-8225-eabfdc511e64`

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

## Purpose

Provide one durable, human-facing, non-secret intake example for WR-4.

This is a synthetic operator-assisted onboarding intake for a single Taiwan
temple service offering. It is intentionally realistic enough to exercise the
current YAML and setup contract, but it does not represent a real temple,
participant, merchant account, or production launch.

## Synthetic Intake

### Temple

- temple slug: `readiness-synthetic`
- temple name: `台灣祈福示範宮`
- contact name: `林示範`
- contact phone: `02-0000-1234`
- address: `台北市中正區驗證路 108 號`
- public map url: `https://maps.example.test/readiness-synthetic`
- service notes: accepts onsite confirmation and operator-assisted setup only

### Offering

- offering type: service
- offering slug: `readiness-peace-lamp`
- offering label: `平安祈福燈`
- category: `lamp`
- registration period key: `2026-q4-peace-light`
- registration period label zh: `2026 第四季平安祈福`
- registration period label en: `Q4 2026 Peace Blessing Cycle`
- status at apply time: draft only
- price: `NT$1,200`
- currency: `TWD`
- public description:
  `適用季度平安祈福燈服務，信眾可登記祈福姓名、聯絡方式與偏好時段，由廟方代為安燈與後續通知。`
- operator operational notes:
  `季度批次處理，先由廟方確認燈別與安燈時段，再安排證書與通知。`

### Admin Setup Fields

- `offering_type`
- `price_cents`
- `currency`
- `description`
- `lamp_type`
- `lamp_location`
- `fulfillment_method`
- `certificate_hint`
- `logistics_notes`

### Admin Option Lists

- `lamp_type`
  - `平安燈`
  - `光明燈`
  - `闔家燈`
- `fulfillment_method`
  - `廟方代辦`
  - `現場確認`

### Registration Intake Fields

- order
  - `quantity`
  - `unit_price_cents`
  - `currency`
  - `certificate_number`
- contact
  - `primary_contact`
  - `phone`
  - `email`
  - `notes`
- logistics
  - `preferred_date`
  - `preferred_slot`
- ritual metadata
  - `ancestor_placard_name`
  - `dedication_message`
  - `certificate_notes`

### Registration Field Settings

- `preferred_slot`
  - `上午`
  - `下午`
  - `晚上`
- `ancestor_placard_name`
  - `allow_multiple: true`
- `dedication_message`
  - `allow_multiple: true`

## Operator Mapping To Configuration

The operator translates this intake into repository configuration. Temple staff
do not edit YAML directly.

| Intake source | Config target |
| --- | --- |
| temple slug/name/contact/map | `rails/db/temples/readiness-synthetic.yml` top-level `slug`, `name`, `contact` |
| registration period labels | `rails/db/temples/readiness-synthetic.yml` `registration_periods` |
| offering slug/label | `rails/db/temples/offerings/readiness-synthetic.yml` `services[0].slug` and `label` |
| service category and currency | `services[0].defaults.offering_type`, `services[0].defaults.currency` |
| price and description | `services[0].attributes.price_cents`, `currency`, `description` |
| admin setup fields | `services[0].form_fields` |
| admin option lists | `services[0].options` |
| registration sections | `services[0].registration_form.sections` |
| registration defaults | `services[0].registration_form.defaults` |
| registration field settings | `services[0].registration_form.field_settings` |
| repeat registration behavior | `services[0].allow_repeat_registrations` |

## Boundary

- synthetic only
- no secrets
- no real temple
- no real ECPay merchant data
- no production activation
