# DUMMY LINE PAYMENT TEST TICKETS

## Purpose

Manual checklist for testing the fake hosted checkout flow before real LINE Pay rollout.

## Scope

- Use the current hosted checkout/payment architecture.
- Run with `PAYMENTS_PROVIDER=fake`.
- Treat this as app-flow validation, not provider validation.

## Account Flow

- [ ] Start checkout from an unpaid registration payment page.
- [ ] Confirm the app creates or reuses the expected pending payment record.
- [ ] Complete the fake hosted checkout path and return to the app.
- [ ] Confirm the registration becomes paid when the payment completes.
- [ ] Verify the payment page updates from pending to completed.
- [ ] Verify retry behavior when the fake flow returns a failed payment state.

## Admin Flow

- [ ] Start checkout from the admin payment/order screen.
- [ ] Confirm hosted checkout returns to the correct admin page.
- [ ] Confirm the payment record status and registration status stay in sync.

## Webhook / Status Sync

- [ ] Simulate webhook completion and confirm duplicate webhook replay is ignored safely.
- [ ] Confirm the account payment status API reflects the latest payment state.
- [ ] Confirm the payment page polling stops once the payment is no longer pending.

## Refund / Recovery

- [ ] Trigger a refund through the current payments subsystem path.
- [ ] Confirm the payment moves to `refunded`.
- [ ] Confirm refunded registrations do not present as still payable without an explicit retry path.

## Exit Criteria

- [ ] Account start, return, and completion flow works end to end.
- [ ] Admin start and return flow works end to end.
- [ ] Payment state changes are visible in UI and persisted correctly.
- [ ] No duplicate payments are created for the same successful intent.
- [ ] Any gaps found are converted into follow-up tickets before real provider rollout.
