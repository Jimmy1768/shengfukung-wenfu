# Eval Record: Admin Gathering Form Browser Review

Eval id: `shengfukung-2026-06-12-admin-gathering-form-browser-eval`

Created: 2026-06-12

Evaluator: Shengfukung Wenfu coordinator thread

Mode: local prototype browser review

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-admin-gathering-form-two-column.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-admin-gathering-form-two-column-return.md`

Related acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-admin-gathering-form-two-column-acceptance.md`

Related execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-admin-gathering-form-two-column-execution.md`

## Objective

Close the visual/browser gap from the gathering two-column layout checkpoint by taking over the local authenticated admin UI in the in-app Browser.

## Environment

- Local server: `RAILS_ENV=test`, `WEB_CONCURRENCY=0`
- URL: `http://127.0.0.1:3312`
- Browser surface: Codex in-app Browser
- Admin account: disposable local reviewer account only
- Server PID during review: `35917`

## Browser Steps

1. Opened `/admin/login`.
2. Submitted disposable reviewer credentials.
3. Confirmed redirect to `/admin/dashboard`.
4. Opened `/admin/gatherings/new`.
5. Captured DOM and layout geometry for the gathering form.
6. Captured viewport screenshot evidence in the in-app Browser.
7. Filled and submitted a disposable gathering record.
8. Confirmed redirect to `/admin/gatherings`.
9. Confirmed the disposable gathering title appeared on the listing page.

## Layout Evidence

Viewport:

```json
{ "width": 1280, "height": 720 }
```

Gathering form stage geometry:

```json
{ "x": 292, "y": 208, "width": 973, "height": 1055 }
```

Section geometry:

```json
[
  { "heading": "基本資料", "x": 292, "y": 208, "width": 538, "height": 367 },
  { "heading": "收費", "x": 292, "y": 575, "width": 538, "height": 247 },
  { "heading": "時間", "x": 292, "y": 822, "width": 538, "height": 298 },
  { "heading": "封面圖片", "x": 844, "y": 208, "width": 421, "height": 542 },
  { "heading": "地點與狀態", "x": 844, "y": 763, "width": 421, "height": 499 }
]
```

Interpretation:

- primary column rendered at `x=292`;
- secondary column rendered at `x=844`;
- the gathering form no longer renders as one long narrow column at desktop width.

## Create Flow Evidence

Disposable local record submitted:

```text
Browser Test Gathering 1781259954731
```

Result:

- browser navigated to `http://127.0.0.1:3312/admin/gatherings`;
- listing page contained the disposable title.

## Decision

pass_for_local_prototype

## Boundary

- No product/code changes were made during this eval.
- No deployment.
- No server config change.
- No secret access or rotation.
- No payment/accounting behavior change.
- No production data.
- No YAML writes.

## Remaining Gaps

- Full Rails suite was not rerun during this browser eval.
- Browser server still used `RAILS_ENV=test`, so later Rails test runs can wipe this disposable browser data/session.

## Next

Coordinator should update the gathering acceptance trail to reference this eval and commit the docs-only audit update.
