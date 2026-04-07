# ECPay Stage Smoke Checklist

Use this checklist for the first real ECPay stage validation on a temple.

This runbook assumes:
- the repo is already on the ECPay-first payment architecture
- the temple has an owner admin account
- account registration and payment pages already work in local/fake mode

## Goal

Verify that one temple can:
- store temple-specific ECPay stage credentials
- start hosted checkout through ECPay
- return to the app successfully
- receive the ECPay server callback successfully
- mark the registration as paid

## Required Inputs

Collect these from the temple’s ECPay stage account:
- `Merchant ID`
- `HashKey`
- `HashIV`
- environment = `stage`

Also confirm:
- the target temple slug
- one owner admin login
- one account user login for the real checkout attempt
- one published paid gathering or offering

## Before You Start

1. Confirm app env:
   - deployed env uses `PAYMENTS_PROVIDER=ecpay`
2. Confirm the temple exists and is published.
3. Confirm there is one paid registrable item visible in the account flow.
4. Confirm routes are reachable:
   - `/admin/payment_methods`
   - `/account/events?temple=<slug>` or the relevant account entry path

## Step 1: Save Temple Payment Settings

1. Sign in as an owner admin.
2. Open `/admin/payment_methods`.
3. Enter:
   - `ECPay Merchant ID`
   - `ECPay HashKey`
   - `ECPay HashIV`
   - `ECPay environment = stage`
4. Save the form.

Expected result:
- success flash appears
- values persist on reload

## Step 2: Start a Real Account Registration

1. Sign in as a normal account user.
2. Open the paid gathering/offering page.
3. Submit registration.
4. Open the payment page.
5. Click `Continue to payment`.

Expected result:
- app redirects to the internal ECPay handoff page
- the handoff page auto-posts to ECPay stage
- browser lands on the ECPay stage payment page

## Step 3: Complete the ECPay Stage Payment

1. Finish the payment in ECPay stage using the provided test flow.
2. Wait for browser return.

Expected result:
- browser returns to the app payment page
- the registration payment page loads without exception

## Step 4: Verify App-Side State

Confirm all of the following:
- payment page status changes from `Pending` to `Paid`
- registration detail reflects paid state
- admin payment ledger shows the completed payment

## Step 5: Verify Server Logs

Check Rails logs for:
- `POST /account/registrations/:id/start_checkout`
- `POST /api/v1/payments/webhooks/ecpay`
- `GET` or `POST /account/registrations/:id/checkout_return`

Expected payment transitions:
- `pending -> completed` on `temple_payments`
- `pending -> paid` on `temple_registrations`

Expected webhook response:
- plain body `1|OK`

## Step 6: Verify Stored Data

From Rails console or DB inspection, verify:
- `TemplePayment.provider = "ecpay"`
- `TemplePayment.payment_method = "ecpay"`
- `TemplePayment.provider_reference` is populated
- `TemplePayment.status = "completed"`
- `TempleRegistration.payment_status = "paid"`

## Pass Criteria

Treat the stage smoke as passed only if:
- owner admin settings save correctly
- hosted redirect reaches ECPay stage
- server callback succeeds
- checkout return succeeds
- payment row is completed
- registration is paid
- account/admin UI both reflect the paid result

## If It Fails

Capture:
- temple slug
- registration reference
- payment provider reference
- exact page URL where the flow stopped
- relevant Rails log block
- whether the webhook hit the app
- whether the browser return hit the app

Common failure buckets:
- wrong `Merchant ID` / `HashKey` / `HashIV`
- wrong callback/return domain
- ECPay stage account not enabled correctly
- temple saved stale credentials
- callback signature mismatch

## After First Success

Once one temple passes:
- reuse the same owner-admin workflow for future temple onboarding
- move the credential-collection steps into the standard client onboarding checklist
- keep cash/manual payments as the fallback path
