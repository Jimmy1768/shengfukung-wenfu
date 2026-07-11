# Wenfu Repository Cleanup Integration Handoff

```yaml
handoff:
  handoff_id: wenfu-repo-cleanup-integration-2026-07-11
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_control: Wenfu Control
  objective: Reconcile the accepted offering-setup branch with canonical local main, consolidate current V1 plan truth, run local smoke verification, and remove only the merged local feature branch.
  accepted_design_refs:
    - /Users/jimmy1768/Projects/operator-kit/ops/docs/reference/codex_work_mode.md
    - /Users/jimmy1768/Projects/operator-kit/ops/docs/reference/codex_handoff_execution_profiles.yml
    - /Users/jimmy1768/Projects/operator-kit/ops/docs/handoffs/templates/codex_control_handoff.md
    - /Users/jimmy1768/Projects/operator-kit/ops/docs/handoffs/kernel-removal/2026-07-11-wenfu-kernel-removal-request.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-production-boundary-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-help-guide-decision.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md
  readiness_refs:
    - /Users/jimmy1768/Projects/operator-kit/ops/docs/operator/reports/2026-07-11-curator-kernel-install-uninstall-readiness.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/friction_records/2026-06-14-real-temple-admin-staff-rehearsal-awaiting-participant.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-06-14-real-temple-admin-staff-rehearsal-readiness-acceptance.md
  owned_files_or_surfaces:
    - docs/operator/README.md
    - docs/operator/handoffs/2026-07-11-repo-cleanup-integration.md
    - docs/operator/returns/2026-07-11-repo-cleanup-integration-return.md
    - docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md
    - ops/docs/plans/SHENGFUKUNG_V1_STABILIZATION_PLAN.md
    - ops/docs/plans/SHENGFUKUNG_OFFERINGS_CONFIG_PLAN.md
    - ops/docs/plans/ADMIN_ACCOUNTING_AND_ARCHIVES_WORKFLOW_PLAN.md
    - ops/docs/plans/PAYMENTS_CORE_SUBSYSTEM_PLAN.md
    - ops/docs/plans/SYSTEM_AUDIT_COVERAGE_AND_RETENTION_PLAN.md
    - local branches main and offering-setup-admin-workflow
    - temporary local Rails smoke process started by this Handoff
  implementation_scope:
    - Confirm the starting worktree is clean except for this Handoff file and preserve all unrelated state.
    - Treat main as canonical because refs/remotes/origin/HEAD resolves to origin/main; do not push or rewrite remote refs.
    - Preserve both histories by merging origin/main into offering-setup-admin-workflow; do not rebase, reset, squash, or drop commits.
    - Resolve merge conflicts by retaining accepted work from both histories. The patch-equivalent commits dab4275 and 5e5ad16 must not produce duplicated behavior.
    - Preserve the two applied offering-setup migrations and schema history; do not renumber, delete, recreate, or destructively rewrite migrations or schema.
    - Update docs/operator/README.md to use Wenfu Control and Wenfu Handoff task terminology, exact-idle-first dispatch, explicit Handoff model/reasoning, Control-only acceptance, and the truth that Codex is not governed OperatorKit and no OperatorKit kernel is installed into Codex. Preserve SourceGrid's cross-repo/product coordination statement and the existing pointer-only record rule.
    - Delete ops/docs/plans/SHENGFUKUNG_V1_STABILIZATION_PLAN.md because its offerings-frozen and LINE Pay launch direction is stale and conflicts with the later accepted ECPay/offering-onboarding decisions.
    - Update SHENGFUKUNG_OFFERINGS_CONFIG_PLAN.md to identify the real temple admin/staff rehearsal packet as the single current V1 exit path, record the accepted local offering-setup/admin QA evidence, and state that production acceptance remains pending.
    - Update ADMIN_ACCOUNTING_AND_ARCHIVES_WORKFLOW_PLAN.md with the accepted large-data local QA and previous-month export rehearsal evidence, while keeping real staff rehearsal and production acceptance pending.
    - Keep PAYMENTS_CORE_SUBSYSTEM_PLAN.md as the current provider truth and ensure it says ECPay is the Taiwan default, cash is admin-trusted and manually marked received, and local/sandbox evidence is not production acceptance.
    - Update SYSTEM_AUDIT_COVERAGE_AND_RETENTION_PLAN.md with the integrated API audit middleware hardening evidence without claiming the remaining retention/access phases complete.
    - Mark docs/operator/workflows/2026-06-14-real-temple-admin-staff-rehearsal-packet.md explicitly as the current external V1 acceptance gate and link the consolidated plan evidence. Do not rewrite its rehearsal procedure.
    - Do not create a new plans index because none currently exists. Scan for and remove any stale current-source link to the deleted stabilization plan if one exists; do not rewrite historical evidence references.
    - Commit the Handoff and plan/source-truth consolidation on offering-setup-admin-workflow.
    - Merge origin/main into offering-setup-admin-workflow with a merge commit, resolving only actual conflicts.
    - Run the required local smoke checks after the merge.
    - Fast-forward local main to the verified offering-setup-admin-workflow result.
    - Verify local main contains both previous histories and matches the verified integration tree.
    - Delete only the local offering-setup-admin-workflow branch after it is fully merged into main. Preserve origin/offering-setup-admin-workflow and all remote refs because pushing and remote cleanup are blocked.
    - Write the return file on main with exact evidence and commit it. Leave main clean.
  blocked_surfaces:
    - ops/docs/commands.md except conflict preservation required by the history merge
    - production and staging systems
    - remote Git mutation, push, force-push, and remote branch deletion
    - secrets, billing, payment provider state, customer data, and external callbacks
    - PostgreSQL or Redis service shutdown
    - Expo/mobile implementation or build work
    - historical handoff, return, acceptance, execution, eval, and friction records
    - destructive migration or schema-history rewrites
  required_checks:
    - git status --short --branch
    - git diff --check
    - RAILS_ENV=test bin/rails db:test:prepare
    - RAILS_ENV=test bin/rails test test/integration/api_protection_middleware_test.rb test/models/temple_offering_setup_draft_test.rb test/services/offerings/setup_field_catalog_test.rb test/services/offerings/setup_draft_applier_test.rb test/integration/admin/offering_setup_drafts_test.rb test/integration/admin/offerings_audit_test.rb test/services/offerings/template_parity_test.rb test/integration/admin/orders_and_payments_access_test.rb test/integration/admin/accounting_reporting_gatherings_test.rb test/integration/admin/payments_flow_test.rb test/integration/admin/archives_access_test.rb test/services/reporting/payments_csv_exporter_test.rb test/services/payments/provider_resolver_test.rb test/services/payments/checkout_service_test.rb test/services/payments/checkout_return_service_test.rb test/services/payments/status_mapper_test.rb test/services/payment_gateway/ecpay_adapter_test.rb test/integration/api/v1/payment_webhooks_test.rb test/integration/admin/layout_css_test.rb test/integration/admin/gatherings_layout_test.rb
    - npm run build from vue
    - Start Rails locally in test mode on an unused 127.0.0.1 port, request GET /up and require HTTP 200, then stop that exact temporary process and prove the port is closed.
    - git merge-base --is-ancestor origin/main main
    - git merge-base --is-ancestor dab42756e23496c2f04ab487d7c315ee0edc57a4 main
    - git branch --merged main
    - git status --short --branch on final main
  commit_required: true
  commit_message: Consolidate Wenfu cleanup checkpoint
  codex_execution:
    profile_id: handoff_standard
    model: gpt-5.4
    reasoning: medium
  escalation_conditions:
    - The starting worktree has changes other than this Handoff file.
    - A merge conflict cannot be resolved from accepted current source truth without choosing between incompatible product behavior.
    - Any required test exposes a product/design gap rather than an integration defect.
    - Integration would require dropping, rewriting, or renumbering migration history.
    - Local main cannot be fast-forwarded after the verified merge without losing commits.
    - Any requested action would touch a blocked surface.
  return_shape:
    - status: complete | blocked
    - canonical_branch
    - starting_state
    - plan_and_source_truth_changes
    - commits_created
    - integration_evidence
    - branches_or_worktrees_removed
    - branches_preserved_and_reason
    - smoke_checks_with_exact_results
    - final_git_status
    - temporary_service_pid_port_and_stop_evidence
    - blockers
```

## Readiness Decision

- Canonical local integration branch: `main`, proven by `origin/HEAD -> origin/main`.
- Current work branch: `offering-setup-admin-workflow`, clean and one commit ahead of its remote tracking branch before this Handoff file.
- Local `main` is at `8b25d09`; `origin/main` is at `5e5ad16`; their histories diverge after `3086b85`.
- `offering-setup-admin-workflow` contains `8b25d09` and the accepted offering/admin/accounting workflow history through `dab4275`.
- `dab4275` and `5e5ad16` are patch-equivalent API audit hardening commits on their respective histories.
- No additional local worktrees exist.
- No Wenfu Rails/Vue process is listening. Shared local PostgreSQL and Redis are present and must remain running.
- The prior kernel-presence classification found zero of 184 copied manifest files, zero installer state seeds, and zero governed-kernel claims. Kernel removal is a no-op.

## Return Location

Write the detailed execution return to:

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-11-repo-cleanup-integration-return.md`

Return to Wenfu Control only. Do not dispatch another Handoff.
