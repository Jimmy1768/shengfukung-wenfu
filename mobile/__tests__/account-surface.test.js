const test = require('node:test');
const assert = require('node:assert/strict');
const { accountMenu, isAccountScreen, isBoundPresentation, isPaidFixtureReadOnly, safeBoundScreen, visibleLocale, visibleTheme } = require('../app/account/screen_model');

test('the account screen model admits only account screens', () => {
  for (const screen of ['home', 'profile', 'dependents', 'registrations', 'discover', 'gallery', 'settings', 'signup', 'recovery', 'assistance', 'privacy', 'closure', 'connection']) assert.equal(isAccountScreen(screen), true);
  assert.equal(isAccountScreen('contact'), false);
  assert.equal(isAccountScreen('admin'), false);
  assert.deepEqual(accountMenu(), ['home', 'profile', 'dependents', 'registrations', 'discover', 'gallery'],
    'the gallery is its own destination, not a tail on the offering catalogue');
  assert.equal(isPaidFixtureReadOnly({ readOnly: true }), true);
  assert.equal(isPaidFixtureReadOnly({ readOnly: false }), false);
  assert.equal(isBoundPresentation({ state: 'unbound' }), false);
  assert.equal(safeBoundScreen('settings', { state: 'unbound' }), 'home',
    'an unbound device cannot reach a bound screen');
});

test('locale and theme foundations are deterministic', () => {
  assert.equal(visibleLocale('zh-TW'), 'zh-TW');
  assert.equal(visibleLocale('en'), 'en');
  assert.equal(visibleLocale('unsupported'), 'zh-TW');
  assert.equal(visibleTheme(false), 'light');
  assert.equal(visibleTheme(true), 'dark');
});
