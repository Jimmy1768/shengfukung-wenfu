# Gatherings V1 Fake Payment QA

## Purpose

Use this checklist to validate the actual V1 launch path:

- gatherings are open
- offerings are paused
- fake checkout is verified first
- temple LINE Pay credentials are only entered after fake-flow QA is green

## Runtime Setup

- Keep `PAYMENTS_PROVIDER=fake`
- Do not enter live temple LINE Pay credentials yet
- Use the current temple web/admin deployment, not Expo

Relevant env keys:

- `PAYMENTS_PROVIDER`
- `LINE_PAY_CHANNEL_ID`
- `LINE_PAY_CHANNEL_SECRET`
- `LINE_PAY_API_BASE`
- `LINE_PAY_CONFIRM_BASE_URL`

## Admin Gathering Setup

- [ ] Create one paid gathering in admin
- [ ] Create one free gathering in admin
- [ ] Confirm both appear in `/admin/gatherings`
- [ ] Confirm both appear in the admin registrations picker as enabled targets
- [ ] Confirm event/service registration targets appear paused for V1
- [ ] Confirm new offering creation appears paused for V1

## Account Gathering Flow

### Paid gathering

- [ ] Sign in through the account web flow with OAuth or local account
- [ ] Open a paid gathering from the account side
- [ ] Submit a new registration
- [ ] Confirm redirect to the payment page
- [ ] Confirm the registration shows the gathering title and correct amount
- [ ] Start fake checkout
- [ ] Confirm a pending payment record is created or reused
- [ ] Complete the fake return path
- [ ] Confirm the registration becomes paid
- [ ] Confirm the payment page updates to completed state

### Free gathering

- [ ] Open a free gathering from the account side
- [ ] Submit a new registration
- [ ] Confirm redirect to the payment page
- [ ] Confirm the page shows no-payment-required / completed state
- [ ] Confirm no unnecessary checkout prompt is shown

## Admin Gathering Registration Flow

- [ ] Create a gathering registration from `/admin/gatherings/:id/orders`
- [ ] Confirm the admin order page shows the attendee correctly
- [ ] For a paid gathering, start fake checkout from the admin payment path
- [ ] Confirm hosted checkout returns to the same gathering order page
- [ ] Confirm payment status and registration status stay in sync
- [ ] For a free gathering, confirm the registration stays visible for headcount/logistics without requiring payment

## Failure / Retry

- [ ] Simulate a failed fake checkout for a paid gathering registration
- [ ] Confirm the account payment page shows a retry path
- [ ] Confirm retry does not create duplicate successful payments for the same completed intent

## Webhook / Status Sync

- [ ] Simulate webhook completion for a paid gathering registration
- [ ] Replay the same webhook payload
- [ ] Confirm duplicate replay is ignored safely
- [ ] Confirm the account payment status endpoint returns the latest status
- [ ] Confirm pending polling stops once the payment is no longer pending

## Refund / Recovery

- [ ] Trigger a refund for a paid gathering registration
- [ ] Confirm payment status moves to `refunded`
- [ ] Confirm the registration does not present as silently payable again without an explicit retry path

## Credential Handoff Gate

Only move past fake mode when all of these are true:

- [ ] Paid gathering fake checkout works in account flow
- [ ] Paid gathering fake checkout works in admin flow
- [ ] Free gathering flow works without payment regressions
- [ ] Webhook replay behavior looks safe
- [ ] Retry behavior looks safe
- [ ] Refund behavior looks acceptable for V1

## Live LINE Pay Prep

After the fake checklist passes:

- [ ] Collect temple LINE Pay credentials
- [ ] Enter them only in env, never in Git
- [ ] Keep a rollback path to `PAYMENTS_PROVIDER=fake`
- [ ] Run one paid gathering live-provider test
- [ ] Run one free gathering sanity check after switching env
- [ ] Confirm callback/return URLs are correct before broader rollout

## Repo Coverage Notes

Gathering-specific regression coverage has been added in:

- `rails/test/integration/account/registration_payment_flow_test.rb`
- `rails/test/integration/admin/payments_flow_test.rb`
- `rails/test/integration/admin/accounting_reporting_gatherings_test.rb`
- `rails/test/integration/admin/offering_orders_registrant_flow_test.rb`

If these tests cannot be executed in the current environment, record the infrastructure blocker and run them in the normal local/dev DB setup before live LINE Pay credential entry.
