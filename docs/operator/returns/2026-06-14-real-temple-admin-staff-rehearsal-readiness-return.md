# Return: Real Temple Admin/Staff Rehearsal Readiness

Handoff id: `shengfukung-2026-06-14-real-temple-admin-staff-rehearsal-readiness`

Created: 2026-06-14

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch: `offering-setup-admin-workflow`

## Objective

Prepare the real temple admin/staff rehearsal packet required by the V1 acceptance threshold, without contacting a real temple, touching production data, deploying, changing provider/server configuration, accessing secrets, changing real ECPay configuration, or creating automation.

The packet needed to make the next human rehearsal executable:

- staff-facing task script;
- observer checklist;
- success and blocker criteria;
- friction log template;
- post-session decision path;
- local evidence that the script maps to current admin surfaces.

## Reviewed Context Records

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-help-guide-decision.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-14-previous-month-accounting-export-rehearsal-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-13-ecpay-default-path-local-verification-return.md`

## Result

Completed with accepted gaps.

The docs-only rehearsal packet now defines how to run the first real temple admin/staff session and how to record evidence afterward. The actual real temple rehearsal has not happened yet, so this is not final V1 acceptance and not production readiness.

## Packet Summary

Created:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md`

The packet covers:

- session boundary and forbidden production/provider actions;
- temple staff/admin, observer, and coordinator roles;
- preflight checks;
- admin login and orientation;
- temple profile review;
- offering setup draft;
- review/apply understanding;
- registrations and orders;
- cash receipt/admin attestation;
- ECPay status understanding;
- previous-month accounting export;
- end-of-session reflection;
- observer evidence checklist;
- friction log template;
- pass, accepted-with-gaps, retry-required, and blocked criteria;
- V1 blocking rules;
- post-session OperatorKit record path;
- help-guide follow-up topics.

## Files Changed

- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/handoffs/2026-06-14-real-temple-admin-staff-rehearsal-readiness.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-06-14-real-temple-admin-staff-rehearsal-readiness-return.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/eval_records/2026-06-14-real-temple-admin-staff-rehearsal-readiness-eval.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-14-real-temple-admin-staff-rehearsal-readiness-acceptance.md`
- `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/execution_records/2026-06-14-real-temple-admin-staff-rehearsal-readiness-execution.md`

## Local Dry-Run Evidence

Browser surface: Codex in-app Browser against the isolated local review admin server.

Review server:

`127.0.0.1:3312`

Admin login:

`operator-ui-review@example.test`

Environment/database:

`RAILS_ENV=development PGDATABASE=golden_template_review RAILS_SESSION_COOKIE_KEY=_shengfukung_wenfu_review_session`

Checked admin surfaces:

| Surface | URL | Evidence |
| --- | --- | --- |
| Dashboard | `/admin/dashboard` | Loaded with `掌握指標` and `下一步`; no error text. |
| Temple profile | `/admin/temple/profile` | Loaded profile edit surface with temple/public-content fields; no error text. |
| Offerings | `/admin/offerings` | Loaded `供品管理` with link to `供品設定`; no error text. |
| Offering setup index | `/admin/offering-setup` | Loaded `供品設定` and `新增設定草稿`; no error text. |
| New offering setup | `/admin/offering-setup/new` | Loaded `新增供品設定`, `基本資料`, `價格`, `表單結構`, and `報名欄位`; no error text. |
| Orders | `/admin/orders` | Loaded `報名與現場訂單`, filters, payment status controls, and order rows; no error text. |
| Payments | `/admin/payments` | Loaded `付款報表`, `收款依據`, and `上月`; no error text. |
| Payment methods | `/admin/payment_methods` | Loaded `帳務設定`, ECPay fields, and ECPay action link; no error text. |

No create/update/submit action was performed in the browser during this dry-run. The dry-run confirmed route/surface coverage for the rehearsal script, not staff usability.

## Verification

Command:

```bash
git diff --check
```

Result: pass.

Browser/local dry-run:

```text
Signed in to local review admin, opened dashboard, temple profile, offerings, offering setup index, new offering setup, orders, payments, and payment methods.
```

Result: pass.

## Skipped Checks

- Full Rails suite was not run because this was docs-only workflow alignment.
- No product code test suite was run because no product code was intentionally changed.
- No actual real temple staff/admin rehearsal was run.
- No production data was accessed.
- No real payment provider or ECPay network call was made.
- No mobile/Expo check was run because mobile/Expo is outside current scope.
- Comprehensive help guide implementation and links were not built yet by accepted decision.

## Boundary Confirmation

- Product code: not intentionally changed.
- Rails/Vue/Expo/mobile runtime: not changed.
- Existing `ops/docs/`: not touched.
- Production data: not touched.
- Deployment/server config: not changed.
- Secrets: not accessed.
- Payment provider configuration: not changed.
- Real payment provider calls: none.
- Real ECPay merchant configuration: not changed.
- Automation: not created.
- Real temple: not contacted.

## Residual Risk

- This packet proves rehearsal readiness, not product usability with a real temple staff member.
- The first real staff session may still expose wording, layout, workflow, or support-burden gaps.
- Actual V1 acceptance remains blocked until the real temple admin/staff rehearsal evidence is recorded and accepted.
- Production promotion remains blocked by the production-boundary decision.

## Follow-Up Gaps

- Run one real temple admin/staff rehearsal using the packet.
- Record the session with return, eval, acceptance, and execution records.
- Use the session friction to create targeted implementation handoffs only if needed.
- Build the comprehensive help guide after V1 behavior settles.
- Link help guide sections from public temple pages and the admin console after the guide exists.

## Next Owner

Coordinator/implementation thread should create matching eval, acceptance, and execution records, commit and push this checkpoint, then schedule/run the actual real temple admin/staff rehearsal when a participant and safe non-production environment are ready.
