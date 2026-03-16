# Account Password Production Tickets

## Open

- [ ] Production validation for OAuth-seeded account password addition:
  - sign in with Google or Apple on production
  - add a password from `/account/settings`
  - sign out and sign back in with email/password using the same account
  - confirm the original OAuth sign-in still works after password addition
  - confirm no duplicate user row or duplicate account profile is created
- [ ] Production validation for password reset on OAuth-seeded accounts after manual password creation:
  - request password reset for the same account email
  - complete reset flow
  - confirm email/password sign-in works with the reset password
