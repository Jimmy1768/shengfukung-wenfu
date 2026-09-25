# Future Work

## TempleMate Post-UI V1 Sequence

Phases 1–3 of the TempleMate cash-only demo, development-client parity, and
Director UI refinement are complete. The next action is a separately committed
Phase 4 read-only readiness scan for real Google/Apple native OAuth and
physical-device validation. The dummy OAuth driver and the local/test adapters
it belonged to are gone; there is one adapter and it talks to a real server.
Web OAuth still does not prove real native provider behaviour. The Apple account-
resolution rollout and historical user 22 recovery remain separate Control A
work; this sequence grants no user/account action.

After Phase 4, Phase 5 is distribution readiness only. Phase 6 separately
authorizes each production-identity TestFlight IPA, Google Play AAB, or optional
Android APK packet. Phase 7 is client-meeting and beta observation/acceptance.
DojoMate-Expo may later inform operational profiles, artifacts, and ledgers,
but is not OAuth evidence and contributes no inherited identifiers, secrets,
signing, versions, or commands. `1.0.0 / Android 1 / iOS 1` remains unchanged.

Stripe platform billing and live ECPay activation remain deferred until a first
real client and a separately authorized provider workflow.

## Deferred First-Tenant Activation

First-tenant activation is deferred and is not authorized by local evidence. No
real client is currently named, and no local acceptance simulates one.

- A real approved temple and owner, reviewed offering DOCX/intake
  classification, and any required service/event workflow remain unavailable
  and must not be simulated.
- ECPay credential entry is staged configuration only. Real merchant,
  callback, payment, refund, and accounting verification require a separately
  authorized provider-safe workflow.
- Stripe catalog/configuration and local code evidence do not create a
  customer, Checkout, invoice, subscription, payment, or entitlement. A
  controlled setup and matching signed webhook event remain future proof.
- Timers are installed but disabled. Enabling timers, first collection,
  deployment, production migration/data work, and provider actions require a
  future target-specific packet with exact target, commit, rollback,
  verification, monitoring, and authority.

## Retained Active Or Deferred Plans

These paths remain active or deferred source material; this inventory does not
assign equal priority or implementation readiness.

- `ops/docs/plans/ACCOUNT_CLOSURE_AND_PRIVACY_REQUESTS_PLAN.md`
- `ops/docs/plans/ACCOUNT_PASSWORD_ADDITION_PLAN.md`
- `ops/docs/plans/ACCOUNT_PORTAL_REFINE.md`
- `ops/docs/plans/ADMIN_ACCOUNTING_AND_ARCHIVES_WORKFLOW_PLAN.md`
- `ops/docs/plans/ADMIN_PERIOD_KEY_GOVERNANCE.md`
- `ops/docs/plans/ADMIN_PORTAL_REFINE.md`
- `ops/docs/plans/ADMIN_ROLE_MODEL_SIMPLIFICATION_PLAN.md`
- `ops/docs/plans/ADMIN_ROLE_TRANSITIONS_PLAN.md`
- `ops/docs/plans/API_ABUSE_BLACKLIST_GOVERNANCE_PLAN.md`
- `ops/docs/plans/DEPLOYMENT_READINESS.md`
- `ops/docs/plans/EMAIL_DELIVERY_QUEUE_AND_DEDUPE_PLAN.md`
- `ops/docs/plans/EXPO_ACCOUNT_APP_READINESS_AND_PARITY_PLAN.md`
- `ops/docs/plans/EXPO_OAUTH_PHASE_PLAN.md`
- `ops/docs/plans/EXPO_PAYMENT_PHASE_PLAN.md`
- `ops/docs/plans/OAUTH_GOOGLE_SUBJECT_COMPATIBILITY_REPAIR_PLAN.md`
- `ops/docs/plans/OAUTH_PROVIDERS_SETUP_PLAN.md`
- `ops/docs/plans/PATRON_REQUEST_ASSISTANCE_ALERTS.md`
- `ops/docs/plans/PAYMENTS_CORE_SUBSYSTEM_PLAN.md`
- `ops/docs/plans/PAYMENT_FOUNDATION_PARALLEL_TRACK_INTEGRATION_PLAN.md`
- `ops/docs/plans/PLATFORM_BILLING_QUALIFYING_REGISTRATION_ACCOUNTING_PLAN.md`
- `ops/docs/plans/SHENGFUKUNG_PAYMENT_AND_OFFERING_PHASE_ROADMAP.md`
- `ops/docs/plans/REGISTRATION_LIFECYCLE_EDIT_POLICY.md`
- `ops/docs/plans/SHENGFUKUNG_OFFERINGS_CONFIG_PLAN.md`
- `ops/docs/plans/SYSTEM_AUDIT_COVERAGE_AND_RETENTION_PLAN.md`
- `ops/docs/plans/SYSTEM_WIDE_ABUSE_PROTECTION_TELEMETRY_FOLLOWUP.md`
- `ops/docs/plans/TEMPLE_OFFERING_SYSTEM_SPEC.md`

## Superseded Plan Pointers

- `EXPO_MULTI_ROLE_MODE_SWITCH_PLAN.md` recorded a multi-role/admin mode
  direction, superseded on 2026-08-11 by the account-only Expo direction in
  `ops/docs/plans/EXPO_ACCOUNT_APP_READINESS_AND_PARITY_PLAN.md` and the two
  parallel plans for Rails JSON and Expo-native infrastructure
  (`EXPO_ACCOUNT_JSON_API_TRACK_PLAN.md` and
  `EXPO_NATIVE_CLIENT_INFRA_TRACK_PLAN.md`, both completed). All three were
  deleted with `ops/docs/plans/archive/` in 406a349.
- `EXPO_ACCOUNT_V1_BUILD_PLAN.md` recorded a purpose-first selection gate, a
  selective-CRUD framing, and a minimal-shell dummy objective, all superseded on
  2026-08-11 by the two parallel-track plans above. It was deleted with the rest
  of `ops/docs/plans/archive/` in 406a349 and is recoverable from that commit
  (`git show 406a349^:ops/docs/plans/archive/EXPO_ACCOUNT_V1_BUILD_PLAN.md`).
- `EXPO_ACCOUNT_APP_V1_ROADMAP.md`,
  `EXPO_DUMMY_ACCOUNT_DEVELOPMENT_CLIENT_PLAN.md`,
  `EXPO_NATIVE_ACCOUNT_FOUNDATION_PLAN.md`, `EXPO_CORE_ACCOUNT_PARITY_PLAN.md`
  and `EXPO_V1_UI_REFINEMENT_PLAN.md` recorded the earlier phase decomposition.
  They were deleted with `ops/docs/plans/archive/` in 406a349 and are
  recoverable from that commit. Their independent pre-integration scope was
  reorganized into the two parallel-track plans above, which completed and
  integrated at canonical commit `6cab3f1b52ebaeaf68667f19a3c804f8d9c43079`.

## 2026-08-19 Bulk Archival

73 plans reached an explicit terminal/acceptance disposition (either the
plan's own closing section or a directly matching `ops/docs/handoffs/`
record) and were moved intact to `ops/docs/plans/archive/` by Control B,
alongside this update. That directory was itself deleted later, in 406a349. This covers completed Account/Admin
personal-and-offering-data work, completed OAuth account-resolution and
Apple-recovery scans, the completed repository-local ECPay/cash-only payment
program (through Phase 4), the completed Expo/TempleMate account-integration,
EAS/Android dev-client, OAuth-native-client, V1 UI-refinement, registration-
authority, and Phase 3 tenant-gate/navigation debugging chains, plus two
governance/housekeeping plans whose own bodies already declared themselves
historical records (`CODEX_WORK_MODE_CURRENT_V1_POLICY_PROPAGATION_PLAN.md`,
`DOCUMENTATION_HOUSEKEEPING_AND_FUTURE_WORK_PLAN.md`, the latter being the
plan that originally produced this file). Durable evidence for each remains
in its corresponding `ops/docs/handoffs/` record, which was not moved or
altered — only the planning-surface copy was archived. Retained/active plans
above and this file's own future-work sections were not otherwise changed.

Several archived Phase 3 tenant-gate/navigation retry plans record a
terminal *packet* disposition (Control returned to idle) without directly
resolving the underlying issue in that specific attempt — the issue was
carried forward and resolved by a later plan in the same chain, which is
also archived. Archived does not mean "succeeded on the first try," only
that the individually-scoped plan concluded.

## 2026-09-03 Record Tree Removal

`ops/docs/handoffs/` (148 files) and `docs/operator/` (175 files) were deleted
on 2026-09-03. Director's reason: handoff-based coordination was abandoned
because neither Codex nor Claude has true governance or enforcement, so the
ceremony bought nothing, and attention moved to building the native app.

**Any `ops/docs/handoffs/...` path still cited in a plan, protocol, or
reference doc points at a deleted record.** The citation is left in place as
provenance rather than rewritten across ~30 files. Recover any of them with:

```bash
git show <this-commit>^:ops/docs/handoffs/<file>.md
```

Distilled before deleting, per the procedure set in `2f40594`:

| Content | Destination |
| --- | --- |
| ECPay default, cash as admin-attested receipt, monthly export on the 1st, no in-app close/lock | [platform payments](platform_payments.md) |
| Offering setup as a controlled field catalog | [onboarding runbook](onboarding.md) |
| Synthetic operator-intake worked example | [synthetic intake example](onboarding_synthetic_intake_example.md) |

The production boundary, the help-guide requirement, and Shengfukung's
declined onboarding were checked and found already recorded in the context
file, `templemate_product_positioning.md`, and
`shengfukung_demo_temple_status.md` respectively.

26 plan docs went in the same pass, each classified from its own closing
section rather than from the Retained list above (which dates from
2026-08-19 and no longer reflects what is live). Deleted: the six that
declare themselves terminal or are already tombstone stubs; the completed
Expo/EAS project, signing, OAuth-native-contract and V1 stabilization plans,
whose `..._authorized` classification was simply never updated after the work
shipped; the Phase 3 tenant-gate and navigation chains, complete per the
demo-readiness roadmap; the TestFlight/OTA plans, shipped; the superseded
account-admin data contract, replaced by
`PERSONAL_AND_OFFERING_DATA_CONTRACT_GAP_PLAN.md`; and the two Codex
branch/worktree cleanup plans.

Eight of the unlisted plans were kept as live or on-hold: the media asset
plan, the data-contract gap plan, semi-automatic registration, the
demo-readiness roadmap, the Apple user-22 recovery roadmap, TempleMate
refine, and the two awaiting a Director decision (central auth tenant
registration, platform env file reorganization).

`ops/docs/plans/archive/` no longer exists: it was deleted in 406a349 (78
files). The records below are therefore named rather than linked, which is the
rule — a prose mention that something was retired is fine, a link to a file
that is not there is not. Any one of them is recoverable with
`git show 406a349^:ops/docs/plans/archive/<NAME>.md`.

## Archived Completed Records

| Archived record (deleted in 406a349) | Durable destination |
| --- | --- |
| `ADMIN_PERMISSIONS_UI_AND_NAVIGATION_ALIGNMENT_PLAN.md` | [Admin portal reference](admin_portal.md) |
| `PLATFORM_BILLING_MONTHLY_AUTOPAY_CORRECTION_PLAN.md` | [TempleMate platform-billing runtime reference](templemate_platform_billing_runtime.md) |
| `FIRST_TENANT_BILLING_ENTITLEMENT_AND_REGISTRATION_GATE_PLAN.md` | [TempleMate platform-billing runtime reference](templemate_platform_billing_runtime.md), [onboarding runbook](onboarding.md) |
| `FINAL_WEB_READINESS_AND_EXPO_GATE_PLAN.md` | [Future work](future_work.md), [deployment readiness](../plans/DEPLOYMENT_READINESS.md) |
| `CODEX_WORK_MODE_SKILL_MIGRATION_PLAN.md` | Codex Work Mode, itself retired — its reference and current-coordination documents were deleted on 2026-08-23 |
| `CODEX_WORK_MODE_ON_DEMAND_CONTROL_LIFECYCLE_MIGRATION_PLAN.md` | Codex Work Mode, itself retired — see above |
