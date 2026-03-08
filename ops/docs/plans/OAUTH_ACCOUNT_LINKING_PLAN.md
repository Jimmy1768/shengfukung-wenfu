# OAuth Account Linking Plan (Post-V1)

## Execution Tracker (2026-03-08)

- [x] Planning doc created and approved as post-v1 scope.
- [x] Central OAuth provider plumbing in temple runtime is active (Google complete, Apple authorize step complete).
- [x] Phase 1 kickoff: account-linking runtime fields + shared resolver service added in temple app.
- [x] Phase 2: explicit in-session link/unlink endpoints + account UI entry points shipped in temple app.
- [x] Phase 3: conflict handling + support duplicate-account review surface shipped in temple app/admin.
- [ ] Phase 4: staged rollout behind feature flag + production observability gates.

This plan defines how one person can sign in with Google, Apple, and Facebook and still land in the same account.

- Priority: post-v1 (not launch critical).
- Scope: phased implementation. Phase 2 account-linking controls are now live in temple app; later phases remain pending.

## Problem Statement

Today, social sign-in can create fragmented identities when the same user signs in with different providers (different emails, Apple private relay, etc.).

Target behavior:

- One user account can link multiple OAuth identities.
- Future sign-ins from any linked provider resolve to the same app account.

## Product Decisions (Proposed)

1. Canonical app identity is internal `users.id` (not provider UID, not email alone).
2. Provider identity records are attached to one user account.
3. Linking requires account ownership proof (active session + recent auth challenge).
4. Unlink is allowed only if user keeps at least one login method.
5. Default auto-link by email is conservative:
   - Auto-link only when email is verified and not ambiguous.
   - Otherwise require explicit in-session linking confirmation.

## Identity Resolution Policy

- Primary match key is (`provider`, `provider_uid`). If that pair already exists, sign in the linked user.
- Verified email can be used only as a secondary hint when it maps to exactly one existing user and policy allows linking.
- Different provider emails must never be auto-merged, even if product intuition suggests they might belong to the same person.
- Apple private relay addresses are treated as ordinary provider emails for matching purposes; they are not enough to infer ownership of a different Google/Facebook/email-password account.
- When provider emails differ, the system must require explicit in-session account linking or create a separate account/identity until the user proves ownership.

Rationale:

- Same human != same provider email.
- Different humans may control similar or forwarded inboxes.
- A false-positive account merge is harder to recover from than a duplicate account that later gets linked intentionally.

## Data Model Plan

Create/confirm a dedicated linkage table (name illustrative):

- `oauth_identities`
  - `user_id` (FK)
  - `provider` (`google`, `apple`, `facebook`)
  - `provider_uid`
  - `provider_email`
  - `provider_email_verified`
  - `linked_at`
  - `last_login_at`
  - `metadata` (jsonb, minimal)

Constraints:

- Unique: (`provider`, `provider_uid`)
- Index: `user_id`
- Optional unique policy on normalized verified email should be deliberate, not implicit.

## Flow Design

### A. First-Time Social Sign-In

1. Receive provider identity from central auth.
2. If (`provider`, `provider_uid`) exists: sign in linked user.
3. Else if verified email maps to exactly one user and policy allows: link + sign in.
4. Else: create new account or require confirm-link flow (depending on UX decision).

### B. Link Additional Provider (While Logged In)

1. User clicks "Link Google/Apple/Facebook" in account settings.
2. OAuth completes and returns provider identity.
3. If identity already linked to different user: block and show conflict path.
4. Else attach identity to current user and audit-log event.

### C. Unlink Provider

1. User chooses unlink in account settings.
2. Require step-up confirmation (password/OTP/re-auth as available).
3. Prevent unlink if it would leave account with zero login methods.
4. Audit-log unlink event.

## Edge Cases To Handle

- Apple private relay email differs from Google/Facebook email.
- Provider email changes later.
- Existing duplicate users caused by pre-linking behavior.
- Provider returns no verified email.
- Tenant boundaries: no cross-tenant identity linking.

## Security & Compliance

- Do not trust raw client payload; trust server-side exchange only.
- Log link/unlink/auth events with user/tenant/provider/request-id.
- Add rate limits and abuse controls on link attempts.
- Keep provider tokens out of long-term storage unless explicitly required.
- Ensure account recovery path exists if user unlinks last social method.

## Migration / Backfill Strategy

1. Introduce table + write path without changing existing sign-in resolution.
2. Dual-write link records during normal OAuth login.
3. [x] Build admin report for possible duplicate users by verified email.
4. Run controlled merge tooling (manual approval) for legacy duplicates.
5. Switch resolver to provider-link-first logic after data confidence.

## API / Controller Work

- Account settings endpoints:
  - [x] `POST /account/oauth/:provider/link`
  - [x] `DELETE /account/oauth/:provider/unlink`
  - [x] `GET /account/oauth/identities`
- [x] Auth callback supports explicit in-session provider linking when central auth returns to temple callback with link intent.
- [x] Link conflicts now return a support-oriented message instead of a generic callback failure when a provider is already attached elsewhere.
- [ ] Central auth callback contract validation for provider claims completeness.

## Support Runbook

- Start from `Admin -> Patrons -> Review OAuth duplicates` to inspect verified OAuth emails linked to multiple user accounts.
- Treat the report as a manual review queue only; it is not proof that two accounts belong to the same person.
- Confirm ownership of both sign-in methods before any merge or provider reassignment.
- If ownership cannot be proven, leave the accounts separate and direct the member to sign in with the provider that is already linked.
- Keep merges manual and auditable; automatic duplicate cleanup remains out of scope.

## Test Plan (When Implementing)

- Unit:
  - identity resolver precedence and conflict logic
  - link/unlink policy guards
- Request/integration:
  - first sign-in, relogin, link second provider, unlink provider
  - conflict: provider UID already linked elsewhere
  - no-verified-email path
- Security:
  - CSRF/state replay, tenant isolation, tampered callback payloads

## Rollout Plan

1. Feature flag: `oauth_account_linking`.
2. Internal testing on non-production tenant.
3. Enable for one production tenant.
4. Observe error rates/conflicts/support tickets.
5. Gradual rollout to all tenants.

## Acceptance Criteria

- User can sign in with any linked provider and reach one consistent account.
- No duplicate account creation for already linked identities.
- Safe conflict handling when provider identity belongs to another account.
- Link/unlink is auditable and reversible via support process.
- No regression to existing OAuth login flow for tenants not yet enabled.

## Out Of Scope (V1)

- Automatic mass merge of historical duplicate users.
- Cross-tenant shared identity.
- Advanced risk scoring/fraud pipeline.
