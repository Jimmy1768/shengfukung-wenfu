# Account Password Addition Plan

## Purpose

- Define the safe path for users who first created an account through social OAuth and later want password login.
- Avoid unsafe auto-merge behavior on the email sign-up path.
- Improve the current UX when a user enters an email that already belongs to an OAuth-created account.

## Current State

- Google OAuth can create or link a `User` by exact email match when the provider has already authenticated the user.
- Email registration is create-only.
- If email registration hits an existing `users.email`, the form returns a generic `email is already taken` error.
- There is no current `/account/settings` flow for an authenticated user to add a password to an OAuth-seeded account.

## Security Rule

- Never merge or extend account access from the email-registration path based only on email knowledge.
- Knowing an email address is not proof of account ownership.
- Safe password addition must require one of:
  - an already-authenticated session, or
  - an email-verification / password-reset proof flow to the existing address.

## Scope

### In Scope

- Better signup collision messaging for existing-email cases.
- Clear instruction to sign in with the existing social provider.
- Add-password flow under `/account/settings` for authenticated users.

### Out Of Scope

- Automatic merge from email sign-up into an existing OAuth account.
- Support-assisted account recovery policy.
- Provider linking changes beyond the already-shipped OAuth account-linking work.

## Phase 1: Better Email Signup Collision Messaging

- [x] Replace generic `email is already taken` on account registration with a user-facing message that explains the likely cause.
- [x] Message should tell the user:
  - this email already has an account
  - if they previously used Google / Apple / Facebook, they should sign in with that provider
  - after signing in, they can add a password from account settings
- [x] Keep the response generic enough to avoid turning the signup form into an account enumeration oracle.

### Suggested Copy Direction

- Primary message:
  - `We found an existing account for this email. If you previously used Google, Apple, or Facebook, sign in with that provider first.`
- Follow-up guidance:
  - `After signing in, you can add a password from Account Settings.`

## Phase 2: Add Password In Account Settings

- [x] Add a new `/account/settings` section for password management.
- [x] If the signed-in user does not have a usable password yet, show:
  - new password
  - confirm password
  - submit action
- [x] Require the user to already be authenticated before setting a password on an OAuth-seeded account.
- [x] Save the password to `users.encrypted_password` using existing hashing conventions.
- [x] Show a success message that confirms email login is now enabled.

### Behavior Rules

- [x] For OAuth-seeded users with no known password, allow password creation without requiring current password.
- [x] For existing email/password users, reuse the stricter change-password rules if/when that UI is added later.
- [x] Do not create a second `User`.
- [x] Do not change linked OAuth identities.

## Phase 3: Login / Recovery Integration

- [ ] Confirm existing email/password sign-in works after password is added.
- [ ] Confirm password reset works for OAuth-seeded accounts once a real email exists on the user record.
- [ ] Decide whether password reset should also be allowed for OAuth-seeded accounts before manual password creation.

## QA Checklist

- [ ] Create account with Google OAuth, then attempt email registration with the same email and confirm the improved message appears.
- [ ] Sign in with Google, go to `/account/settings`, add a password, sign out, and sign in again with email/password.
- [ ] Verify no duplicate `users` row is created.
- [ ] Verify existing OAuth login still works after password addition.
- [ ] Verify password reset behavior for the same account.

## Open Decisions

- [ ] Final wording for the existing-email signup message.
- [ ] Whether `/account/settings` should be a new page or an expansion of the current account profile/settings surface.
- [ ] Whether password reset should be enabled before a manual password is ever set.

## Acceptance Criteria

- [ ] Existing-email signup gives clear guidance instead of a raw uniqueness error.
- [ ] Users can safely add a password only after proving ownership via an authenticated session.
- [ ] Same user can sign in with either social OAuth or email/password after password addition.
- [ ] No automatic merge or hijack path exists from public email signup.
