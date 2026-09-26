# Mobile web — plan

Wenfu Planning, 2026-09-25. **Phase 1 is done; Phases 2 and 3 are not
started.** The measurements this rests on are in `MOBILE_WEB_READINESS_SCAN.md`.

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

**Menu tap targets — done, 2026-09-25** (assignment 036). On a phone the seven
menu links were 30.4px tall — 14px text at the 1.6 line-height plus 4px of
padding — and the menu button 43.6px, both under the 44px minimum for a
comfortable tap. Both are now 44px, and the whole row takes the tap, not just
the words. The desktop header is unchanged, measured before and after at
1280px. The open menu grew from 246px to 341px against a 400px cap: an eighth
link still fits; a ninth needs the cap raised.

**In-page links — done, 2026-09-26** (assignment 037). The scan counted 17
targets under 44px on the homepage; the menu was eight of them. Of the rest,
the arrow links in the page body were the worst: only as tall as their line of
text, 19px on the homepage. The Director approved fixing that pair. The same
style carries the arrow links on Services and event pages at 23.8px, including
the six "登入並報名 →" a patron uses to start registering, so the fix went to
the style's owner rather than to two links: one rule in `layout.css`, where
three pages had each kept an identical copy. On a phone they are now 44px, and
the desktop is unchanged, measured before and after.

**Left as they are, the Director's call:** the footer's five links (28px) and
its "Email 聯絡" button (33.6px), and the brand link in the header (40px).

**Restored: the Director's Contact subtitles** (assignment 033). 032 removed
them because one carried a "（… Placeholder）" suffix and the other mentions
"在後台". Both are back as written: the page subtitle
"地址、地圖、開放時間、停車與大眾運輸", shown when a temple has written no service
notes, and the 交通 / 停車 section's "在後台可隨時更新資訊，方便信眾掌握動線。".
The first had never actually reached a visitor before: an admin note came first
in the fallback chain and always won.

The lesson for guards like 032's: they enforce a list of markers, not the
sentence "no admin instruction reaches the public". A string scan cannot tell
who owns a piece of copy. Product copy is the Director's, and removing any of it
is a call to report, not to make.

**Kept deliberately: the hidden demo showcase.** Every temple site carries the
template's "Golden Template Demo" pages at `/demo` and `/marketing`, including a
disabled nav item labelled "Custom Feature Placeholder". They are reachable by
typing the path. The Director, 2026-09-25: keep them. The router already
protects them in a comment. They are not a leftover to clean up.

## Phase 2 — Payment in the app

**Corrected 2026-09-26, after tracing the code: this does not block Phase 3.**
An earlier version of this section said it did, and that the Rails app had
Stripe and LINE Pay for patrons. It has neither.

- **ECPay is the only online payment provider in the code.** LINE Pay does not
  exist beyond a label and unused env vars; Stripe bills temples for the
  platform and never takes a patron's money.
- **No temple takes online payment.** The demo temple is cash-only on
  production, with no ECPay credentials, and live ECPay needs a real temple's
  merchant account. Patrons pay at the temple and staff record it.
- **So blocking the account area on phones removes no way to pay.** The app
  already creates registrations and shows "待完成付款。", and the patron pays at
  the temple as they would from the website. The app states the status and
  nothing more, by the Director's principle that the patron is not a messenger
  for the temple (commit fda6678), so no cash instructions are added.

Payment in the app becomes real work when a temple brings an ECPay merchant
account. It already has a plan, `EXPO_PAYMENT_PHASE_PLAN.md` (2026-08-11): no
Apple in-app purchase, checkout in the phone's browser, then back to the app.
The inventory it asked for, the store rules, and the web-side defects to fix
first are recorded there.

## Phase 3 — Block the account area on phones

Detect a phone, and show a page linking to the app instead of the account area.

Blocked on **something to link to.** There is no App Store listing yet — build
4 is in TestFlight — and Android has no release lane at all. Payment no longer
blocks it (Phase 2, above). What else the account area does that the app does
not has not been checked for this phase.

## Not in this plan

- **Landscape.** Director's call.
- **A mobile version of the account area.** The decision above rules it out.
- **The admin area.** Staff use it at a desk, and it is a different user from a
  patron. The scan found `/admin/login` scrolls sideways on a phone; that is
  recorded there and not scheduled here.
