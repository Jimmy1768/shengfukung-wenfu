const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createCameraPermissionController, createCameraSession, permissionState } = require('../app/tenant/camera_session');
const { scanCameraPayload } = require('../app/tenant/scanner');
const { resolveHardwareBack } = require('../app/tenant/back');

// A scan is only a binding when the link comes from the configured origin AND
// the server confirms the temple. The fixture link/origin path went with the
// dummy client.
const config = { apiBaseUrl: 'https://temple.example.test', tenantSlug: 'demo-temple' };
const trustedLink = `${config.apiBaseUrl}/connect/templemate/v1`;
const templeTransport = async () => ({ ok: true, body: { temple: { slug: config.tenantSlug, name: '示範宮廟' } } });
const realScan = payload => scanCameraPayload({ payload, config, transport: templeTransport });

test('active camera Back is consumed and closes only the scanner to home', () => {
  assert.deepEqual(resolveHardwareBack({ screen: 'home', cameraOpen: true }), { handled: true, screen: 'home', cameraOpen: false, albumOpen: false });
  assert.deepEqual(resolveHardwareBack({ screen: 'settings', cameraOpen: false }), { handled: true, screen: 'home', cameraOpen: false, albumOpen: false });
  assert.deepEqual(resolveHardwareBack({ screen: 'home', cameraOpen: false }), { handled: false, screen: 'home', cameraOpen: false, albumOpen: false });
});

// An album is a step inside the gallery, so Back returns to the album list.
// Sending it home instead meant opening a second album took three taps.
test('Back closes an open album and stays on the gallery', () => {
  assert.deepEqual(resolveHardwareBack({ screen: 'gallery', cameraOpen: false, albumOpen: true }), { handled: true, screen: 'gallery', cameraOpen: false, albumOpen: false });
  assert.deepEqual(resolveHardwareBack({ screen: 'gallery', cameraOpen: false, albumOpen: false }), { handled: true, screen: 'home', cameraOpen: false, albumOpen: false },
    'with no album open the gallery behaves like any other screen');
  assert.deepEqual(resolveHardwareBack({ screen: 'gallery', cameraOpen: true, albumOpen: true }), { handled: true, screen: 'home', cameraOpen: false, albumOpen: false },
    'the scanner sits over everything, so it wins');
});

test('camera permission states keep preview closed until a user-initiated granted state', () => {
  assert.equal(permissionState(null), 'loading');
  assert.equal(permissionState({ granted: true }), 'ready');
  assert.equal(permissionState({ granted: false, canAskAgain: true }), 'denied');
  assert.equal(permissionState({ granted: false, canAskAgain: false }), 'blocked');
});

test('camera permission requests never repeat after denial and Retry is the only retry authority', () => {
  const controller = createCameraPermissionController();
  let requests = 0;
  const requestWhenAllowed = permission => {
    if (controller.open(permission)) requests += 1;
  };
  const retry = permission => {
    if (controller.retry(permission)) requests += 1;
  };
  const undetermined = { granted: false, canAskAgain: true, status: 'undetermined' };
  const denied = { granted: false, canAskAgain: true, status: 'denied' };
  const blocked = { granted: false, canAskAgain: false, status: 'denied' };

  requestWhenAllowed(undetermined);
  assert.equal(requests, 1);
  requestWhenAllowed(denied);
  assert.equal(requests, 1, 'a permission update after denial must not re-request');
  retry(denied);
  assert.equal(requests, 2, 'one explicit Retry makes exactly one request');
  requestWhenAllowed(denied);
  retry(blocked);
  assert.equal(requests, 2, 'blocked permission never requests');

  controller.close();
  requestWhenAllowed(undetermined);
  assert.equal(requests, 3, 'a new explicit scanner session may make one initial request');
  requestWhenAllowed(denied);
  assert.equal(requests, 3, 'the reopened session still cannot loop after denial');
});

test('camera session accepts only the first QR callback and can be cancelled or retried', async () => {
  let calls = 0;
  const session = createCameraSession({ scanPayload: async payload => {
    calls += 1;
    return realScan(payload);
  } });
  assert.equal(session.snapshot().state, 'closed');
  assert.equal(session.open({ granted: true }).state, 'ready');
  const first = session.receive(trustedLink);
  const duplicate = session.receive('https://untrusted.example.test/connect/templemate/v1');
  assert.equal((await duplicate).state, 'validating');
  assert.equal((await first).state, 'success');
  assert.equal(calls, 1);
  assert.equal(session.close().state, 'closed');
  assert.equal(session.open({ granted: true }).state, 'ready');
});

test('invalid or untrusted camera payload never becomes a binding', async () => {
  const session = createCameraSession({ scanPayload: realScan });
  session.open({ granted: true });
  const result = await session.receive('https://untrusted.example.test/connect/templemate/v1');
  assert.equal(result.state, 'invalid');
  assert.equal(result.result.state, 'binding_failed');
  assert.equal(result.result.error, 'invalid_connection_link',
    'a link from another origin is rejected before the server is asked');
});

test('camera surface is a rear-only QR preview with no audio or real binding path', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'app', 'tenant', 'camera_surface.js'), 'utf8');
  assert.match(source, /CameraView/);
  assert.match(source, /useCameraPermissions/);
  assert.match(source, /facing="back"/);
  assert.match(source, /barcodeTypes: \['qr'\]/);
  assert.doesNotMatch(source, /recordAudio|audio|microphone|fetch|real/iu);
});
