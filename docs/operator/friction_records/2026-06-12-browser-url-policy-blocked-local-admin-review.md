# Friction Record: Browser URL Policy Blocked Local Admin Review

Friction id: `shengfukung-2026-06-12-browser-url-policy-blocked-local-admin-review`

Created: 2026-06-12

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-12-offering-setup-browser-ui-review.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-12-offering-setup-browser-ui-review-return.md`

Related acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-12-offering-setup-browser-ui-review-acceptance.md`

Related execution record: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-12-offering-setup-browser-ui-review-execution.md`

## Type

workflow_tooling

## Summary

The Codex in-app Browser plugin blocked further local admin page access after submitting disposable test credentials to the local Rails test server.

## Impact

The OperatorKit browser/manual UI review could not complete. The product behavior under review remains unverified in a real browser.

## Trigger

Attempted local-only browser review:

- Rails environment: `test`;
- URL: `http://127.0.0.1:3312/admin/login`;
- data: disposable Rails test database admin/temple records;
- action: submit local test credentials through the in-app browser.

## Observed Block

```text
Browser Use rejected this action due to browser security policy. Reason: Browser Use cannot visit the requested page because its URL is blocked by the Browser Use URL policy.
```

The Browser plugin instructions prohibit trying to complete the same blocked browser outcome through alternate browser surfaces or policy workarounds.

## Not A Product Finding

No Shengfukung Wenfu product defect was confirmed. The browser review was blocked before the offering setup workflow screens could be reviewed.

## Suggested Future Handling

- Treat authenticated local admin browser reviews as needing a preflight before committing to a browser/manual OperatorKit handoff.
- If the Browser plugin blocks the authenticated local path, stop and record `blocked` rather than substituting an unapproved browser surface.
- Retry only when a permitted local browser-review path is available.

## Production Safety

- No deployment.
- No server config change.
- No secrets accessed.
- No payment changes.
- No production data touched.
- No YAML writes.
