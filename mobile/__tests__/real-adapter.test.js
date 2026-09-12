const test = require('node:test');
const assert = require('node:assert/strict');
const { createRealAdapter } = require('../app/real/adapter');
const { resolveClientConfig, localTenantBinding } = require('../app/real/config');
const { sessionKey } = require('../app/real/storage');
const { createTrustedBindingStorage } = require('../app/tenant/storage');
const { storageScope } = require('../app/core/storage_scope');
const { createOAuthController } = require('../app/oauth/transaction');
const { nativeError } = require('../app/real/response');

const config = { mode: 'real', apiBaseUrl: 'http://local.test', tenantSlug: 'fixture-temple', environment: 'test' };
const store = () => { const values = new Map(); return { values, getItem: async key => values.get(key) || null, setItem: async (key, value) => values.set(key, value), deleteItem: async key => values.delete(key) }; };
const user = { id: 1, email: 'member@example.test', native_name: '林小安' };
const session = { access_token: 'access-1', refresh_token: 'refresh-1', token_type: 'Bearer', expires_in: 900 };
const response = (body = {}, status = 200) => ({ ok: status >= 200 && status < 300, status, body });

// The routes a patron can reach with no temple loaded. Everything else is
// temple-scoped and the server refuses it without one.
const SESSION_PATHS = ['/login', '/signup', '/refresh', '/password/recovery', '/password/reset', '/oauth/start', '/oauth/exchange', '/oauth/resolution/existing', '/oauth/resolution/new'];
const KNOWN_TEMPLES = new Set(['fixture-temple', 'first-temple', 'second-temple', 'shengfukung-wenfu']);

function fixtureTransport(calls, failures = {}, overrides = {}) {
  return async request => {
    calls.push(request);
    const path = request.url.replace(/^.*\/native/, '').replace(/\?.*$/, '');
    // The server's temple rules, before any route answers. A fixture that
    // answers every path successfully whatever it is sent cannot fail, and a
    // test built on one is not evidence -- which is exactly how a temple-less
    // sign-in was reported as working against a server that returns 422.
    const found = /[?&]temple_slug=([^&]*)/.exec(request.url);
    const slug = found ? decodeURIComponent(found[1]) : '';
    if (slug && !KNOWN_TEMPLES.has(slug)) return response({ error: 'tenant_not_found', code: 'tenant_not_found' }, 404);
    if (!slug && !SESSION_PATHS.includes(path)) return response({ error: 'tenant_required', code: 'tenant_required' }, 422);
    if (overrides[path]) return overrides[path];
    if (failures[path]) return failures[path];
    if (path === '/login' || path === '/signup' || path === '/password/reset') return response({ user, session });
    if (path === '/oauth/start') return response({ oauth: { authorization_url: 'https://central.example.test/authorize', redirect_uri: 'templemate://oauth/complete', transaction_token: 'opaque-native-transaction', provider: JSON.parse(request.body).oauth.provider, expires_in: 300 } }, 201);
    if (path === '/oauth/exchange') return response({ user, session, oauth: { provider: 'google', profile_required: false } });
    if (path === '/refresh') return response({ session: { ...session, access_token: 'access-2', refresh_token: 'refresh-2' } });
    if (path === '/bootstrap') return response({ user, temple: { slug: 'fixture-temple', name: 'Fixture' }, preferences: { locale: 'zh-TW' }, registrations: [{ id: 9, offering: { id: 1, title: '祈福', slug: 'prayer', account_action: 'event', price_cents: 1200, currency: 'TWD' }, quantity: 1, total_amount_cents: 1200, fulfillment_status: 'pending', payment_status: 'unpaid', lifecycle: 'pending', payment_state: 'unpaid' }], certificates: [{ id: 3 }] });
    if (path === '/profile') return response({ user: { ...user, native_name: '新名字' } });
    if (path === '/dependents') return request.method === 'GET' ? response({ dependents: [{ id: 4, native_name: '家屬', relationship_label: '家人' }] }) : response({ dependent: { id: 5, native_name: '新家屬', relationship_label: '子女' } }, request.method === 'POST' ? 201 : 200);
    if (/^\/dependents\//.test(path)) return request.method === 'DELETE' ? response({}, 204) : response({ dependent: { id: 4, native_name: '家屬', relationship_label: '家人' } });
    if (path === '/registrations') return request.method === 'GET' ? response({ registrations: [{ id: 9, offering: { id: 1, title: '祈福', slug: 'prayer', account_action: 'event', price_cents: 1200, currency: 'TWD' }, quantity: 1, total_amount_cents: 1200, fulfillment_status: 'pending', payment_status: 'unpaid', lifecycle: 'pending', payment_state: 'unpaid' }] }) : response({ registration: { id: 10, offering: { id: 2, title: '超薦', slug: 'memorial', account_action: 'event', price_cents: 600, currency: 'TWD' }, quantity: 1, total_amount_cents: 600, fulfillment_status: 'pending', payment_status: 'unpaid', lifecycle: 'pending', payment_state: 'unpaid' } }, 201);
    if (/^\/registrations\/new/.test(path)) return response({ offering: { id: 1, title: '祈福', slug: 'prayer', account_action: 'event', price_cents: 1200, currency: 'TWD' }, registration: { quantity: 1 }, registrants: [{ scope: 'self', id: 1, label: '林小安' }] });
    if (/^\/registrations\/\d+\/edit/.test(path)) return response({ registration: { id: 9, offering: { id: 1, title: '祈福', slug: 'prayer', account_action: 'event', price_cents: 1200, currency: 'TWD' }, quantity: 1, total_amount_cents: 1200 } });
    if (/^\/registrations\/\d+/.test(path)) return response({ registration: { id: 9, offering: { id: 1, title: '祈福', slug: 'prayer', account_action: 'event', price_cents: 1200, currency: 'TWD' }, quantity: 1, total_amount_cents: 1200, fulfillment_status: 'pending', payment_status: 'unpaid', lifecycle: 'pending', payment_state: 'unpaid' } });
    if (['/events', '/services', '/galleries', '/certificates', '/privacy', '/preferences'].includes(path)) return response({ [path.slice(1)]: [] });
    if (/^\/galleries\//.test(path)) return response({ gallery: { id: 1 } });
    return response({ accepted: true }, request.method === 'POST' ? 201 : 200);
  };
}

test('there is one mode, and it cannot be configured without tenant and API inputs', () => {
  // No dummy fallback to land in: a build with nothing configured fails loudly
  // rather than quietly serving fixtures.
  assert.throws(() => resolveClientConfig({}), { code: 'REAL_CONFIG_REQUIRED' });
  assert.throws(() => resolveClientConfig({ clientMode: 'real' }), { code: 'REAL_CONFIG_REQUIRED' });
  assert.equal(resolveClientConfig({ clientMode: 'real', localApiBaseUrl: 'http://local.test/', localTenantSlug: 'fixture', clientEnvironment: 'test' }).tenantSlug, 'fixture');
  assert.throws(() => resolveClientConfig({ clientMode: 'real', localApiBaseUrl: 'https://example.com', localTenantSlug: 'fixture' }), { code: 'TRUSTED_API_REQUIRED' });
  const release = resolveClientConfig({ clientEnvironment: 'testflight', apiBaseUrl: 'https://shengfukung.com.tw', tenantSlug: 'shengfukung-wenfu', easUpdateChannel: 'testflight' });
  assert.equal(release.mode, 'real'); assert.equal(release.updateChannel, 'testflight');
  assert.throws(() => resolveClientConfig({ clientEnvironment: 'production', apiBaseUrl: 'http://shengfukung.com.tw', tenantSlug: 'shengfukung-wenfu' }), { code: 'TRUSTED_API_REQUIRED' });
  // Needs a config that clears the origin/tenant checks first, since without a
  // dummy fallback those now fire before the OAuth return URL is looked at.
  assert.throws(() => resolveClientConfig({ localApiBaseUrl: 'http://local.test/', localTenantSlug: 'fixture', clientEnvironment: 'test', nativeOAuthReturnUrl: 'templemate://wrong' }), { code: 'NATIVE_OAUTH_RETURN_REQUIRED' });
  assert.deepEqual(localTenantBinding(config), { state: 'bound', tenant: { id: 'fixture-temple', name: 'fixture-temple' }, error: null, source: 'local-test' });
});

test('real adapter maps the complete account contract and never falls back to dummy data', async () => {
  const calls = []; const local = store(); const adapter = createRealAdapter({ config, store: local, transport: fixtureTransport(calls) });
  const signedIn = await adapter.signIn({ email: user.email, password: 'test-password' });
  assert.equal(adapter.kind, 'real'); assert.equal(adapter.network, 'local-test'); assert.equal(signedIn.profile.name, '林小安');
  assert.deepEqual(signedIn.registrations[0], { id: '9', offering: { id: '1', title: '祈福', slug: 'prayer', account_action: 'event', price_cents: 1200, currency: 'TWD' }, registrantName: '', registrantScope: 'self', dependentId: null, quantity: 1, totalAmountCents: 1200, state: 'pending', lifecycle: 'pending', lifecycleStage: null, paymentState: 'unpaid', readOnly: false });
  await adapter.signUp({ email: user.email, password: 'test-password' });
  await adapter.recoverPassword({ email: user.email }); await adapter.resetPassword({ token: 'local-reset', password: 'test-password', password_confirmation: 'test-password' });
  await adapter.refresh(); assert.equal(adapter.snapshot().profile.email, user.email);
  await adapter.updateProfile({ name: '新名字' }); await adapter.addPassword({ password: 'new-password', password_confirmation: 'new-password' });
  await adapter.listDependents(); await adapter.showDependent(4); await adapter.createDependent({ name: '新家屬', relationship: '子女' }); await adapter.updateDependent(4, { name: '家屬', relationship: '家人' }); await adapter.deleteDependent(5);
  await adapter.listRegistrations(); await adapter.showRegistration(9); await adapter.newRegistration({ offering: 'prayer' }); await adapter.createRegistration({ offering: 'prayer', registrantName: '林小安' }); await adapter.editRegistration(9); await adapter.updateRegistration(9, { registrantName: '林小安' });
  await adapter.events(); await adapter.services(); await adapter.galleries(); await adapter.gallery(1); await adapter.certificates(); await adapter.submitAssistance({ message: 'help' }); await adapter.preferences(); await adapter.updatePreferences({ locale: 'zh-TW', mobile_theme_id: 'default' }); await adapter.privacy(); await adapter.requestPrivacy({ kind: 'export' });
  assert.ok(calls.every(call => call.url.includes('temple_slug=fixture-temple')));
  assert.ok(calls.some(call => call.headers.Authorization === 'Bearer access-1' || call.headers.Authorization === 'Bearer access-2'));
  const profile = calls.find(call => call.url.includes('/profile?') && call.method === 'PATCH');
  assert.deepEqual(JSON.parse(profile.body), { profile: { native_name: '新名字' } });
  assert.equal(calls.some(call => /admin|oauth|checkout|provider/i.test(call.url)), false);
  assert.equal(JSON.stringify(signedIn.registrations[0]).match(/provider|checkout|payment_reference/i), null);
  await adapter.logout(); assert.equal(local.values.size, 0);
});

test('real local/test Assistance sends the exact profile-channel body, maps duplicate outcomes, and preserves the account snapshot', async () => {
  const calls = []; const adapter = createRealAdapter({ config, store: store(), transport: fixtureTransport(calls, {}, { '/assistance': response({ assistance_request: { id: 9, status: 'open' } }, 201) }) });
  await adapter.signIn({ email: user.email, password: 'test-password' });
  const before = adapter.snapshot();
  assert.deepEqual(await adapter.submitAssistance({ channel: 'ignored', message: 'help' }), { outcome: 'created' });
  assert.deepEqual(adapter.snapshot(), before);
  const call = calls.find(item => item.method === 'POST' && item.url.includes('/assistance?'));
  assert.deepEqual(JSON.parse(call.body), { assistance: { channel: 'profile', message: 'help' } });
  const duplicateCalls = []; const duplicate = createRealAdapter({ config, store: store(), transport: fixtureTransport(duplicateCalls, {}, { '/assistance': response({ assistance_request: { id: 9, status: 'open' }, duplicate: true }) }) });
  await duplicate.signIn({ email: user.email, password: 'test-password' });
  const duplicateBefore = duplicate.snapshot();
  assert.deepEqual(await duplicate.submitAssistance({ message: 'again' }), { outcome: 'duplicate' });
  assert.deepEqual(duplicate.snapshot(), duplicateBefore);
  const duplicateCall = duplicateCalls.find(item => item.method === 'POST' && item.url.includes('/assistance?'));
  assert.deepEqual(JSON.parse(duplicateCall.body), { assistance: { channel: 'profile', message: 'again' } });
});

test('real session expiry, replay, revocation, closure and tenant cleanup clear the scoped state without dummy fallback', async () => {
  for (const code of ['session_invalid', 'session_replayed', 'session_revoked', 'account_closed']) {
    const local = store(); const initial = createRealAdapter({ config, store: local, transport: fixtureTransport([]) });
    await initial.signIn({ email: user.email, password: 'test-password' });
    const adapter = createRealAdapter({ config, store: local, transport: fixtureTransport([], { '/bootstrap': response({ code }, 401) }) });
    await assert.rejects(adapter.restoreSession(), { code });
    assert.equal(local.values.size, 0, code);
  }
  const local = store(); const adapter = createRealAdapter({ config, store: local, transport: fixtureTransport([]) });
  await adapter.signIn({ email: user.email, password: 'test-password' });
  assert.ok(local.values.has(sessionKey({ environment: 'test', tenantId: 'fixture-temple' })));
  await adapter.clearTenantState(); assert.equal(local.values.size, 0);
  await adapter.signIn({ email: user.email, password: 'test-password' }); await adapter.closeAccount(); assert.equal(local.values.size, 0);
});

test('logging out clears the session but keeps the remembered temple', async () => {
  // The binding is a fact about the device, not the session. clearRetainedState
  // runs on logout, on session expiry and on a failed restore, and it used to
  // wipe the binding at every one of them -- so signing out sent the patron
  // back to the QR scanner. Re-scanning overwrites it, so nothing needs a clear.
  // Bindings are only retained under a release environment, so this uses one.
  const releaseConfig = { ...config, environment: 'testflight' };
  const local = store();
  const adapter = createRealAdapter({ config: releaseConfig, store: local, transport: fixtureTransport([]) });
  const bindings = createTrustedBindingStorage({ store: local, config: releaseConfig });
  await bindings.save({ state: 'bound', tenant: { id: releaseConfig.tenantSlug, name: 'Demo Temple' }, error: null, source: 'qr' });

  await adapter.signIn({ email: user.email, password: 'test-password' });
  await adapter.logout();

  const remembered = await bindings.load();
  assert.equal(remembered?.tenant?.id, releaseConfig.tenantSlug,
    'the temple must survive sign-out');
  assert.equal(await local.getItem(sessionKey(storageScope({ environment: releaseConfig.environment, tenantId: releaseConfig.tenantSlug }))), null,
    'the session itself must still be cleared');
});

// Criterion 6. Signing in with no temple loaded must work, and must not reach
// for anything temple-scoped on the way -- the server refuses those, and every
// sign-in path used to call bootstrap unconditionally.
test('a patron with no temple signs in, and nothing temple-scoped is attempted', async () => {
  const releaseConfig = { mode: 'real', apiBaseUrl: 'http://local.test', environment: 'testflight' };
  const calls = [];
  const adapter = createRealAdapter({ config: releaseConfig, store: store(), transport: fixtureTransport(calls) });

  await adapter.signIn({ email: user.email, password: 'test-password' });

  assert.equal(calls.some(call => call.url.includes('/bootstrap')), false,
    'bootstrap is temple-scoped and must not be attempted without one');
  assert.equal(calls.every(call => !call.url.includes('temple_slug=')), true);
  assert.deepEqual(calls.map(call => call.url.replace(/^.*\/native/, '').replace(/\?.*$/, '')), ['/login']);
});

// restoreSession matters on its own: it wiped the stored session before
// rethrowing, so a temple-less patron who relaunched was silently signed out.
test('relaunching with no temple keeps the session instead of discarding it', async () => {
  const releaseConfig = { mode: 'real', apiBaseUrl: 'http://local.test', environment: 'testflight' };
  const local = store();
  const first = createRealAdapter({ config: releaseConfig, store: local, transport: fixtureTransport([]) });
  await first.signIn({ email: user.email, password: 'test-password' });
  const storedBefore = local.values.size;
  assert.ok(storedBefore > 0, 'the session must be on disk for this test to mean anything');

  const calls = [];
  const relaunched = createRealAdapter({ config: releaseConfig, store: local, transport: fixtureTransport(calls) });
  const restored = await relaunched.restoreSession();

  assert.ok(restored, 'a restored session with no temple is still a session');
  assert.equal(calls.some(call => call.url.includes('/bootstrap')), false);
  assert.equal(local.values.size, storedBefore, 'the stored session must survive');
});

// The tenant is runtime state, read per request from what the scan stored --
// not captured when the adapter was constructed. A patron can unload a temple
// and load another without signing out or restarting, so an adapter built once
// must follow that rather than hold the answer it started with.
test('the adapter sends whichever temple is loaded, and none when there is none', async () => {
  const releaseConfig = { mode: 'real', apiBaseUrl: 'http://local.test', environment: 'testflight' };
  const local = store();
  const calls = [];
  const adapter = createRealAdapter({ config: releaseConfig, store: local, transport: fixtureTransport(calls) });
  const bindings = createTrustedBindingStorage({ store: local, config: releaseConfig });

  // Signed in with no temple loaded: the scanner screen is this state, and the
  // session routes accept a request that names no tenant.
  await adapter.signIn({ email: user.email, password: 'test-password' });
  assert.ok(calls.length > 0);
  assert.equal(calls.every(call => !call.url.includes('temple_slug=')), true,
    'no temple loaded means no temple_slug at all, not an empty one');

  await bindings.save({ state: 'bound', tenant: { id: 'first-temple', name: 'First' }, error: null, source: 'qr' });
  calls.length = 0;
  await adapter.listDependents();
  assert.equal(calls.every(call => call.url.includes('temple_slug=first-temple')), true,
    'the temple the scan stored is the one sent');

  // Unload and load another, on the same adapter instance.
  await bindings.save({ state: 'bound', tenant: { id: 'second-temple', name: 'Second' }, error: null, source: 'qr' });
  calls.length = 0;
  await adapter.listDependents();
  assert.equal(calls.every(call => call.url.includes('temple_slug=second-temple')), true,
    'a different temple takes effect without rebuilding the adapter');
  assert.equal(calls.some(call => call.url.includes('first-temple')), false);
});

// Local development has no scan and no stored binding; its slug still comes
// from configuration, which is the one place a tenant may still be named.
test('local development still takes its tenant from configuration', async () => {
  const calls = [];
  const adapter = createRealAdapter({ config, store: store(), transport: fixtureTransport(calls) });
  await adapter.signIn({ email: user.email, password: 'test-password' });
  assert.equal(calls.every(call => call.url.includes('temple_slug=fixture-temple')), true);
});

test('real transport errors are surfaced and never return fixture data', async () => {
  const adapter = createRealAdapter({ config, store: store(), transport: fixtureTransport([], { '/login': response({ code: 'invalid_credentials' }, 401) }) });
  await assert.rejects(adapter.signIn({ email: user.email, password: 'bad' }), { code: 'invalid_credentials' });
  assert.equal(adapter.snapshot().profile.email, '');
});

test('real OAuth adapter sends only the accepted Rails native start and exchange envelopes', async () => {
  const calls = []; const local = store(); const adapter = createRealAdapter({ config, store: local, transport: fixtureTransport(calls) });
  const started = await adapter.startOAuth({ provider: 'google', pkceChallenge: 'c'.repeat(43), pkceMethod: 'S256' });
  assert.deepEqual(started, { authorization_url: 'https://central.example.test/authorize', redirect_uri: 'templemate://oauth/complete', transaction_token: 'opaque-native-transaction', provider: 'google', expires_in: 300 });
  const exchanged = await adapter.exchangeOAuth({ code: 'return-code', transactionToken: 'opaque-native-transaction', pkceVerifier: 'v'.repeat(64) });
  assert.equal(exchanged.oauth.provider, 'google'); assert.equal(exchanged.snapshot.profile.email, user.email);
  const start = calls.find(call => call.url.includes('/oauth/start?'));
  const exchange = calls.find(call => call.url.includes('/oauth/exchange?'));
  assert.deepEqual(JSON.parse(start.body), { oauth: { provider: 'google', pkce_challenge: 'c'.repeat(43), pkce_method: 'S256' } });
  assert.deepEqual(JSON.parse(exchange.body), { oauth: { code: 'return-code', transaction_token: 'opaque-native-transaction', pkce_verifier: 'v'.repeat(64) }, device: { device_id: 'local-test-client', platform: 'expo' } });
  assert.equal(calls.filter(call => /google|apple|sourcegrid/i.test(call.url)).length, 0);
  assert.ok(local.values.has(sessionKey({ environment: 'test', tenantId: 'fixture-temple' })));
});

test('TestFlight and production OAuth use only the trusted Rails-native origin with the existing scheme and PKCE envelopes', async () => {
  for (const [environment, provider] of [['testflight', 'google'], ['production', 'apple']]) {
    const release = resolveClientConfig({ clientEnvironment: environment, apiBaseUrl: 'https://shengfukung.com.tw', tenantSlug: 'shengfukung-wenfu', easUpdateChannel: environment });
    const calls = [];
    const adapter = createRealAdapter({ config: release, store: store(), transport: fixtureTransport(calls) });
    await adapter.startOAuth({ provider, pkceChallenge: 'c'.repeat(43), pkceMethod: 'S256' });
    await adapter.exchangeOAuth({ code: 'return-code', transactionToken: 'opaque-native-transaction', pkceVerifier: 'v'.repeat(64) });
    const start = calls.find(call => call.url.includes('/oauth/start?'));
    const exchange = calls.find(call => call.url.includes('/oauth/exchange?'));
    assert.equal(release.oauthReturnUrl, 'templemate://oauth/complete');
    assert.equal(start.url, 'https://shengfukung.com.tw/api/v1/account/native/oauth/start?temple_slug=shengfukung-wenfu');
    assert.equal(exchange.url, 'https://shengfukung.com.tw/api/v1/account/native/oauth/exchange?temple_slug=shengfukung-wenfu');
    assert.deepEqual(JSON.parse(start.body), { oauth: { provider, pkce_challenge: 'c'.repeat(43), pkce_method: 'S256' } });
    assert.deepEqual(JSON.parse(exchange.body), { oauth: { code: 'return-code', transaction_token: 'opaque-native-transaction', pkce_verifier: 'v'.repeat(64) }, device: { device_id: 'local-test-client', platform: 'expo' } });
    assert.ok(calls.every(call => new URL(call.url).origin === 'https://shengfukung.com.tw'));
    assert.equal(calls.some(call => /google|apple|central|sourcegrid/i.test(new URL(call.url).hostname)), false);
  }
});

test('real OAuth session cleanup removes an exchange-applied session and every scoped record', async () => {
  const calls = []; const local = store(); const adapter = createRealAdapter({ config, store: local, transport: fixtureTransport(calls) });
  await adapter.exchangeOAuth({ code: 'return-code', transactionToken: 'opaque-native-transaction', pkceVerifier: 'v'.repeat(64) });
  await adapter.oauthStorage.savePending({ provider: 'google' });
  assert.ok(local.values.size > 0);
  await adapter.clearOAuthSession();
  assert.equal(local.values.size, 0);
  assert.equal(adapter.snapshot().profile.email, '');
});

test('malformed or provider-mismatched real exchange envelopes leave no retained session', async () => {
  for (const oauth of [
    { provider: 'apple', profile_required: false },
    { provider: 'google' }
  ]) {
    const calls = []; const local = store();
    const adapter = createRealAdapter({ config, store: local, transport: fixtureTransport(calls, {}, { '/oauth/exchange': response({ user, session, oauth }) }) });
    const controller = createOAuthController({
      adapter,
      expectedReturnUrl: 'templemate://oauth/complete',
      createPkce: async () => ({ verifier: 'v'.repeat(64), challenge: 'c'.repeat(43), method: 'S256' }),
      openBrowser: async () => ({ type: 'success', url: 'templemate://oauth/complete?code=return-code' })
    });
    assert.equal((await controller.begin('google')).phase, 'failed');
    assert.equal(local.values.size, 0);
  }
});

test('real startup restoration loads every accepted collection and registration forms use the Rails identifiers', async () => {
  const calls = []; const local = store();
  const adapter = createRealAdapter({ config, store: local, transport: fixtureTransport(calls) });
  await adapter.signIn({ email: user.email, password: 'test-password' });
  const restored = createRealAdapter({ config, store: local, transport: fixtureTransport(calls) });
  const bootstrap = await restored.restoreSession();
  assert.equal(bootstrap.profile.email, user.email);
  const loaded = await restored.loadCollections();
  assert.deepEqual(loaded.dependents, [{ id: '4', dependentId: '4', name: '家屬', relationship: '家人' }]);
  for (const path of ['/dependents', '/registrations', '/events', '/services', '/galleries', '/certificates']) assert.ok(calls.some(call => call.url.includes(`${path}?`)), path);
  await restored.newRegistration({ offering: 'prayer', accountAction: 'event' });
  await restored.createRegistration({ offering: 'prayer', accountAction: 'event', registration: { quantity: 1, contact_name: '林小安' } });
  await restored.updateRegistration(9, { registration: { contact_name: '新名字' } });
  const create = calls.find(call => call.method === 'POST' && call.url.includes('/registrations?'));
  assert.deepEqual(JSON.parse(create.body), { offering: 'prayer', account_action: 'event', registration: { quantity: 1, contact_name: '林小安' } });
  const update = calls.find(call => call.method === 'PATCH' && call.url.includes('/registrations/9?'));
  assert.deepEqual(JSON.parse(update.body), { registration: { contact_name: '新名字' } });
});

test('every resolution error code rails/app/controllers/api/v1/account/native_oauth_resolutions_controller.rb can render has a specific client message, not the generic fallback', () => {
  // Real gap found live, 2026-08-20, testing an Apple identity with no
  // matching account through "I already have an account": the client
  // didn't crash (nativeError always produces a valid Error either way),
  // but existing_account_proof_failed and six sibling resolution codes had
  // no entry in response.js's messageFor(), so they all silently showed
  // the generic "The request could not be completed." This list is the
  // controller's actual rescue set, kept in one place so a new rescue
  // clause added there without a matching entry here fails loudly.
  const genericFallback = nativeError(0, {}).message;
  const resolutionCodes = ['resolution_invalid', 'resolution_expired', 'resolution_consumed', 'resolution_provider_mismatch', 'account_closed', 'existing_account_proof_failed', 'account_resolution_unavailable', 'oauth_identity_conflict', 'validation_failed'];
  for (const code of resolutionCodes) assert.notEqual(nativeError(422, { code }).message, genericFallback, `${code} must have a specific message, not the generic fallback`);
  // The one the Director specifically asked about: must not imply whether
  // the email exists, matching the backend's own choice not to leak that.
  assert.doesNotMatch(nativeError(422, { code: 'existing_account_proof_failed' }).message, /no account|doesn't exist|not found/i);
});

test('lifecycle_stage drives the patron caption and never discloses the temple billing state', () => {
  const { mapRegistration } = require('../app/real/response');
  const { registrationCaption } = require('../app/account/screen_model');
  const { copy } = require('../app/ui/copy');

  const at = stage => mapRegistration({ id: 1, lifecycle: 'open', lifecycle_stage: stage });

  // The stage reaches the client and read-only is derived from it, not from
  // the coarse fulfillment_status.
  assert.equal(at('awaiting_admin_completion').lifecycleStage, 'awaiting_admin_completion');
  assert.equal(at('awaiting_payment').readOnly, false);
  assert.equal(at('fulfilled').readOnly, true);
  assert.equal(at('cancelled').readOnly, true);

  // An unknown stage is rejected rather than passed through.
  assert.equal(at('something_new').lifecycleStage, null);

  for (const locale of ['zh-TW', 'en']) {
    const t = copy[locale];
    // The whole point: a patron cannot tell a frozen temple from a busy one.
    assert.equal(
      registrationCaption(t, at('blocked_on_billing')),
      registrationCaption(t, at('awaiting_admin_completion')),
      `${locale} must not disclose the billing freeze`
    );
    // A raw server state is never shown.
    assert.equal(registrationCaption(t, mapRegistration({ id: 2, lifecycle: 'open' })), '');
    for (const stage of ['awaiting_admin_completion', 'awaiting_payment', 'awaiting_fulfilment', 'fulfilled', 'cancelled']) {
      assert.ok(registrationCaption(t, at(stage)).length > 0, `${locale}/${stage} needs copy`);
    }
  }
});

test('registrations/new tells the client when a registration already exists', () => {
  const { registrationCaption } = require('../app/account/screen_model');
  const { copy } = require('../app/ui/copy');

  // Both locales must carry the copy the discover screen shows instead of a
  // form the server would reject.
  for (const locale of ['zh-TW', 'en']) {
    assert.ok(copy[locale].alreadyRegistered, `${locale} needs alreadyRegistered`);
    assert.ok(copy[locale].alreadyRegistered.length > 0);
  }

  // The gate is on can_register === false specifically, not on falsiness:
  // a server that omits the field must still render the form.
  const gated = payload => payload.can_register === false;
  assert.equal(gated({ can_register: false }), true);
  assert.equal(gated({ can_register: true }), false);
  assert.equal(gated({}), false, 'an older server without the field must not block registration');
});

test('updateProfile sends every field the endpoint permits, and nothing it does not', async () => {
  const calls = []; const adapter = createRealAdapter({ config, store: store(), transport: fixtureTransport(calls) });
  await adapter.signIn({ email: user.email, password: 'test-password' });
  calls.length = 0;

  await adapter.updateProfile({
    english_name: 'Lin Xiao An', native_name: '林小安',
    phone: '0911-222-333', city: '竹南鎮',
    notes: 'REMOVED FIELD', admin_display_mode: 'dark', id: 99
  });

  const call = calls.find(c => c.method === 'PATCH' && c.url.includes('/profile'));
  const sent = JSON.parse(call.body).profile;

  assert.deepEqual(Object.keys(sent).sort(), ['city', 'english_name', 'native_name', 'phone']);
  assert.equal(sent.native_name, '林小安');
  assert.equal(sent.city, '竹南鎮');
  // notes was removed from the profile; anything else is not ours to send.
  assert.equal('notes' in sent, false);
  assert.equal('admin_display_mode' in sent, false);
  assert.equal('id' in sent, false);
});

test('updateProfile keeps the single-name shorthand working', async () => {
  const calls = []; const adapter = createRealAdapter({ config, store: store(), transport: fixtureTransport(calls) });
  await adapter.signIn({ email: user.email, password: 'test-password' });
  calls.length = 0;
  await adapter.updateProfile({ name: '新名字' });
  const call = calls.find(c => c.method === 'PATCH' && c.url.includes('/profile'));
  assert.deepEqual(JSON.parse(call.body), { profile: { native_name: '新名字' } });
});

test('a validation failure shows the server message, not a generic English one', () => {
  const { nativeError } = require('../app/real/response');
  // Mirrors App.js#errorMessage / firstDetail.
  const firstDetail = reason => {
    const details = reason?.details;
    if (!details || typeof details !== 'object') return null;
    const messages = details.base || Object.values(details).find(v => Array.isArray(v) && v.length);
    return Array.isArray(messages) && typeof messages[0] === 'string' ? messages[0] : null;
  };
  const message = reason => firstDetail(reason) || reason?.message || 'fallback';

  const validation = nativeError(422, { code: 'validation_failed', details: { base: ['姓名或英文姓名至少需填寫一項。'] } });
  assert.equal(message(validation), '姓名或英文姓名至少需填寫一項。');

  // Field-scoped errors work too.
  const fieldScoped = nativeError(422, { code: 'validation_failed', details: { quantity: ['數量無效。'] } });
  assert.equal(message(fieldScoped), '數量無效。');

  // No details -> the code-based message still applies.
  const noDetails = nativeError(401, { code: 'session_invalid' });
  assert.equal(message(noDetails), 'Your session is no longer valid.');
});
