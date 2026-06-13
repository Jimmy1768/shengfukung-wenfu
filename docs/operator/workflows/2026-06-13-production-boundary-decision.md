# Workflow Decision: Production Boundary

Decision id: `shengfukung-2026-06-13-production-boundary`

Created: 2026-06-13

Owner: Shengfukung Wenfu coordinator thread

Repo: `/Users/jimmy1768/Projects/shengfukung-wenfu`

Branch context: `offering-setup-admin-workflow`

## Decision

V1 local or prototype acceptance does not authorize production promotion.

Production deployment, payment-provider changes, server changes, secrets work, production data work, or broader public rollout require a separate production-promotion workflow and explicit human approval.

## Production-Gated Actions

The following must remain blocked until an explicit production-promotion handoff and approval exists:

- deployment or release promotion;
- public rollout to additional temples;
- server configuration changes;
- DNS, proxy, TLS, webserver, process manager, queue, cron, or systemd changes;
- secret access, secret rotation, credential creation, or credential sharing;
- payment provider configuration changes;
- real ECPay merchant configuration changes;
- real ECPay payment testing that can move money or alter merchant state;
- production database migrations, backfills, repairs, destructive changes, or direct production data inspection;
- payment/accounting claims that the system is legally, fiscally, tax, invoice, or accountant-final;
- automated recurring jobs that affect production data or external providers;
- irreversible account, temple, admin, or patron changes in production.

## Allowed Before Production Promotion

The following remain allowed within repo-local OperatorKit workflows when scoped and recorded:

- local code changes;
- local docs and OperatorKit records;
- local tests;
- local browser review;
- local or isolated review database testing;
- sandbox/stubbed provider verification that cannot affect real merchant funds/configuration;
- non-production QA evidence;
- prototype acceptance records that explicitly do not claim production readiness.

## V1 Acceptance Relationship

V1 acceptance can establish that the product is ready for broader temple rollout planning.

It does not automatically establish:

- production deployment approval;
- accounting/legal/fiscal finality;
- payment provider production readiness;
- production data migration safety;
- zero-support rollout readiness.

## Required Production Promotion Packet

Before any production promotion, create a separate handoff that includes:

- exact target environment;
- exact branch/commit;
- deployment plan;
- rollback plan;
- database migration/backfill plan if any;
- server/config changes if any;
- payment provider impact if any;
- secrets impact if any;
- production data impact if any;
- verification plan;
- owner approval requirement;
- post-deploy monitoring plan.

## Related Decisions

- V1 acceptance threshold is recorded in `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-acceptance-threshold-decision.md`.
- V1 help guide requirement is recorded in `/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/workflows/2026-06-13-v1-help-guide-decision.md`.
- ECPay is the default online payment method for Taiwan temples, but production ECPay changes remain gated by this production boundary.
- Cash is admin-attested and auditable, but not externally controlled by the system.

## Future Handoff Trigger

Create a production-promotion handoff only after V1 acceptance evidence is complete and the owner explicitly asks to evaluate production promotion.
