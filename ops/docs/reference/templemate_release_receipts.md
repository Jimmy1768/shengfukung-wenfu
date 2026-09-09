# TempleMate version, build, and update receipts

| App version | iOS build | Android code | iOS build state | Published OTA update |
| --- | --- | --- | --- | --- |
| 1.0.0 | 1 | 1 | uploaded, distributed, installed by staff | see the update table below |
| 1.0.0 | 2 | 1 | prepared in `versioning.js`, not confirmed uploaded | none recorded |

Build 1 was uploaded to TestFlight, installed by Director's staff, and reported
green (Director, 2026-08-31). `versioning.js` was subsequently bumped to
iOS build 2 (`5e1e3cd`); whether that build was uploaded is not confirmed here.

Apple-side state is not visible from this repository. Any claim about
submission, review, or acceptance status must come from the Director or App
Store Connect, never from inference off `versioning.js`.

## Published OTA updates

| Update group | Date | Channel | Runtime | Platforms | Source commit |
| --- | --- | --- | --- | --- | --- |
| `ad7dd713-f47a-425c-89ce-0b3e04dfbefe` | 2026-09-03 | `testflight` | 1.0.0 | android, ios | `92cd19a` |
| `74f188d5-6b61-48c0-b82b-8df94005ede5` | 2026-09-03 | `testflight` | 1.0.0 | android, ios | `6095967` |
| `ad7dd713…` republished as rollback | 2026-09-03 | `testflight` | 1.0.0 | android, ios | `92cd19a` |
| `a81381b8-bbec-4bcd-baa3-564685a92fe1` | 2026-09-04 | `testflight` | 1.0.0 | android, ios | `a2c7450` |
| `b15df493-30a7-4535-a573-e9844f3ca4f3` | 2026-09-04 | `testflight` | 1.0.0 | android, ios | `cd6a257` |
| `1f1dd0ec-31a2-4f58-82ed-294b99ddf04c` | 2026-09-04 | `testflight` | 1.0.0 | android, ios | `c7a8d0a` |
| `4c774de9-1cb6-499b-81ef-8b2b5968b192` | 2026-09-05 | `testflight` | 1.0.0 | android, ios | `de6bc98` |
| `b8f71bc2-e129-499d-b7cc-af3cb0907e19` | 2026-09-05 | `testflight` | 1.0.0 | android, ios | `b4af067` |
| `68336027-831c-4d46-ac88-1294c427acfd` | 2026-09-09 | `testflight` | 1.0.0 | android, ios | `05b7154` |
| `646240e2-f2e5-46ea-88ed-989cd4fa37e9` | 2026-09-09 | `testflight` | 1.0.0 | android, ios | `6ddf4aa` |

Message: "profile parity, OAuth prefill, remembered temple, demo tenant name".
Published by the Director from `release-1.0.0`, the first publish under the
release-branch rule.

EAS recorded the commit with a trailing `*`, meaning the working tree was not
clean. Nothing under `mobile/` was dirty — the untracked `.claude/` directory
and an in-progress edit to `ops/protocol/claude_work_mode.md` were — so the
published bundle matches `92cd19a` exactly.

Carried, being every mobile change since build 1 was reported green:

- `984018d` existing registrations surfaced, profile name prefilled, real temple name
- `6224452` demo tenant shows 示範宮廟 rather than the real temple's name
- `b2faeab` profile screen to four fields, real error messages
- `b54a58f` OAuth resolution prefilled from the provider's name and email
- `751ea19` remembered temple survives sign-out

`74f188d5` follows because that last one did not work. `751ea19` stopped
`App.js` clearing the binding but not `adapter.logout()`, which clears it
through `clearRetainedState` — so signing out still returned the patron to the
QR scanner. `6095967` removes the clear from the adapter and is covered by a
test that fails if it comes back.

Both updates carry a trailing `*` on the commit, meaning an unclean tree. In
both cases nothing under `mobile/` differed, so each bundle matches its commit
exactly; the untracked `.claude/` directory accounts for it.

### 2026-09-04: three updates crashed before one worked

`ae82ad6` (dummy client removed) crashed on launch. `a2c7450` added a boot
guard and did not fire, which narrowed it to render rather than module scope.
`868bbee` added an error boundary that caught the crash but rendered a white
screen -- its failure screen used SafeAreaProvider, which renders null until it
measures. `75cd73c` made that screen dependency-free.

The cause was found on the Pixel dev client against local Rails in minutes,
not through those OTA cycles: `AccountSurface` referenced `loadingText`, which
is defined inside `AppBody` and never passed to it. Pre-existing, and only
reachable once a release build could restore its temple and stop landing on
TenantSetupGate -- the earlier binding bug had been hiding it. `cd6a257` fixes
it and adds a test that fails if the prop is dropped again.

`c7a8d0a` follows and was found the recorded way -- on the Pixel against local
Rails, before publishing. Two faults the Director hit on production: OAuth
sign-in never called loadCollections, so Google users saw the registrations
bootstrap returns and no offerings at all; and every bound screen carried the
removed dummy client's disclosure, telling patrons the app never contacts a
service while it was talking to the server.

**Lesson recorded because it cost three publishes:** debug on the dev client
against a local server. An OTA round trip tells you almost nothing, and the
device is only reachable through TestFlight for iOS -- which is exactly why the
error boundary is worth keeping, and why it was verified by throwing on purpose
and reading the result off the device rather than assumed to work.

### 2026-09-05: an event's own image, and a fixture that lied

`de6bc98` sends `hero_image_url` in `offering_payload` and renders it in
`OfferingList`. The offering's OWN picture only -- `EventShow.vue:37` falls
back to the temple's `event` image because one large hero about one event is
worth showing even when it is the default, but in a list every image-less row
would carry that same picture. The Director's ruling: "own image only, no
fallback."

**Shipped in two halves, app first.** The app reads a key the server had to
start sending, so between the two the update was inert -- it rendered no image,
exactly the prior behavior, no regression and no feature. That order was
deliberate: the reverse would have had the server sending a key no client could
use. `de6bc98` reached `release/current` the same day and the droplet was
restarted, so both halves are live.

Verified on the Pixel dev client against local Rails before publishing, as the
2026-09-04 lesson requires. The first attempt looked like a bug and was not:
the test fixture pointed at `placehold.co`, which serves `image/svg+xml` by
default, and React Native's `Image` cannot render SVG -- it laid out the 132dp
box and drew nothing, with no error in logcat, on device, or in the bundle.
Adding `.png` to the URL rendered it immediately. **A fixture can fail in a way
that is indistinguishable from the code failing.**

Consequence still open: nothing validates that a pasted `hero_image_url` is a
raster format, so a temple admin pasting an SVG gets a silently blank box in
the app while the website renders it fine.

The new test is mutation-checked -- reintroducing the fallback fails it with
its own message, so it is not passing for the wrong reason.

### 2026-09-05: three partial copies, one of them mine

`b4af067`. All three faults were the same shape -- a concept with a complete
owner and a partial copy standing in front of it.

- **Registrant name rendered as `<title> · ` on every card.** I had called this
  cosmetic. It was not. `TempleRegistration#registrant_name` resolves through
  six sources and ends at 訪客, so it never returns blank;
  `RegistrationSerializer` re-implemented it with two and returned nil when
  both were empty. `registrant_scope` sat beside it with the same fault: the
  model infers "dependent" from a present `dependent_id`, the copy always fell
  back to `"self"`, so a dependent registration whose metadata had lost the key
  was reported to the app as the account holder.
- **`offering_payload` existed twice** with different field sets. That is how
  `hero_image_url` reached the list on 2026-09-05 and silently missed the
  registration screen the same day. `NativeBaseController` owns the single
  builder now, and a test asserts both surfaces return the same key set.
- **An unrenderable image left a blank 132dp band.** Fixed in the app, not by
  validating formats server-side: an extension check passes extensionless SVGs,
  and a partial guard is the fault being fixed here. `OfferingImage` collapses
  on error, so SVG, 404 and dead host all degrade to "no image".

**The lesson is about the fix immediately before this one.** `de6bc98` added
`hero_image_url` to one `offering_payload` without checking whether there was a
second. There was. Grepping every definition of the thing being changed is
cheap; the earlier receipt for `751ea19` / `6095967` records the same failure
against the temple binding.

Trailing `*` on the commit is the untracked `.claude/` directory again; nothing
under `mobile/` differed, so the bundle matches `b4af067` exactly.

### 2026-09-09: an album you could see but not open

`05b7154`. The Director uploaded the first real gallery album through the admin
console and reported the same defect on both surfaces: the album was visible in
the app and on the website, with no way to open it and look at the photos.

Same shape on each, and neither was a data problem. `photo_urls` has been in
the native payload all along -- `native_resources#galleries` sends it for both
the list and the detail -- and the website already had the URLs in hand. What
was missing was the rendering. In the app, `DataSection` drew a gallery entry
as one line of text and had exactly one caller. On the website, the photos were
90px `object-fit: cover` thumbnails with no click handler, so every picture
arrived cropped with no way to see it whole.

Both now open a photo full-size, contained rather than cropped, with wrapping
prev/next. The app expands the album in place rather than pushing a screen,
because navigation there is a single `screen` string with no stack; Android
back closes the photo through `onRequestClose` instead of leaving the screen.
The website locks the body while the overlay is up, so a wheel scroll behind it
cannot silently move the page underneath.

`DataSection` also read `item.date`, a field this payload does not have, so the
date it meant to show was always undefined. It is `event_date`, and it is
sliced rather than parsed so a `Date` cannot shift the day across timezones.

**Shipped in two halves again, website first.** `bin/deploy_vue` ran the same
day and the site was verified against the Director's own album on production --
the live bundle is the one the droplet built, and 中秋祈福活動（1／2）opens with
its S3 image. No restart: no Rails code, no migration, no Gemfile change.

Each of the three new app guards was mutation-checked -- reintroducing the
defect fails the test -- so none is passing for the wrong reason. Verification
of the app half is the Director's on the Pixel, per the 2026-09-04 lesson;
this receipt does not claim it.

Trailing `*` on the commit is the untracked `.claude/` directory again; nothing
under `mobile/` differed, so the bundle matches `05b7154` exactly.

### 2026-09-09: the same album, built the second time as it was asked for

`6ddf4aa` follows `05b7154` on the same report, because the first attempt
answered the symptom instead of the request. The Director had asked for an
album page; what shipped made the photos openable where they already were. His
correction: "the central problem is, as i said, it needs to go to an album
page. so it's missing a link, and a dedicated page."

Two faults, one on each surface, both structural rather than visual.

- **The app had no Gallery screen.** The albums lived at the bottom of Explore,
  under every offering a patron could register for -- two unrelated things on
  one screen, the albums reachable only by scrolling past the whole catalogue.
  `05b7154` had then made each album expand in place, so a twenty-photo album
  unrolled inside the offering list. The Director: "i don't want to load all 20
  photos into the app screen."
- **The website had no album page.** `/archive` rendered every photo of every
  album inline, so a visitor scrolled past dozens of crops and could not reach
  an album as a thing in itself.

Gallery is now its own menu destination, listing albums with one cover each;
opening one shows that album alone, and only that album loads its photos.
`/archive` is an index of album cards linking to `/archive/:id`, a contact
sheet for that album. The lightbox from `05b7154` survives on both, moved to
where an album is actually being viewed.

Android back closes an open album back to the list rather than jumping home --
without it, opening a second album took three taps -- and any tab press clears
the selection so the Gallery tab always lands on the list. Each of the four
navigation guards was mutation-checked.

**Lesson, and it is not a new one.** The report named the missing thing --
a link and a page -- and the first fix treated it as a rendering gap. Reading
the request as a symptom to be relieved rather than a design to be built cost
a full publish cycle, and the Director had to say the same thing twice.

Website verified on production against his own albums before this publish:
three index cards with covers, dates and counts; `/archive/11` opens two S3
photos; `/archive/999` says not found. Verification of the app half is the
Director's on the Pixel, per the 2026-09-04 lesson; this receipt does not
claim it.

Trailing `*` on the commit is the untracked `.claude/` directory again; nothing
under `mobile/` differed, so the bundle matches `6ddf4aa` exactly.

## Working lanes (Director, 2026-08-31)

- **Iterate on the Android dev-client APK.** Build the dev client once
  (`eas build --platform android --profile development` — internal
  distribution, `buildType: apk`, no channel), then serve JS to it with
  `yarn dev-client`. This mirrors DojoMate-Expo, which likewise has no
  `build:*:development` script because the APK is a one-time artifact.
- **Promote to iOS only when ready for a production test**, not for routine
  verification.
- **`testflight` is an EAS Update channel.** Simple JS changes ship to it as
  an OTA update; they do not require a rebuild. Native config, native
  dependency, or `runtimeVersion` changes still do.

`runtimeVersion` is pinned to `versioning.appVersion` (`1.0.0`) at the top
level of `app.config.js`, so OTA updates only reach builds sharing that
version.

## Source

- `mobile/versioning.js` — the single version/build source.
- `mobile/eas.json` — `development`, `testflight`, `production` profiles.
- `mobile/package.json` — `dev-client`, `build:testflight`, `ota:testflight`.
- `ops/docs/reference/templemate_eas_ota_release_lanes.md` — the lane contract
  and the guarded OTA wrappers.
