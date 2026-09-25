# TempleMate Platform-Billing Runtime Reference

## Product and authority boundary

TempleMate has two separate money flows:

- **ECPay** processes patron-to-temple offerings, registrations, refunds,
  receipts, and temple accounting.
- **Stripe** collects TempleMate platform setup and monthly
  registration-usage fees from a temple.

Wenfu owns qualifying-registration/refund semantics, the Taipei-calendar
monthly close, progressive-price calculation, adjustments, and the immutable
statement. Stripe receives only Wenfu's finalized collection input; it is not
the registration meter, a cloud/API-usage meter, or statement authority.

SourceGrid owns the Stripe catalog and provider binding. Wenfu uses the
catalog as configuration and retains neither catalog-write authority nor a
broad SourceGrid secret key. One shared billing backend serves every tenant;
each tenant may use its own public frontend domain and owner/admin console.

## Domain ownership and roles

TempleMate platform identity and temple tenant identity have different domain
owners. Decided 2026-08-28 (see
`ops/docs/reference/templemate_product_positioning.md`) — no dedicated
platform domain will be purchased:

- The TempleMate product's own public identity (App Store/Play Store
  listing requirements, help/support, distribution-facing URLs) lives at
  `sourcegridlabs.com/templemate`, a page on SourceGrid's own already-owned
  domain -- not a separate domain the backend runs on.
- Each temple client purchases and owns its tenant domain. The pilot's
  completed-onboarding domain is `shengfukung.org.tw`; SourceGrid does not
  purchase that `.org.tw` domain.
- `shengfukung.com.tw` is not a placeholder -- it is the backend's permanent
  identity and the standing sales-demo instrument, by deliberate decision, not
  a stand-in awaiting a future domain swap. It is still neither the
  platform's own public-identity page (that's `sourcegridlabs.com/templemate`)
  nor the pilot's tenant domain (that's `shengfukung.org.tw`).

Runtime configuration may use the placeholder while those domains are
deferred. Product identity, QR/app binding, public documentation, and release
configuration must not treat it as permanent.

## Catalog configuration

The active SourceGrid account is `acct_1TFRmE7ZKypwRK7g`. These are non-secret
runtime inputs:

| Purpose | Product | Price | Meaning |
| --- | --- | --- | --- |
| TempleMate Platform Setup | `prod_V0JaalvBLyIxI8` | `price_1U0Ix77ZKypwRK7gI1x3IngL` | NT$10,000 one-time |
| TempleMate Registration Platform | `prod_V0Ji2ksvSabvoF` | `price_1U0J5S7ZKypwRK7gRvFaJd4D` | Progressive monthly TWD registration usage |

The monthly schedule is progressive: NT$1,500 through 500 qualifying
registrations, then NT$1.00 through 2,000, NT$1.25 through 10,000, and NT$1.50
thereafter. At 600 qualifying registrations, Wenfu's closed statement total is
NT$1,600.

## Protected runtime configuration

`/etc/default/shengfukung-demo-env` holds the protected values:

```dotenv
STRIPE_SECRET_KEY=
STRIPE_PUBLISHABLE_KEY=
STRIPE_TEMPLEMATE_PLATFORM_ACCOUNT_ID=acct_1TFRmE7ZKypwRK7g
STRIPE_TEMPLEMATE_SETUP_PRICE_ID=price_1U0Ix77ZKypwRK7gI1x3IngL
STRIPE_TEMPLEMATE_MONTHLY_PRICE_ID=price_1U0J5S7ZKypwRK7gRvFaJd4D
STRIPE_TEMPLEMATE_PLATFORM_WEBHOOK_SECRET=
```

The API key and webhook secret never belong in source control, chat, logs, or
fixtures. The API key is a TempleMate-specific restricted key, not a reused
SourceGrid broad key. `STRIPE_WEBHOOK_SECRET` remains separate and blank until
the later patron-to-temple Stripe Connect flow; it must never be substituted
for the TempleMate platform-billing endpoint secret.

## Deployed shared backend

As observed on 2026-08-04, `release/current` deployed
`af459d904af547222d1bd45ff3e40340aca9b894` to the Wenfu host. Additive
platform-billing migrations `20260802000021` and `20260803000022` are up, and
Puma plus Sidekiq are running and enabled at boot.

The shared Stripe platform-billing endpoint is:

```text
https://shengfukung.com.tw/api/v1/platform_billing/webhooks
```

`shengfukung.com.tw` is the temporary hostname described above. An unsigned
probe returns `401`; a locally generated valid-signature probe without tenant
or delivery metadata returns `422`. Together those results prove the deployed
environment, public route, and signature verification, while safely refusing
an event that cannot belong to a tenant. They do not establish a permanent
TempleMate or client-owned domain.

The endpoint accepts only these platform events:

```text
checkout.session.completed
invoice.paid
invoice.payment_succeeded
invoice.payment_failed
invoice.payment_action_required
```

An event can return `200` only after it matches an existing TempleMate tenant
and platform-billing delivery. That first matching event is the remaining
controlled onboarding proof; catalog existence or route readiness does not
create a customer, subscription, invoice, charge, payment, or entitlement.

## Deterministic enqueue schedule

Rendered units are created by
`ops/scripts/render_ops_templates.rb --slug <slug> --output <directory>`.

Monthly close was split into two separate steps, run on two separate
schedules, deliberately -- so a mistake caught in the gap between them can
be fixed before any charge fires:

| Timer | Service action | Calendar | Delivery behavior |
| --- | --- | --- | --- |
| `<slug>-platform-billing-monthly-review.timer` | `PlatformBillingMonthlyReviewJob.perform_later` | daily at 00:20 Asia/Taipei | idempotently closes the prior month and creates the (still-pending, uncharged) delivery; the next daily run is the deterministic retry for recorded per-temple review failures |
| `<slug>-platform-billing-monthly-collection.timer` | `PlatformBillingMonthlyCollectionJob.perform_later` | the 5th of the month only, at 00:20 Asia/Taipei | dispatches/charges every delivery review left pending. Deliberately **not** daily, unlike review: running it every day would eventually dispatch the following month's pending delivery before that month's own review-to-collection buffer had elapsed |
| `<slug>-platform-billing-lifecycle.timer` | `PlatformBillingLifecycleJob.perform_later` | daily at 00:40 Asia/Taipei | advances persisted overdue/grace deadlines independently of webhook replays |

All timers are persistent and have `RandomizedDelaySec=0`. Each one-shot
service retries an enqueue failure after five minutes, with a start limit of
three attempts in a one-hour window. The units are installed but disabled: no
automatic close, collection, or lifecycle advancement runs until an explicit
first-tenant onboarding decision enables them.

The lifecycle timer was originally hourly; changed to daily on 2026-08-26.
It never gates unlocking a temple after payment -- that happens
synchronously inside the Stripe webhook handler
(`Billing::StripePlatformBillingEventIngest#activate_entitlement!`),
independent of this timer. The timer only advances an already-delinquent
temple's own `overdue -> grace -> frozen` deadlines, a process on a
multi-day timescale (7-day overdue window, 14-day grace window) where
sub-day precision changes nothing. Daily also removes any chance of the
job's own retry window (up to three attempts, five minutes apart)
overlapping its own next scheduled run, which the hourly cadence did not
rule out.

The original design (a single `PlatformBillingMonthlyCloseJob` running daily,
closing and dispatching in the same call) was replaced by the two-step split
above. The old `<slug>-platform-billing-monthly-close.service`/`.timer` units
installed on the host from the original `af459d9` rollout referenced a job
class that no longer exists after this change; they were already disabled
and never fired, so this was inert. They (and two unrelated wrong-cwd build
artifacts found in the same checkout inspection) were removed directly from
the `taiwan-01-web` production checkout on 2026-08-26. The new review/
collection units still need to be installed in their place the next time
someone with production access re-runs the systemd unit staging step -- that
has not happened yet, since installing/enabling units on the host is a
separate, deliberate step from building the code.

## Collection status: real code, currently inert

`Billing::StripePlatformBillingCollection#collect!` is genuine, working
Stripe API integration -- a real `Stripe::Invoice.create` with
`collection_method: "charge_automatically"`, not a mock. If invoked
successfully it would attempt a real charge. As of this writing it is
inert for two independent reasons, not one:

- No scheduler was ever active before the two-phase timers above were
  built (see "Deterministic enqueue schedule") -- and those timers are
  themselves still installed disabled, per the first-tenant gate below.
- The `shengfukung-demo` demo temple has no `stripe_customer_id` or
  `stripe_payment_method_id` saved in `billing_settings`. Even a manual
  invocation would raise `"Verified Stripe customer is required"` before
  reaching Stripe -- nothing would be charged regardless of the
  scheduler or the live/test key question below.

**Director's stated belief (2026-08-21, not independently verified
against the Stripe dashboard): the configured `STRIPE_SECRET_KEY` is
live mode, not test/sandbox.** If correct, the two inert-today
conditions above are the *only* things currently preventing a real
charge attempt -- there is no sandbox layer underneath them. Confirm
this directly against the Stripe dashboard before any work populates a
real `stripe_customer_id`/`stripe_payment_method_id` on any temple, or
manually invokes the collection job/service, rather than relying on a
recalled belief.

## Grace period timing

`Billing::PlatformBillingLifecycle`: `OVERDUE_WINDOW = 7.days`,
`GRACE_WINDOW = 14.days` -- 21 days total from a failed charge to
freezing the temple's account (shortened from 37 as of this writing).
`Admin::PaymentMethodsForm::DEFAULT_BILLING_GRACE_DAYS` (a stale, unused
30-day duplicate of this same number) was removed in the same change;
the only place this value now lives is `PlatformBillingLifecycle`
itself. `Temple#billing_grace_days` (`billing_settings["grace_days"] ||
30`) is a separate, currently read-only code path -- no admin UI writes
it for any temple, so there's no stored per-temple override to
conflict with the shared default.

## First-tenant gate and preserved boundaries

Before enabling either timer or initiating the first setup collection, name the
first tenant and owner, confirm its expected statement and payment-method
setup path, supervise the matching Stripe event and Wenfu audit record, and
confirm live/test key mode directly against the Stripe dashboard (see
"Collection status" above -- this has never been independently verified,
only recalled). Local acceptance established entitlement-first
registration/payment-intake enforcement and matching owner presentation for
adopted temples; it did not authorize live collection, activation, or a
live-readiness claim.
Preserve platform-delivery idempotency, signed-webhook behavior, the persisted
`overdue -> grace -> frozen` lifecycle, legacy annual-record protection,
ECPay/patron payment behavior, tenant isolation, owner/admin authority,
accounting records, secrets, and assisted onboarding. No rollback deletes
closed statements, billing deliveries, provider-event evidence, or temple
payment history.
