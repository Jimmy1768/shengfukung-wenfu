# Mobile web readiness — a scan, not a plan

Wenfu Planning, 2026-09-14. **Nothing here is approved for implementation.**
It records what was measured and what it implies, so the decision about scope
can be made on evidence rather than on impression.

## Why this exists

The connect page (`/account/connect`) shows a QR code and tells the patron to
scan it with the TempleMate app. That works only if the patron is reading the
page on a *second* device. If they are on the phone they just registered with —
the likely case — they cannot scan their own screen.

The Director's observation on finding this: *"we collapsed the two entrance
cases."* The design assumed one entrance, desktop-then-scan, and a consequence
followed that nobody decided: **the website was never built to be used on a
phone.** This scan measures how far that goes.

## Method, and its limits

Two kinds of evidence, kept separate.

**Measured live** against production at a 375×812 viewport, 2026-09-14:
`/` (Vue SPA), `/account/login`, `/admin/login`. Horizontal overflow was read
from `document.documentElement.scrollWidth` against `clientWidth`, and tap
targets from `getBoundingClientRect().height < 44`.

**Read from source** for everything else.

**Not measured:** every page behind authentication, which is most of the patron
surface — the dashboard, profile, registrations, payments and the connect page
itself. Reaching them means logging into production as a patron, which is not
something to do casually. Where those pages appear below, the evidence is the
stylesheet rule that governs them and the view that uses it, not a rendering.
That distinction matters: a rule with a 520px minimum *will* overflow 375px, but
only a render proves what the patron sees.

## A. Breaks on a phone

**`/admin/login` overflows horizontally.** Measured: `main.admin-main` extends
to 399px inside a 375px viewport. The page scrolls sideways.

**Two unconditional two-column grids on patron pages.** Neither is inside a
media query, so both apply at every width:

    account.scss:339  .event-grid--list         repeat(2, minmax(260px, 1fr))  → 520px minimum
    account.scss:651  .profile-form .single-row-grid
    account.scss:674  .single-row-grid          repeat(2, minmax(220px, 1fr))  → 440px minimum

At 375px the first overflows by roughly 145px before gaps, the second by 65px.
`repeat(auto-fit, …)` collapses on its own; `repeat(2, …)` cannot. The same
pattern appears ten more times under `admin/`.

**Two layouts carry no viewport meta tag**: `demo_admin.html.erb` and
`internal.html.erb`. Without it a phone renders at an assumed desktop width and
scales down, so text is unreadable until pinched. `account.html.erb` and
`admin.html.erb` both have it.

**Tables are unwrapped.** 19 view files contain a `<table>`; the entire
repository has 3 `overflow-x` rules. Three of those views are patron-facing —
`account/dashboard`, `account/registrations`, `account/payments` — and 13 are
admin. A table wider than the screen with nothing to scroll it drags the whole
page sideways.

## A2. The connect page, measured behind login

Added after the first pass. The Rails server was restarted onto `templemate_dev`
and the page opened as the seeded patron, so these are renderings rather than
inferences — the gap the first pass had to leave open.

**At 375×812 the patron sees only navigation.** Nothing is broken; nothing is
reachable either.

    nav chrome ends            747px   92% of the first screen
    connect content begins     780px   below the fold
    QR code begins             997px   1.23 screens down
    instructions               1236px  BELOW the QR
    raw URL                    1366px
    page total                 1735px  2.1 screens

The same page on desktop puts the QR at 0.86 screens — above the fold on a
1024×768 window. So the page was not designed badly; it was designed for the
only viewport anyone looked at.

Three things follow, and none of them is a CSS bug:

- **The header is the page on a phone.** Title, sign-out, language toggle,
  display-mode toggle and ten nav buttons in a two-column grid consume the
  entire first screen before any content starts.
- **The instructions sit below the QR.** A patron reaches the code before
  reading what to do with it, and on a phone they cannot see both at once.
- **No horizontal overflow, 15 tap targets under 44px.** The layout is
  technically responsive. It is the *information order* that assumes a screen
  tall enough to show everything at once.

This is the sharpest available statement of what "we collapsed the two entrance
cases" cost. Every element is present and correctly sized; the page simply
assumes the reader can see a screenful of it at once, which a phone cannot.

## B. Usable but degraded

**Tap targets below the 44px minimum.** Measured: 17 on the Vue homepage, 7 on
`/account/login`. Apple's guidance is 44×44pt; below that, taps miss.

**The showcase surface has no media queries at all** — zero across
`rails/showcase_ui/styles`. The shared bundle has one.

## C. Structural

**Eight ad-hoc breakpoints, no system.** In use: 520, 640, 720, 760, 860, 900,
920, 960 — mixing `min-width` (5 rules) and `max-width` (16). Nothing says which
is the phone tier, so each surface has improvised its own. **The lowest
`max-width` is 520px**, which means a 375px phone is not a case anything was
written for; it inherits whatever the smallest tier happens to give.

**There is no mobile-first baseline.** The base rules are desktop rules, with
narrow overrides bolted on where somebody noticed.

## What is already fine

`/` and `/account/login` both render at 375px with no horizontal overflow.
`account.html.erb` and `admin.html.erb` carry correct viewport meta. Six grids
already use `repeat(auto-fit, minmax(…))`, which collapses correctly. So this is
not a rewrite: the account surface is closer than the admin surface, and the
worst findings are a small number of specific rules.

## The fork — Director, 2026-09-14

**"We can't make a mobile version just by editing the web version. Don't even
try. There are only 2 buckets."**

That rules out the obvious reading of everything above. **Sections A, B and C are
evidence of the size of the gap, not a work list.** Nothing in them should be
turned into a responsive-CSS pass.

### Bucket 1 — a real mobile version

Its own layout, smaller elements, dropdowns instead of a ten-button grid. A
second presentation of the same data, not the desktop one reflowed. The measured
finding supports this: the connect page has no CSS defect at all, and is still
unusable on a phone because the information order assumes a tall screen. That is
not reachable by editing breakpoints.

Open: which surfaces get one. The patron account is what the entrance problem
argues for. Admin is a different user at a desk and holds 13 of the 19 unwrapped
tables.

### Bucket 2 — no mobile version; send the visitor to the app

Detect a device, show a page with App Store and Play Store buttons, and let the
app be the mobile experience.

**It is not available today, and the reason is not the web.** Observed
2026-09-14:

- **iOS has no App Store listing.** Build 3 is TestFlight, by invitation. There
  is no public link anywhere in this repository.
- **Android has no release lane at all.** `mobile/eas.json` defines an `android`
  block only under `development` (an internal APK). `testflight` and
  `production` are iOS-only. Tier 5, the China side-load lane, has no profile
  and no script — `repo_context.md` already records this as the real gap.

So bucket 2 cannot be built until both apps ship. It is a decision about where
to spend effort next, not an option that can be taken this week.

**And it has a loop that must be solved first.** The connect page exists so a
patron can load a temple into the app — the app is built with no temple and gets
one by scanning. If the mobile web shows only "download the app", then a
phone-only patron goes: install the app → the app shows a scanner → the scanner
needs a QR code → the QR code is on the website → the website says install the
app. There is no second screen to break the cycle.

The exit is a `templemate://` deep link carrying the slug, so the temple binds
without a scan. That is a prerequisite of bucket 2, not a detail of it.

## Decisions before any of this becomes a plan

1. **Which surfaces are in scope.** Patron account is the one the entrance
   problem argues for. Admin on a phone is a different product question — a
   temple clerk at a desk is not the same user — and 13 of the 19 unwrapped
   tables are admin. Including it roughly triples the work.

2. **What is the device floor.** 375px is the iPhone figure used here. Android
   side-loading for China (client tier 5) puts 360px devices in scope, which is
   narrower than anything currently written for.

3. **What the connect page becomes.** If the phone case is served by a
   `templemate://` deep link rather than a QR, the page has two paths and the QR
   stops being its centre. That is a design decision, not a CSS one, and it
   changes what the page is for.

4. **The download step has no link to point at.** The Director's fourth point
   was that a patron missing the app should be given a way to get it. There is
   no App Store listing and no public TestFlight link anywhere in this
   repository — build 3 is TestFlight-only, by invitation. Until one exists,
   that step cannot be written honestly.

## Not in scope here

The `shengfukung-wenfu` → `shengfukung-demo` slug rename, which the Director
raised in the same message. It is a separate job with its own blast radius —
runtime-coupled paths, live infrastructure names and a production data row — and
mixing it into a CSS pass would make both harder to reverse.
