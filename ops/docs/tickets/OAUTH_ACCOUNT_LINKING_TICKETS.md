# OAuth Account Linking Tickets

## Open

- [ ] Manual Apple/OAuth follow-up after production fix:
  - confirm conflict handling, duplicate-review report visibility, and audit-log entries during manual merge debugging
  - verify missing-name provider responses land on profile edit instead of staying at `OAuth User`
- [ ] Facebook OAuth production follow-up:
  - verify central auth `/oauth/start` returns a valid Facebook authorize URL for `shengfukung`
  - verify Facebook callback reaches temple `/auth/callback` and temple `/oauth/token/exchange`
  - verify temple session establishment succeeds end-to-end
  - test account-linking behavior when Facebook is the secondary provider
