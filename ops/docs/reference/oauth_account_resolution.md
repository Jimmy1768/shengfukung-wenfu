# OAuth Account Resolution

Covers the Rails-side policy for what happens when an OAuth (Apple/Google)
sign-in doesn't cleanly match an existing account. `templemate_native_oauth.md`
covers the Expo/mobile transaction plumbing (PKCE, deep link) —
this document covers the account-resolution *decision* that plumbing feeds
into, which is separate and did not previously have a reference doc.

## Why this exists

An unmatched Apple sign-in (no name/email returned by Apple, no email match
to an existing account) used to silently create a placeholder `User` with the
generic display name `OAuth User`. That name was not a UI fallback bug — it
was the deterministic, intended result of provisioning an account from an
OAuth exchange that returned no usable identity fields. The real problem was
that this happened invisibly, with no way for the human on the other end to
prove they already had an account and get linked to it instead of quietly
accumulating a second, empty one.

## Resolver modes

`Auth::OAuthIdentityResolver` (`rails/app/services/auth/oauth_identity_resolver.rb`)
first tries an exact `(provider, provider_uid)` match. Failing that, and only
for Google, it allows one narrow additional path: replacing a user's stored
Google subject when their previously-linked identity now presents a different
`provider_uid` for the same verified email with no conflicting identity
already using that subject (`google_subject_replacement_candidate?`) — this
is the existing, narrower Google subject-compatibility repair; keep it
isolated from the newer resolution paths below rather than folding it in.

For everything else, `Auth::OAuthAccountResolution`
(`rails/app/services/auth/oauth_account_resolution.rb`) holds the unmatched
identity in a short-lived, single-use token (`OAuthAccountResolution` model,
`token_digest` stored, raw token never persisted or logged) rather than
provisioning immediately. From that pending state, exactly one of four things
can happen:

1. **Exact-identity login** — a later OAuth attempt matches `(provider,
   provider_uid)` directly; no resolution needed at all.
2. **Explicit signed-in link** — the user proves they already have an
   account by supplying its email + password (`consume_existing!`); the
   identity links to that account.
3. **New account** — the user explicitly confirms terms and supplies
   email/password/name (`consume_new!`); a fresh `User` is created with
   `metadata["oauth_seeded"] = true`.
4. **Admin lookup-only** — an admin OAuth attempt that doesn't resolve must
   never provision a new account as a side effect. This was a real, fixed
   readiness gap: an earlier version could create a user before the
   admin-authority check failed. `lookup_only:` (`oauth_exchange_identity.rb`)
   is the enforcement point — an admin login path is never an
   account-provisioning path.

Both `create!`/`consume_*!` raise `FeatureDisabled` unless the
`oauth_account_resolution` feature flag is enabled.

## Trust boundary — what Wenfu will never infer

Wenfu cannot infer that an Apple relay address and a Gmail address belong to
the same human. The resolver never auto-merges across:

- name similarity
- email similarity (including Apple private-relay-domain pattern matching)
- shared temple membership
- staff familiarity ("this is obviously the same person")

Only a deliberate, proven action by the account holder (password proof, or an
already-authenticated session) moves an unmatched identity onto an account.

## Empty-placeholder consolidation

`Auth::OAuthEmptyPlaceholderConsolidator`
(`rails/app/services/auth/oauth_empty_placeholder_consolidator.rb`) is the
narrow recovery path for placeholders that were already created under the old
behavior. It is **not** a generic account-merge tool — it only moves an
OAuth identity from a source user to a keeper user, and only when the source
passes every check in `empty_placeholder?`:

- `metadata["oauth_seeded"] == true`
- account is active, not closed
- `english_name == "OAuth User"` and `native_name` blank (i.e., still exactly
  the placeholder default — never touched)
- exactly one OAuth identity, and it's the one being consolidated
- no admin account, no dependents, no registrations, no payments, no refresh
  tokens, no push tokens, no privacy requests, no lifecycle events, no
  assistance requests, no preference/privacy-setting rows, and none of
  `TempleRegistration`, `AgreementAcceptance`, `ApiUsageLog`,
  `CacheRepairTask`, `ClientCheckin`, `DataTransferLog`,
  `MessageDeliveryArchive`, `ClientCacheMetric`, `ClientCacheState`,
  `NotificationPreference`, `Notification`, `FinancialLedgerEntry`, or
  `UsageBillingSnapshot` reference it

If any of those fail, consolidation raises rather than merging — there is no
partial/best-effort merge path. On success the source account is closed
(`close_account!`, `reason: "operator_action"`) and its refresh tokens
revoked; the keeper's identity requires the keeper's own password
(`consolidate!` requires `confirmed:` plus a correct `keeper_password`).
Gated by the separate `oauth_account_consolidation` feature flag.

## Still-open, tracked elsewhere — not resolved by this document

- The historical "user 22" Apple account-recovery case remains open. It is
  tracked in the live (non-archived) `ops/docs/plans/OAUTH_APPLE_USER_22_RECOVERY_ROADMAP.md`
  and `ops/docs/plans/OAUTH_ACCOUNT_RESOLUTION_PRODUCTION_ROLLOUT_READINESS_PLAN.md`,
  not here — this document describes the shipped mechanism, not that specific
  case's disposition.
- Production rollout readiness for this resolver was, as of the same roadmap,
  blocked in part by 86 untracked files in the production checkout's public
  paths preventing a clean release-candidate assembly. Also tracked in the
  live roadmap, not resolved here.
