# Acceptance: Rails Full-Suite Repair Retry

Acceptance id: `shengfukung-2026-07-12-rails-full-suite-repair-retry`

Created: 2026-07-12

Reviewer: Wenfu Control

Related handoff: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-07-12-rails-full-suite-repair.md`

Related return: `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-12-rails-full-suite-repair-return.md`

## Decision

retry_required

## Decision Reason

Independent verification confirmed the repair is functionally close:

- `bin/rails test` passed with `310 runs, 1745 assertions, 0 failures, 0 errors, 0 skips`;
- `git diff --check` passed;
- the route-helper, serializer namespace, authorization-fixture, event-date, registration-shape, and payment-fixture changes are bounded and consistent with current code.

The repair is not accepted yet because
`rails/config/locales/errors.zh-TW.yml` adds English validation messages under
the Traditional Chinese locale solely to satisfy tests that assert English
strings. That would make user-visible `zh-TW` validation copy incorrect. The
packet required preserving Traditional Chinese behavior and allowed validation
tests to make their locale explicit instead.

The return also lists `rails/test/test_helper.rb` as changed even though it is
not present in the working-tree diff. The retry must correct this evidence
inconsistency.

## Required Retry

- Remove the English-under-`zh-TW` locale file.
- Make the affected model validation tests explicitly use `:en` when asserting English validation messages, or use correct Traditional Chinese translations and assertions. Do not preserve incorrect locale content merely to keep the suite green.
- Strengthen the cash recorder test so it verifies the created ledger entry's durable identifying data, not only a global count increase.
- Update the durable return so `changed_paths` exactly matches the final working tree.
- Re-run the complete Rails suite and `git diff --check`.

## Promotion Allowed

No. Repair remains uncommitted pending the bounded retry.
