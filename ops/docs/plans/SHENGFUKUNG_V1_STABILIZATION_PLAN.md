# Shengfukung V1 Stabilization Plan

## Position

Yes, this is the right V1 cut.

The important framing change is:

- V1 should mean stable and supportable now.
- Offerings are not a code-quality blocker right now; they are a temple-config blocker.
- Gatherings are the shippable path because they already avoid the broken config dependency.

## V1 Scope

Treat V1 as complete when the product behaves like this:

- No Expo app is required for release.
- The account side can sign in with OAuth and use the web experience.
- The Vue marketing/site experience for the temple is viewable from the account-facing side.
- Offering registrations for `services` and `events` are intentionally frozen until temple offering config is clarified.
- Admin can still manage gatherings end to end.
- Gatherings can be either paid or free.
- Gatherings can use the existing payments stack with dummy provider testing first, then temple LINE Pay credentials for live validation later.

## Explicit Non-Goals For V1

- Do not ship Expo/mobile app work as part of V1.
- Do not try to rescue unclear service/event offering YAML during this release cut.
- Do not remove offerings code.
- Do not rewrite registration architecture.

## Current Reality

Working now:

- OAuth login already works.
- Admin gathering CRUD exists.
- Gathering registrations already run through the shared registration/payment stack.
- The payments core already supports `fake` mode and has a LINE Pay adapter path behind env gating.
- Free gatherings already fit the current product model.

Blocked externally:

- Service/event offering registration depends on temple-owned YAML/config that is still unclear or incorrect.
- Admin creation of new offerings or non-gathering registrations currently creates operational confusion, even if the code path itself is correct.

## Release Decision

For V1, freeze offerings and promote gatherings.

This means:

- Keep all service/event offering code in place.
- Disable the relevant admin buttons for creating new offerings and new non-gathering registrations.
- Leave gathering creation and gathering registration actions enabled.
- Position gatherings as the only active registration flow for launch.

## UI Freeze Rules

Disable buttons only, not backend code, for the offering-config-dependent paths.

Primary admin surfaces to freeze:

- `rails/app/views/admin/offerings/index.html.erb`
  - disable or replace the `new_admin_offering_path` action
- `rails/app/views/admin/registrations/index.html.erb`
  - disable the generic `new registration` launcher unless the picker is reduced to gatherings-only
  - if the modal remains available, service/event targets should be disabled or hidden while gathering targets stay enabled
- `rails/app/views/admin/offering_orders/index.html.erb`
  - for non-gathering offerings, disable the `new registration` action

Surfaces that should remain enabled:

- `rails/app/views/admin/gatherings/index.html.erb`
- gathering CRUD flow
- gathering registration creation flow
- account/user-led gathering registration flow

## Payments Plan For V1

Use the existing staged payment rollout:

1. Keep `PAYMENTS_PROVIDER=fake` for dummy end-to-end testing first.
2. Validate gathering checkout, return, status sync, and refund behavior.
3. Confirm free gatherings correctly bypass payment while still creating usable registrations.
4. After dummy testing passes, collect the temple LINE Pay credentials.
5. Enter credentials in env only, never in Git.
6. Run a live temple-specific LINE Pay test only after the fake-flow checklist is green.

Reference docs already in repo:

- `ops/docs/tickets/DUMMY_LINE_PAYMENT_TEST_TICKETS.md`
- `ops/docs/reference/platform_payments.md`

## Recommended Exit Criteria

Call V1 complete when all of the following are true:

- OAuth sign-in works in the deployed web flow.
- Temple marketing/site pages are viewable from the web experience.
- Admin cannot accidentally create new config-dependent offerings or non-gathering registrations from the main UI.
- Admin can CRUD gatherings.
- Admin can create gathering registrations when needed.
- User-facing gathering registration works.
- Free gatherings work without payment regressions.
- Fake payment flow has been manually validated for gatherings.
- The app is ready for temple LINE Pay credentials to be entered for live testing.

## Post-V1 Follow-Up

After V1, reopen offerings only when the temple provides a clear and reviewable offering config source of truth.

That follow-up should be treated as a separate project track:

- finalize temple offering YAML
- re-enable offering creation UI
- re-enable service/event registration UI
- validate service/event registration end to end

Until then, the correct product stance is:

- gatherings are live
- offerings are frozen
- the release is still a valid V1
