# SourceGrid Pricing Reference

This document is not the source of truth.

The canonical pricing list for the marketing demo is:

`vue/src/sourcegrid/pricing/priceList.js`

The demo adapter is:

`vue/src/sourcegrid/pricing/index.js`

## Current Model

Golden Template no longer presents SourceGrid as a fixed-price custom app shop. The demo now represents SourceGrid as an ecosystem with three pricing patterns:

- Free network/funnel products that maximize adoption first.
- Paid marketplace or service-fee layers that monetize serious downstream usage.
- Hosted tenant workflow systems where a business gets its own public surface and uses shared operational modules.

Clients do not buy a one-off app by default. They enter a managed platform or ecosystem relationship.

## Current Examples

- DojoMate: free martial arts funnel. Monetization happens downstream through Source Combatives, optional productivity tools, and ecosystem services.
- Source Combatives: paid martial arts curriculum platform using a service fee per subscriber.
- TempleMate: free public temple profile/site, with NT$3,000/month workflow access after a grace period. If delinquent, public marketing stays live but registration/business workflows freeze.
- Hotel/hostel bookings, equipment rentals, and nursing-home/dependent-care workflows: pilot vertical modules to validate after Operator-Kit stabilizes.

## Offering Categories

- `network_marketplace`: free or marketplace-style network products where scale is more important than immediate SaaS fees.
- `platform_tenant`: hosted tenant systems and reusable workflow modules.
- `vertical_pilot`: near-term client modules that are plausible but should be validated before broad resale.

## Offering Status

- `ready`: can be sold or demoed now with normal implementation risk.
- `pilot`: useful near-term, but requires operational validation with early clients.
- `case_by_case`: quote only after intake because local rails, workflow complexity, or support burden may change the scope.
- `learning`: not ready for client promise.

## Maintenance Rule

When prices change, update `priceList.js` first. Demo pages, fake-brand pricing pages, and copied downstream repos should consume that same structure instead of maintaining separate pricing tables.
