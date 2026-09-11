# TempleMate Product Positioning — Domain And Go-To-Market Decision

Business/product decision, not a technical or authority boundary — this file
exists so a future session doesn't regress and propose acquiring
`templemate.com` (or similar) as a to-do item. The technical domain/tenancy
architecture this decision plugs into lives in
`ops/protocol/repo_context.md`'s "Domain And Tenancy
Architecture" section; this file explains *why*, that file states *what*.

## The decision (2026-08-28)

- **No dedicated platform domain will be purchased.** Not `templemate.com`,
  not a fallback like `templemateapp.com`. This was evaluated and explicitly
  declined, not merely deferred.
- **`sourcegridlabs.com/templemate`** is the platform's own public identity
  instead — satisfies App Store/Play Store listing requirements (a
  support/marketing URL) and hosts the help guide. It's a page on an
  already-owned domain, not infrastructure the backend runs on.
- **`shengfukung.com.tw` keeps its current role, permanently.** No migration
  to a new repo or server, no domain swap. It stays the backend's informal
  identity *and* becomes the standing instrument the sales team uses to demo
  the product to prospective clients, on an ongoing basis — not a one-off
  historical demo that gets retired.
- **`shengfukung.org.tw`** is the real Shengfukung temple's own domain, once
  onboarded as an actual paying client — a second `shengfukung`-named tenant
  serving a completely different role from the `.com.tw` demo. Same
  organization name, different TLD, do not conflate the two.
- Trademarking "TempleMate" later is fine but not a business blocker; a
  contested or unavailable domain isn't worth fighting for (precedent:
  `dojomate.com` was taken, `dojomateapp.com` was used instead without
  issue).

## Why

**The business is a service, not a SaaS product or a brand.** The value
being sold is hand-held onboarding and an ongoing relationship, not
self-serve software. A marketing domain implies a self-serve acquisition
funnel — visit the site, evaluate the product, sign up — and that funnel
doesn't work for this buyer.

The buyer (temple staff) is non-technical and will not do unprompted work
even when it demonstrably saves them time later. Direct, first-hand
evidence: the Director visited the real Shengfukung temple in person twice,
still couldn't get their offering specs directly, handed them a literal
`.docx` form as a fallback, and they didn't complete it for six months —
despite having personally supplied the complaints that shaped this product's
design. If the person who wants the product won't self-serve a form for her
own benefit, a stranger reading a marketing website won't convert either.

The actual growth model is direct sales: hired sales agents visit temples
in person and hand-hold the onboarding process to completion, then rely on
referral/word-of-mouth to reach the next temple. `shengfukung.com.tw`'s job
in that model is "show, don't tell" — a real, working, stateful demo a rep
can drive live in front of a prospect (create a registration on a phone,
watch it appear on the admin console on a laptop, add details, publish,
mark cash collected) — not a marketing page's job to describe the product in
words to someone who will never read it. A page satisfying App Store
requirements is still needed (hence
`sourcegridlabs.com/templemate`), but it is not the conversion mechanism and
never needs to become one.

### What this looked like getting proven wrong elsewhere

A competitor (trireserve.com, reviewed 2026-08-28) is structured exactly
like the self-serve SaaS model being avoided here: a marketing site, a
single unauthenticated demo link with no real tenant isolation (visible
persisted test data from prior random visitors, not scoped per prospect),
a `success-cases` page with no real content, and pricing/onboarding FAQ
copy that's vague about how long setup actually takes. No evidence any real
temple has completed onboarding. That's the observable outcome of leading
with a website in this market — visits, maybe, but not completions — and it
matches, rather than contradicts, the Director's own six-month experience
getting one real temple to fill out a form.

It's also positioned as a point solution (lamp-lighting/registration only),
one of several separate tools a temple already juggles (accounting
software, a lantern-lighting tool, a separate ancestor-worship/certificate
tool). TempleMate's differentiation is being the all-in-one replacement for
that fragmentation, not another entry in it — a second reason a marketing
page pitching "another tool" doesn't fit, independent of the self-serve
problem above.
