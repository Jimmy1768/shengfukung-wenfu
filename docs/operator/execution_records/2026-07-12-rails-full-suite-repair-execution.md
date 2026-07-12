# Execution Record: Rails Full-Suite Repair

Execution id: `shengfukung-2026-07-12-rails-full-suite-repair-execution`

Created: 2026-07-12

Owner: Wenfu Control

## Objective

Restore the complete Rails test suite without weakening authorization,
validation, localization, routing, temple-event, registration, payment, or
ledger behavior.

## Workflow

- Initial Handoff packet: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-rails-full-suite-repair.md`
- Retry Handoff packet: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-rails-full-suite-repair-retry.md`
- Initial retry decision: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-rails-full-suite-repair-retry.md`
- Final return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-rails-full-suite-repair-return.md`
- Final acceptance: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-12-rails-full-suite-repair-acceptance.md`

## Outcome

The initial `310 runs, 15 failures, 10 errors` baseline was repaired. Wenfu
Control rejected the first green result because it added English validation
copy under the `zh-TW` locale. The bounded retry removed that file, made the
English assertions locale-explicit, strengthened cash-ledger evidence, and
corrected the return.

Final independent result:

- `310 runs, 1748 assertions, 0 failures, 0 errors, 0 skips`;
- `git diff --check` passed;
- no migration, schema, Vue, mobile, deployment, production, staging, secret,
  payment-provider, real ECPay, or customer-data action occurred.

## Work Mode Update

Repo-local guidance now mirrors OperatorKit commits `5f011c4e` and `9854262d`:
explicit terminal wake is primary, Heartbeat is fallback, and the healthy
one-to-one Wenfu Handoff remains bound and reusable after job completion.

## Residual Risk

The existing Rack `:unprocessable_entity` deprecation warning remains outside
this repair. V1 acceptance remains separately gated by the real temple
admin/staff rehearsal and later help-guide workflow.
