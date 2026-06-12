# Eval Record: Admin Onboarding QA Sweep

Eval id: `shengfukung-2026-06-12-admin-onboarding-qa-sweep-eval`

Created: 2026-06-12

Evaluator: Shengfukung Wenfu coordinator thread

Mode: local prototype QA

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-onboarding-qa-sweep.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-onboarding-qa-sweep-return.md`

## Objective

Preserve concrete route, database, browser, and test evidence for the admin onboarding QA sweep.

## Route And DB Evidence

Command:

```bash
RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session ADMIN_REVIEW_EMAIL=operator-ui-review@example.test ADMIN_REVIEW_PASSWORD='Password123!' bin/rails runner /private/tmp/shengfukung_admin_onboarding_sweep.rb
```

Result: pass.

Observed output:

```json
{
  "ok": true,
  "rails_env": "development",
  "database": "golden_template_review",
  "admin_email": "operator-ui-review@example.test",
  "temple_slug": "operator-ui-review-temple",
  "pages": {
    "dashboard": { "status": 200, "bytes": 25857 },
    "offerings": { "status": 200, "bytes": 24984 },
    "offering_setup_index": { "status": 200, "bytes": 24668 },
    "offering_setup_new": { "status": 200, "bytes": 47020 },
    "gatherings": { "status": 200, "bytes": 24683 },
    "gatherings_new": { "status": 200, "bytes": 48264 }
  },
  "service_draft": {
    "id": 1,
    "slug": "qa-bright-lamp-20260612135235-5c78c9",
    "status": "applied",
    "applied_offering_type": "TempleService",
    "applied_offering_id": 1,
    "applied_service_status": "draft",
    "lamp_option_count": 4
  },
  "event_apply": {
    "id": 2,
    "status_after_apply_attempt": "reviewed",
    "response_status": 422
  },
  "gathering": {
    "id": 1,
    "title": "QA Gathering 20260612135235-5c78c9",
    "status": "draft"
  },
  "yaml_changed": []
}
```

Interpretation:

- Login and key admin routes rendered.
- Offering setup draft lifecycle completed through request stack.
- Reviewed drafts were locked before apply.
- Apply created only a draft `TempleService`.
- Event apply remained blocked.
- Gathering creation and listing worked.
- No YAML files changed during admin actions.

## Browser Evidence

Browser surface: Codex in-app Browser.

Viewport:

```json
{ "width": 1280, "height": 720 }
```

Offering setup screenshot:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-onboarding-qa-sweep-offering-setup.jpg`

Offering setup geometry:

```json
{
  "url": "http://127.0.0.1:3312/admin/offering-setup/new",
  "stage": { "x": 292, "y": 227, "width": 988, "height": 2662 },
  "primary": { "x": 292, "y": 227, "width": 547, "height": 2662 },
  "secondary": { "x": 852, "y": 227, "width": 428, "height": 2662 },
  "sections": [
    { "heading": "基本資料", "rect": { "x": 292, "y": 227, "width": 547, "height": 424 } },
    { "heading": "價格", "rect": { "x": 292, "y": 675, "width": 547, "height": 197 } },
    { "heading": "表單結構", "rect": { "x": 292, "y": 896, "width": 547, "height": 1969 } },
    { "heading": "報名欄位", "rect": { "x": 852, "y": 227, "width": 428, "height": 2214 } }
  ]
}
```

Gathering form screenshot:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-12-admin-onboarding-qa-sweep-gathering-new.jpg`

Gathering form geometry:

```json
{
  "url": "http://127.0.0.1:3312/admin/gatherings/new",
  "stage": { "x": 292, "y": 208, "width": 988, "height": 1055 },
  "primary": { "x": 292, "y": 208, "width": 547, "height": 1055 },
  "secondary": { "x": 852, "y": 208, "width": 428, "height": 1055 },
  "sections": [
    { "heading": "基本資料", "rect": { "x": 292, "y": 208, "width": 547, "height": 367 } },
    { "heading": "收費", "rect": { "x": 292, "y": 575, "width": 547, "height": 247 } },
    { "heading": "時間", "rect": { "x": 292, "y": 822, "width": 547, "height": 298 } },
    { "heading": "封面圖片", "rect": { "x": 852, "y": 208, "width": 428, "height": 542 } },
    { "heading": "地點與狀態", "rect": { "x": 852, "y": 763, "width": 428, "height": 499 } }
  ]
}
```

Interpretation:

- Offering setup rendered a left primary column and right secondary column.
- Gathering form rendered a left primary column and right secondary column.
- The browser did not reproduce the earlier one-long-column layout problem.

## Focused Tests

Command:

```bash
bin/rails test test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/gatherings_layout_test.rb test/integration/admin/layout_css_test.rb test/integration/admin/sessions_test.rb
```

Result:

```text
14 runs, 260 assertions, 0 failures, 0 errors, 0 skips
```

## Decision

pass_for_local_prototype_with_gaps

## Remaining Gaps

- Full Rails suite was not run.
- Large-data accounting QA was not run.
- Mobile screenshots were not captured.
- Production readiness is not accepted by this eval.
