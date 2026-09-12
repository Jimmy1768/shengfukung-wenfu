const test = require('node:test');
const assert = require('node:assert/strict');
const { activePresentationTenant, initialBinding, parseProductionConnectionLink } = require('../app/tenant/binding');
const { storageKey, storageScope } = require('../app/core/storage_scope');
const { scanCameraPayload } = require('../app/tenant/scanner');
const { createTrustedBindingStorage, trustedBindingKey } = require('../app/tenant/storage');
const { PLATFORM_CONNECT_ORIGIN } = require('../app/real/config');

const apiOrigin = 'https://shengfukung.com.tw';
// No tenantSlug. A release build is compiled without one; the slug arrives in
// the scanned code and is confirmed by the server.
const config = { mode: 'real', environment: 'testflight', apiBaseUrl: apiOrigin };
const linkFor = slug => `${PLATFORM_CONNECT_ORIGIN}/templemate/connect/${slug}`;
const templeTransport = (slug, name) => async () => ({ ok: true, status: 200, body: { temple: { slug, name } } });

test('a connection link is accepted only in its exact production form', () => {
  const accepted = parseProductionConnectionLink(linkFor('shengfukung-wenfu'));
  assert.equal(accepted.ok, true);
  assert.equal(accepted.slug, 'shengfukung-wenfu');

  // The slug is read from the code rather than assumed, which is what lets one
  // build serve a temple it was never told about.
  assert.equal(parseProductionConnectionLink(linkFor('second-temple')).slug, 'second-temple');

  assert.equal(parseProductionConnectionLink(`${linkFor('x')}?v=1`).ok, false, 'no query is legitimate now');
  assert.equal(parseProductionConnectionLink(`${PLATFORM_CONNECT_ORIGIN}/templemate/connect/`).ok, false, 'a code must name a temple');
  assert.equal(parseProductionConnectionLink(`${PLATFORM_CONNECT_ORIGIN}/templemate/connect/a/b`).ok, false, 'exactly one segment');
  assert.equal(parseProductionConnectionLink(`${linkFor('x')}#frag`).ok, false);
  assert.equal(parseProductionConnectionLink(`http://sourcegridlabs.com/templemate/connect/x`).ok, false, 'https only');
  assert.equal(parseProductionConnectionLink('https://other.example.test/templemate/connect/x').ok, false);

  // The trust anchor is the platform's host, not a tenant's -- a code served
  // from a temple's own domain is refused, which is what stops one client's
  // site from pointing the app anywhere.
  assert.equal(parseProductionConnectionLink(`${apiOrigin}/templemate/connect/x`).ok, false);
  // The previous format, so a stale code is refused rather than half-parsed.
  assert.equal(parseProductionConnectionLink(`${apiOrigin}/connect/templemate/v1`).ok, false);
});

test('binding state is unbound until a scan produces one', () => {
  assert.equal(initialBinding().state, 'unbound');
  assert.equal(activePresentationTenant(initialBinding()), null);
  assert.deepEqual(activePresentationTenant({ tenant: { id: 'x', name: 'y' } }), { id: 'x', name: 'y' });

  // Per-temple data stays scoped by the temple it belongs to.
  const scope = storageScope({ environment: 'testflight', tenantId: 'shengfukung-wenfu' });
  assert.equal(storageKey(scope, 'session'), 'templemate.testflight.shengfukung-wenfu.session');
  assert.notEqual(storageKey(scope, 'session'), storageKey(storageScope({ environment: 'development', tenantId: 'shengfukung-wenfu' }), 'session'));

  // The record of WHICH temple is loaded cannot itself be filed under that
  // temple -- that was circular, and only worked while the tenant was compiled
  // in. One device, one loaded temple, one key per environment.
  assert.equal(trustedBindingKey(config), 'templemate.testflight.unbound.trusted-binding');
  assert.notEqual(trustedBindingKey(config), trustedBindingKey({ ...config, environment: 'production' }));
});

test('a scan loads the temple the code names, and only once the server confirms it', async () => {
  assert.deepEqual(
    await scanCameraPayload({ payload: linkFor('shengfukung-wenfu'), config, transport: templeTransport('shengfukung-wenfu', '聖福宮') }),
    { state: 'bound', tenant: { id: 'shengfukung-wenfu', name: '聖福宮' }, error: null, source: 'qr' }
  );

  // The temple the build was never told about. This is the whole change: the
  // same binary loads a different temple because a different code named it.
  assert.deepEqual(
    await scanCameraPayload({ payload: linkFor('second-temple'), config, transport: templeTransport('second-temple', 'Second Temple') }),
    { state: 'bound', tenant: { id: 'second-temple', name: 'Second Temple' }, error: null, source: 'qr' }
  );

  const wrongOrigin = await scanCameraPayload({ payload: 'https://other.example.test/templemate/connect/shengfukung-wenfu', config, transport: templeTransport('shengfukung-wenfu', '聖福宮') });
  assert.equal(wrongOrigin.state, 'binding_failed');
  assert.equal(wrongOrigin.error, 'invalid_connection_link', 'refused before the server is asked');

  // The QR code's claim about which temple it is never wins; the server does.
  const wrongTemple = await scanCameraPayload({ payload: linkFor('shengfukung-wenfu'), config, transport: templeTransport('somewhere-else', 'Other') });
  assert.equal(wrongTemple.state, 'binding_failed');
  assert.equal(wrongTemple.error, 'temple_validation_failed');

  // A slug the server does not recognise. This is the signal that a code can
  // name a temple which does not exist, and it must not load.
  const unknown = await scanCameraPayload({ payload: linkFor('no-such-temple'), config, transport: async () => ({ ok: false, status: 404, body: { code: 'tenant_not_found' } }) });
  assert.equal(unknown.state, 'binding_failed');
  assert.equal(unknown.error, 'temple_validation_failed');

  const unreachable = await scanCameraPayload({ payload: linkFor('shengfukung-wenfu'), config, transport: async () => { throw new Error('offline'); } });
  assert.equal(unreachable.state, 'binding_failed');
});

test('release bindings persist only server-derived trusted data, for whichever temple was loaded', async () => {
  const values = new Map();
  const store = { getItem: async key => values.get(key) || null, setItem: async (key, value) => values.set(key, value), deleteItem: async key => values.delete(key) };
  const bindings = createTrustedBindingStorage({ store, config });
  const binding = { state: 'bound', tenant: { id: 'shengfukung-wenfu', name: '聖福宮' }, error: null, source: 'qr' };

  await bindings.save(binding);
  assert.deepEqual(await bindings.load(), binding);

  const key = trustedBindingKey(config);
  assert.equal(values.get(key).includes('templemate/connect'), false, 'the link itself is never stored');

  // Any confirmed temple round-trips, not one privileged slug. The old rule
  // discarded a binding that did not match the compiled tenant, which is
  // exactly what made a second temple impossible.
  const other = { state: 'bound', tenant: { id: 'second-temple', name: 'Second Temple' }, error: null, source: 'qr' };
  await bindings.save(other);
  assert.deepEqual(await bindings.load(), other, 'loading a different temple replaces the first');

  // Still only a scan, and still only with a server-supplied name.
  await assert.rejects(bindings.save({ ...binding, source: 'link' }), 'only a QR scan may load a temple');
  await assert.rejects(bindings.save({ ...binding, tenant: { id: 'shengfukung-wenfu', name: '' } }), 'a nameless temple is not server-derived');

  values.set(key, JSON.stringify({ ...binding, source: 'link' }));
  assert.equal(await bindings.load(), null, 'untrusted stored data is discarded');
  assert.equal(values.has(key), false);

  // clear() is the only thing that forgets a temple, and it is reached solely
  // from the explicit Unload control in Settings.
  await bindings.save(binding);
  await bindings.clear();
  assert.equal(await bindings.load(), null);
});
