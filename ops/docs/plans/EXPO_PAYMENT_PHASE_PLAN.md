# Expo Payment Phase Plan

Status: deferred until a temple has a live ECPay merchant account. The provider
inventory this plan required before acceptance was done 2026-09-26 (below). Not
current implementation authority.

Created: 2026-08-11. Inventory, store rules and web defects added 2026-09-26.

Owner: Wenfu Planning

Core-track predecessors: EXPO_ACCOUNT_JSON_API_TRACK_PLAN.md and
EXPO_NATIVE_CLIENT_INFRA_TRACK_PLAN.md (both deleted 2026-08-22 in the
plans/archive cleanup; recoverable via `git log --grep`)

## Objective

Plan and implement the native account payment surface only after core account
registration behavior is stable. Core V1 can create and test registrations
without checkout, and can present already-paid fixtures without performing or
simulating payment.

## Entirely Deferred Surface

- account payment history and payment-detail fields;
- registration payment status polling;
- checkout start and system-browser/native return;
- pending, completed, failed, cancelled, interrupted, duplicate, and retry
  lifecycle handling;
- ECPay callback/correlation behavior used by account registrations;
- any Stripe behavior that is actually part of an account-user payment flow;
- provider-safe diagnostics, receipts, monitoring, rollback, and staged
  validation required by the selected provider path.

Stripe platform billing is an admin/web concern and does not enter the account
app merely because Stripe exists elsewhere in Wenfu. Before this phase is
accepted for implementation, Planning must inventory the exact provider and
account-route mapping rather than assuming both providers belong in every
registration flow.

## What Exists Today — Inventory, 2026-09-26

Read from the code on `main` at ca37b38, and from production for the demo
temple.

- **One thing is paid for: a registration.** The price is the offering's fixed
  `price_cents` times a quantity of 1 to 10. The patron never chooses an
  amount, donations included. Offering types: general, lamp, ritual, donation,
  table. Free registrations never reach payment.
- **One online provider: ECPay**, a hosted page. The provider registry holds
  `fake` and `ecpay` only (`provider_resolver.rb:8-11`); a temple can be set to
  `cash_only` instead.
- **LINE Pay does not exist** — a `line_pay` payment-method value, locale labels
  and unused `LINE_PAY_*` env vars, but no adapter, route or resolver entry.
- **Stripe is platform billing only**: the temple paying for TempleMate. No
  patron flow uses it.
- **Cash is recorded by staff** (`Payments::CashPaymentRecorder`), the only
  path that writes a ledger entry.
- **The web flow.** After an admin marks the registration complete
  (`checkout_ready?`), `start_checkout` writes a pending `TemplePayment` and
  sends the browser to an unauthenticated handoff page that posts to ECPay.
  ECPay's server callback (`/api/v1/payments/webhooks/ecpay`) settles it,
  checking signature and amount; the browser returns to `checkout_return`.
  A registration's payment status is pending, paid, refunded or failed.
- **No temple takes online payment.** On production the demo temple is
  `cash_only` with no ECPay credentials (checked 2026-09-26). Live ECPay needs a
  real temple's merchant account (`reference/platform_payments.md`).
- **The app** creates and edits registrations and shows "待完成付款。" — the
  status and nothing more, by the Director's principle that the patron is not a
  messenger for the temple (commit fda6678). No native route starts, completes
  or polls a payment; the web's status route is cookie-only; and the native API
  never tells the app whether its temple takes online payment. The app's lint
  forbids "checkout" and "ECPay" in `mobile/app`.

## What The Store Rules Allow — Researched 2026-09-26

From Apple's App Review Guidelines (last updated 2026-06-08) and Google Play's
Payments policy. The rules are paraphrased from source; which category an
offering falls in is interpretation.

- **Services and events at the temple** — lamp, ritual, table, gatherings.
  Apple 3.1.3(e): goods and services used outside the app must be paid by a
  method other than in-app purchase. Google Play's Payments policy §3 keeps
  Play billing out of payments for physical services. ECPay's hosted page is
  allowed on both, which is what criterion 1 already requires.
- **Donations** — the `donation` offering type (香油錢). Apple 3.2.2(iv): an app
  may collect donations only outside the app, in Safari or by SMS, unless the
  charity is an Apple-approved nonprofit (3.2.1(vi)), which must then also
  offer Apple Pay. For a Taiwan temple, approval goes through Benevity. So on
  iOS a donation opens Safari itself — not a browser sheet inside the app,
  which Apple does not clearly count as outside — unless that temple is
  approved. Android: Play billing is excluded for tax-exempt donations; the
  policy is silent on gifts that are not.
- **This reaches the website too.** Apple's rules for Apple Pay on the web bar
  it from collecting nonprofit donations without Apple's approval. ECPay's
  `ChoosePayment` is ALL, which may include Apple Pay (not checked), so a
  donation checkout must leave it out — in Safari from the app, and on the
  temple's website.
- **Anything delivered inside the app** — a virtual lamp, a livestream, an
  e-certificate — would fall under Apple 3.1.1 and need in-app purchase.
  Nothing sold today is.
- The 2025 changes to Apple's rules on payment links apply to the US storefront
  only, not Taiwan.

## Before Any Temple Goes Live: Defects In The Web ECPay Path

Found in the code; none has been exercised against real ECPay, which no temple
has. The app would inherit each one, so they are fixed on the web first.

1. **The trade number repeats within an hour.** `default_trade_no` cuts to 20
   characters, dropping the minutes, seconds and random suffix
   (`ecpay_adapter.rb:168-171`). A second attempt on the same registration in
   the same hour sends ECPay a number it has already seen.
2. **A failed or invalid callback can block the real one** (effect inferred).
   The webhook event is recorded before its signature is checked
   (`webhook_ingest_service.rb`), and events are deduplicated by ECPay's trade
   number, so a retried genuine callback can be taken for a duplicate.
3. **A cancelled registration can still be paid.** `start_checkout` checks the
   freeze, admin completion and online availability, not cancellation.
4. **ATM and convenience-store payments probably end as failed** (inferred).
   `ChoosePayment` is ALL, no `PaymentInfoURL` is set, any return code but 1
   maps to failed, and failed is terminal, so the later real payment is refused.
5. **The browser return probably loses the login** (inferred). The session
   cookie is SameSite=Lax and ECPay returns by cross-site POST. The server
   callback still settles the payment.
6. **Two open attempts can both complete** (inferred): nothing stops a second
   pending payment while the first is open.
7. **ECPay refunds do not exist.** The adapter raises NotImplementedError, and
   nothing calls the refund service.

## When A Temple Goes Live — The Shape To Accept

What this plan's deferred list and EA-4 in
`EXPO_ACCOUNT_APP_READINESS_AND_PARITY_PLAN.md` point to, gathered for
acceptance when the work starts:

- **Web first.** The defects above are fixed and tested, and the temple's ECPay
  merchant account works on the website, before the app takes a payment.
- **Checkout in the phone's browser.** The app opens ECPay's hosted page in the
  system browser; the site's return page hands back to the app through
  `templemate://`. No universal links are configured.
- **Donations on iOS open Safari itself**, unless the temple is an
  Apple-approved nonprofit.
- **The native API tells the app what it cannot know today:** whether its
  temple takes online payment, and a payment's status over a bearer-token
  route.
- **The app's lint changes with it**, since `mobile/app` forbids "checkout" and
  "ECPay" today.

## Relationship To Core V1

- Core V1 may create registrations that need no payment.
- A payment-required registration may stop at a truthful unpaid/pending state.
- Local/test data may contain an already-paid registration so the registration
  UI can display paid state.
- A paid fixture is not provider, callback, receipt, reconciliation, settlement,
  refund, accounting, or production evidence.
- Core V1 contains no payments menu, checkout button, status poller, provider
  reference, or transition that claims money moved.

## Provider And Release Boundary

No real ECPay/Stripe credential, merchant/customer change, checkout, callback,
refund, money movement, provider-console action, production data, deployment,
or store/release action is authorized by this plan. Local/stubbed evidence must
remain explicitly non-provider and non-accounting evidence.

## Immutable Acceptance Criteria

Before later payment implementation can be accepted:

1. The exact existing Rails account payment and registration state machine is
   mapped without introducing IAP or a new provider behavior.
2. Native checkout/return/status behavior has explicit correlation,
   interruption, cancellation, idempotency, duplicate, and retry rules.
3. Account-safe serializers expose no unnecessary provider or accounting
   reference.
4. Tenant, registration ownership, lifecycle, callback, and replay protections
   remain server-authoritative.
5. Local/stubbed acceptance makes no claim about credentials, callbacks,
   settlement, refunds, accounting, production, or release readiness.
6. Any live provider validation uses a separately authorized provider-safe
   workflow.

## Current Gate

The entire payment surface/lifecycle is deferred. It does not block the dummy
development client, native email session, core account CRUD, or V1 UI
refinement.

Added 2026-09-26: nor does it block Phase 3 of `MOBILE_WEB_PLAN.md`. No temple
takes online payment, so a phone sent to the app loses no way to pay. The gate
opens when a temple has a live ECPay merchant account, and then the web defects
above come first.
