# COMPLETE ACCOUNT PORTAL

## Gaps we need to close

1. **Events page structure**
   - Current `/account/events` view renders a single “Events” grid.
   - Vue public site splits events into two sections: offerings (TempleEvent/TempleService records tied to the finance workflow) and gatherings (TempleGathering records).
   - Account portal must mirror this split so registrants can see both categories.

2. **Services view**
   - Account portal has no `/account/services` equivalent.
   - Offerings (services) should surface their own list with registration CTAs, matching the Vue site’s “Services” tab.

3. **Registration payment flow**
   - After a user submits a registration, there is no payment handoff screen.
   - Workflow: patron completes registration (event, service, or free/paid gathering). Successful save should redirect to `/account/registrations/:id/payment` (or similar) that shows the registration summary, amount due, and payment method selector.
   - The payment view should accept the registration ID/reference via params, render a “Complete payment” CTA (stub for Line Pay), and a “Pay later” link that returns to the registration detail.
   - For free registrations, the payment screen should short-circuit with a confirmation message but still live at the same route so the UX is consistent.

4. **Gallery section**
   - “View gallery” buttons on past events do nothing because the gallery section/API is missing from account portal.
   - Need a `/account/galleries` view (or extend `/account/events`) that loads gallery entries + links to assets, mirroring Vue behavior.

## Next steps

- [x] Update `/account/events` controller + view to load offerings and gatherings separately; add two sections with localized copy.
- [x] Build `/account/services` (controller, route, view) using the shared offerings templates.
- [x] Add an account payment controller/view that accepts a registration reference and prepares the payment payload (Line Pay stub for now).
- [x] Implement gallery fetching (reuse `TempleGallery` endpoints) and wire the “View gallery” link to a real route/modal.
