# Expo OAuth Phase Roadmap

> The `ops/docs/handoffs/` files linked below were deleted in 102ecda; recover them from git history.

Status: active roadmap; implementation authority lives only in the bounded
phase plans named below

Updated: 2026-08-11

Owner: Wenfu Planning

Canonical readiness evidence:
`ops/docs/handoffs/2026-08-11-expo-oauth-integration-readiness-control-b.md`

## Direction

Komainu/TempleMate is the first SourceGrid Expo application that will
implement OAuth. There is no mature SourceGrid or DojoMate native OAuth client
to copy. Existing Wenfu Rails account OAuth and SourceGrid central-auth are the
mature server authority; current official Expo, Google, and Apple guidance is
the native platform authority.

After implementation and validation are complete, Komainu's attributable
contracts, tests, nonsecret configuration matrix, and operating notes may be
used as the example for later SourceGrid Expo applications. This roadmap does
not create a shared package or authorize changes to another repository.

## Sequence

1. `EXPO_OAUTH_NATIVE_RAILS_CONTRACT_PLAN.md`
   - complete and accepted on canonical `main` at
     `a0f4888c749835f648a5f716237efef89ef29900`;
   - adds the account-only native start/exchange contract around the existing
     central-auth service;
   - uses stubbed/local evidence only and does not access providers.
2. EXPO_OAUTH_NATIVE_CLIENT_PLAN.md (deleted 2026-08-22 in the plans/archive
   cleanup; recoverable via `git log --grep`)
   - was the implementation authority through Control B;
   - added deterministic dummy OAuth UI/state evidence and a real adapter for
     the accepted Rails contract.
3. Provider and development-client validation
   - requires a later separate plan after source integration;
   - verifies exact central-auth return allowlisting and any Google/Apple
     registration prerequisites;
   - uses EAS cloud when a new development-client binary is required. Local
     native building remains prohibited without a separately accepted reason.
4. Native OAuth identity management
   - signed-in provider list/link/unlink remains a separate later phase;
   - it must preserve the existing last-login-method and linking-conflict
     rules and is not required to prove first OAuth sign-in.

## V1 Boundary

The first OAuth-enabled V1 increment is Google and Apple account sign-in only.
It is additive to email authentication and never grants admin authority.
Payment, provider consoles, production credentials, app-store release, native
identity link/unlink management, and shared-package extraction are excluded
until their own plans are accepted.
