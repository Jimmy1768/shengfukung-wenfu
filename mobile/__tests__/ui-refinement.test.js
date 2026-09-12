const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const { emptyFeedback, errorFeedback, feedbackForNavigation, noticeFeedback } = require('../app/ui/feedback');

test('feedback state owns errors and destination notices across navigation, reset, and locale boundaries', () => {
  assert.deepEqual(feedbackForNavigation(errorFeedback('Message is required', 'assistance'), 'privacy'), emptyFeedback());
  const forwarded = noticeFeedback('saved', 'settings');
  assert.deepEqual(feedbackForNavigation(forwarded, 'settings'), forwarded);
  assert.deepEqual(feedbackForNavigation(forwarded, 'closure'), emptyFeedback());
  assert.deepEqual(emptyFeedback(), { error: null, notice: null }, 'reset and locale changes clear all transient feedback');
});

// The demo phrases this used to require are gone from the list. Asserting them
// PRESENT was the dummy client written down as a contract: it would have failed
// the moment the retired copy was removed, which is backwards for strings no
// build can reach. What is worth pinning is that both locales are complete and
// that vocabulary which never belonged in patron-facing copy stays out.
test('refined presentation keeps both complete locales', () => {
  const source = read('app/ui/copy.js');
  for (const phrase of ['TempleMate', '連結失敗', 'Connection failed']) assert.match(source, new RegExp(phrase));
  for (const gone of ['cameraInvalidQr:', 'cameraInstructions:']) {
    assert.equal(source.includes(gone), false, `${gone} is the demo half of a pair no build reads`);
  }
  assert.equal(source.includes('OAuth'), false);
  assert.equal(source.includes('checkout'), false);
});

test('presentation uses generated token authority and a single-line native business menu', () => {
  const theme = read('app/ui/theme.js');
  const app = read('App.js');
  const primitives = read('app/ui/primitives.js');
  assert.match(theme, /getTheme/);
  assert.match(theme, /temple-1/);
  assert.match(theme, /ops-dark/);
  assert.match(app, /accountMenu\(\)/);
  assert.match(app, /<ScrollView horizontal accessibilityRole="tablist"/);
  assert.match(app, /navigationShell: \{ flexGrow: 0, borderBottomWidth: 1 \}/);
  assert.match(app, /flexWrap: 'nowrap'/);
  assert.match(app, /navigation: \{ flexDirection: 'row', flexWrap: 'nowrap', alignItems: 'center'/);
  assert.equal(app.includes('Text numberOfLines={1} style={{ color: screen === key'), false);
  assert.match(app, /accessibilityRole="tablist"/);
  assert.match(primitives, /accessibilityRole="alert"/);
});

// The gallery lived at the bottom of Explore, rendered as one line of text per
// album -- so one screen held every offering a patron could register for AND
// the temple's photos, and the photos were only reachable by scrolling past
// the whole catalogue. photo_urls has been in the payload throughout.
test('the gallery is its own screen, and an album is its own step inside it', () => {
  const app = read('App.js');
  const copy = read('app/ui/copy.js');
  assert.equal(app.includes('<GallerySection'), false, 'the gallery no longer rides along on Explore');
  assert.equal(/screen === 'discover'[\s\S]{0,1200}data\.gallery/.test(app), false,
    'Explore is the offering catalogue only');
  assert.match(app, /if \(screen === 'gallery' && album\) return <AlbumScreen/);
  assert.match(app, /if \(screen === 'gallery'\) return <Section title=\{t\.gallery\}/);
  assert.match(app, /data\.gallery\.map\(item => <AlbumCard/, 'the list shows albums, not photos');
  assert.match(app, /const cover = \(album\.photo_urls \|\| \[\]\)\[0\]/, 'one cover per album');
  assert.match(app, /onPress=\{\(\) => setAlbum\(item\)\}/);
  assert.match(app, /onRequestClose=\{onClose\}/, 'Android back closes the photo, not the screen');
  assert.match(app, /resizeMode="contain"/, 'the opened photo is shown whole, not cropped like the sheet');
  assert.match(app, /setAlbum\(null\); setScreen\(destination\)/, 'a tab press lands on the album list');
  assert.match(app, /albumOpen: Boolean\(album\)/);
  assert.match(app, /item\.event_date/);
  assert.equal(/albumCaption[\s\S]{0,240}item\.date\b/.test(app), false, 'item.date does not exist on this payload');
  for (const key of ['photos:', 'emptyAlbum:', 'closePhoto:', 'previousPhoto:', 'nextPhoto:', 'backToAlbums:']) {
    assert.equal((copy.match(new RegExp(`\\b${key}`, 'g')) || []).length, 2, `${key} needs both locales`);
  }
});

test('bound header places Settings beside Sign out while the unbound gate exposes Sign out only', () => {
  const app = read('App.js');
  assert.match(app, /onSettings=\{\(\) => navigate\('settings'\)\}/);
  assert.match(app, /headerUtilities.*activeTenant && <Button label=\{t\.settings\}.*<Button label=\{t\.signOut\}/);
  assert.match(app, /<Header t=\{t\} palette=\{palette\} binding=\{binding\} onSignOut=\{signOut\} \/>/);
});

test('signed-out OAuth status uses the existing locale outcome dictionaries', () => {
  const app = read('App.js');
  const copy = read('app/ui/copy.js');
  assert.match(app, /t\.oauthOutcome\[oauthState\.phase\] \|\| t\.oauthOutcome\.idle/);
  assert.equal(app.includes('t.oauthState'), false);
  assert.equal((copy.match(/\boauthOutcome:/g) || []).length, 2);
  assert.equal(copy.includes('oauthState:'), false);
});

test('tenant connection presentation uses the shared retained-tenant selector', () => {
  const app = read('App.js');
  assert.match(app, /import \{ activePresentationTenant,/);
  assert.ok((app.match(/activePresentationTenant\(binding\)/g) || []).length >= 3);
  assert.equal(app.includes("binding.state === 'bound' ? binding.tenant.name"), false);
});

// The temple is forgotten in exactly one place, reached from one control. Every
// other path that used to clear it -- sign-out, session expiry, account
// closure, OAuth, the fixture switch-temple flow -- was a bug, each found
// separately over 2026-09-04.
// Criterion 7. isReleaseConfig was the surviving half of the dummy-client
// switch, and it selected behaviour rather than wording -- which is why a scan
// never loaded a temple in a release build: the code that names one after
// loading sat on the side a release build never ran.
test('one code path serves every build', () => {
  for (const file of ['App.js', 'app/real/config.js', 'app/tenant/storage.js']) {
    assert.equal(read(file).includes('isReleaseConfig'), false, `${file} still selects behaviour by build`);
  }
});

// Criterion 2. The scan must load the temple it just confirmed -- its name and
// its collections -- not merely record the slug. This previously called
// setData(adapter.snapshot()): the snapshot exactly as it already was.
test('a scan loads the temple it confirmed', () => {
  const app = read('App.js');
  const handler = app.slice(app.indexOf('const onCameraResult'), app.indexOf('const onCameraResult') + 1400);
  assert.match(handler, /trustedBindingStorage\.save\(result\)/, 'the confirmed temple is recorded');
  assert.match(handler, /adapter\.bootstrap\(\)/, 'and loaded: bootstrap carries the temple name');
  assert.match(handler, /adapter\.loadCollections\(\)/, 'and its collections');
  assert.equal(/setData\(adapter\.snapshot\(\)\)/.test(handler), false,
    'the snapshot as it already was is not a load');
});

// Criterion 6. Collections are six temple-scoped requests; asking for them
// with no temple loaded is what produced the error banner on the scanner.
test('temple-scoped collections are never requested without a temple', () => {
  const app = read('App.js');
  const loads = app.split('adapter.loadCollections()');
  assert.equal(loads.length - 1, 3, 'three call sites: startup, sign-in, and the scan');
  for (const before of loads.slice(0, -1)) {
    const window = before.slice(-700);
    assert.match(window, /activePresentationTenant|onCameraResult|bootstrap\(\)/,
      'each load is reached only with a temple in hand');
  }
});

test('only the explicit Unbind control forgets the temple', () => {
  const app = read('App.js');
  assert.match(app, /const onUnbindTemple = async \(\) => \{/);
  assert.equal((app.match(/trustedBindingStorage\.clear\(\)/g) || []).length, 1,
    'exactly one caller may clear the stored binding');
  assert.match(app, /label=\{t\.unbindTemple\} palette=\{palette\} tone="secondary" onPress=\{onUnbindTemple\}/);
  for (const gone of ['clearReleaseBinding', 'confirmSwitch', 'requestSwitch', 'clearPriorTenant', 'fixtureConnectionLink']) {
    assert.equal(app.includes(gone), false, `${gone} belonged to the removed fixture switch flow`);
  }
});

// AccountSurface is a top-level function, so anything defined inside AppBody is
// out of scope for it. loadingText was referenced there and never passed --
// a ReferenceError that only fired on a render where collections === 'loading',
// and only reached at all once a release build could restore its temple and
// skip TenantSetupGate. It crashed production while every test, the linter and
// the bundler stayed green.
test('AccountSurface receives every value it renders', () => {
  const app = read('App.js');
  const destructure = app.match(/const \{([^}]*)\} = props;/);
  assert.ok(destructure, 'AccountSurface must destructure its props');
  const received = destructure[1].split(',').map(name => name.trim());
  const body = app.slice(app.indexOf('function AccountSurface(props) {'));

  for (const name of ['loadingText', 'collections', 'binding', 'onUnbindTemple']) {
    if (!body.includes(name)) continue;
    assert.ok(received.includes(name),
      `AccountSurface renders ${name} but never receives it -- it cannot close over AppBody`);
  }
});

test('Doctor stays project-local and reports unavailable metadata checks in offline mode', () => {
  const pkg = JSON.parse(read('package.json'));
  assert.equal(pkg.devDependencies['expo-doctor'], '1.20.1');
  assert.equal(pkg.scripts.doctor.includes('npx'), false);
  assert.match(pkg.scripts.doctor, /EXPO_DOCTOR_WARN_ON_NETWORK_ERRORS=1 expo-doctor/);
  assert.equal(pkg.expo.doctor.reactNativeDirectoryCheck.enabled, false);
});
