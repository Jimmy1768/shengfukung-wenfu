# Mobile web — plan

Wenfu Planning, 2026-09-25. **Phased, not implemented.** The measurements this
rests on are in `MOBILE_WEB_READINESS_SCAN.md`.

## The decision

Two surfaces, treated differently. Director, 2026-09-25.

**The Vue public site works on a phone.** Portrait only — landscape is out of
scope: "no one uses their phone sideways except to watch a video."

**The Rails account area gets no mobile version.** A phone is sent to the app
instead. A mobile version would mean duplicating the account area's CRUD routes
and its payment flow, and the app already exists to be the mobile experience.

CSS alone cannot make the account area work on a phone, because its information
order assumes a tall screen. Measured on the connect page at 375×812: the nav
ends at 747px of an 812px screen, and the QR code starts 1.23 screens down.
Nothing in it is broken; it was designed for a desktop.

## Where things stand, verified 2026-09-25

**The Vue site already works on a phone** — mobile work on it had already
started. Tested on a real Pixel 8 in Chrome, portrait:

- the page is one column and nothing scrolls sideways
- "☰ 主選單" opens a menu with all seven pages
- tapping "關於" loads the About page and closes the menu

## Phase 1 — Vue polish

**Placeholder text — done, 2026-09-25** (assignment 032). The public footer
showed "地址：尚未設定地址（請至後台「Temple Profile」更新）" — an instruction to
an admin, shown to the public. It turned out not to be missing data: the demo
temple's address, Plus Code and phone were already on production. The site fell
back to a stand-in text file while a page loaded, so every visitor saw the admin
text on every page until the real details arrived. The server did the same for
any temple that had not filled a section in. Now nothing shows while loading, an
empty field is hidden label and all, and a guard test fails if the text returns.

**Still open:**

- **Menu links are 30px tall.** Raise them to the 44px minimum for a
  comfortable tap.
- **The Contact page subtitle.** Its fallback was
  "地址、地圖、開放時間、停車與大眾運輸（{temple} Placeholder）". The marker had
  to go; 032 dropped the whole line, so a temple with no service notes has no
  subtitle there. **[DIRECTOR]** Keep the descriptive half as default copy, or
  leave it out.

**Kept deliberately: the hidden demo showcase.** Every temple site carries the
template's "Golden Template Demo" pages at `/demo` and `/marketing`, including a
disabled nav item labelled "Custom Feature Placeholder". They are reachable by
typing the path. The Director, 2026-09-25: keep them. The router already
protects them in a comment. They are not a leftover to clean up.

## Phase 2 — Payment in the app

**This is the real work, and Phase 3 cannot happen without it.**

The app cannot take a payment. It displays payment state — a registration can
show as awaiting payment — but it has no checkout, no Stripe or LINE Pay, and
the native API has no payment route. Verified 2026-09-25.

So if phones are blocked from the account area before this lands, a patron who
needs to pay from their phone is stuck at "awaiting payment" with no way to pay.

It needs its own plan: which payment providers (the Rails app already has
Stripe and LINE Pay), what the native API must expose, and what the app screens
look like.

## Phase 3 — Block the account area on phones

Detect a phone, and show a page linking to the app instead of the account area.

Blocked on:

- **Phase 2**, above.
- **Something to link to.** There is no App Store listing yet — build 4 is in
  TestFlight — and Android has no release lane at all.

## Not in this plan

- **Landscape.** Director's call.
- **A mobile version of the account area.** The decision above rules it out.
- **The admin area.** Staff use it at a desk, and it is a different user from a
  patron. The scan found `/admin/login` scrolls sideways on a phone; that is
  recorded there and not scheduled here.
