const test = require('node:test');
const assert = require('node:assert/strict');
const versioning = require('../versioning');
const eas = require('../eas.json');
const project = require('../app/lib/app_constants/project');

const configFor = buildMode => {
  const previous = process.env.BUILD_MODE;
  process.env.BUILD_MODE = buildMode;
  try {
    return require('../app.config.js')().expo;
  } finally {
    if (previous === undefined) delete process.env.BUILD_MODE;
    else process.env.BUILD_MODE = previous;
  }
};

test('bare process env (no BUILD_MODE/EAS_BUILD_PROFILE set) resolves to production identity, never dev', () => {
  // Real incident, 2026-08-20: `eas submit` resolves the project's
  // bundle identifier by evaluating app.config.js in a bare process
  // with neither var set, regardless of which --profile was passed on
  // its own command line -- this used to default that ambiguous case to
  // development, silently pointing App Store Connect credential lookup
  // at com.jimmy1768.komainu.dev for a TestFlight submission. Must fail
  // safe toward production instead, mirroring DojoMate-Expo.
  const previousBuildMode = process.env.BUILD_MODE;
  const previousProfile = process.env.EAS_BUILD_PROFILE;
  const previousClientEnv = process.env.TEMPLEMATE_CLIENT_ENVIRONMENT;
  delete process.env.BUILD_MODE;
  delete process.env.EAS_BUILD_PROFILE;
  delete process.env.TEMPLEMATE_CLIENT_ENVIRONMENT;
  try {
    const config = require('../app.config.js')().expo;
    assert.equal(config.name, project.publicName);
    assert.equal(config.ios.bundleIdentifier, project.nativeIdentifiers.production.iosBundleIdentifier);
    assert.equal(config.android.package, project.nativeIdentifiers.production.androidPackage);
  } finally {
    if (previousBuildMode === undefined) delete process.env.BUILD_MODE; else process.env.BUILD_MODE = previousBuildMode;
    if (previousProfile === undefined) delete process.env.EAS_BUILD_PROFILE; else process.env.EAS_BUILD_PROFILE = previousProfile;
    if (previousClientEnv === undefined) delete process.env.TEMPLEMATE_CLIENT_ENVIRONMENT; else process.env.TEMPLEMATE_CLIENT_ENVIRONMENT = previousClientEnv;
  }
});

test('development config uses TempleMate identity and preserves local version authority', () => {
  const config = configFor('development');
  assert.equal(project.name, 'komainu');
  assert.equal(config.name, project.developmentPublicName);
  assert.equal(config.owner, 'jimmy1768');
  assert.equal(config.extra.eas.projectId, 'c7b8523a-2fad-4123-bc96-0c0c85a23dec');
  assert.equal(config.version, '1.0.0');
  assert.equal(versioning.iosBuildNumber, '2');
  assert.equal(versioning.androidVersionCode, 1);
  assert.equal(config.android.compileSdkVersion, 36);
  assert.equal(config.android.targetSdkVersion, 36);
  assert.deepEqual(config.ios.bundleIdentifier, project.nativeIdentifiers.development.iosBundleIdentifier);
  assert.deepEqual(config.android.package, project.nativeIdentifiers.development.androidPackage);
  assert.equal(eas.build.development.developmentClient, true);
  assert.equal(eas.build.development.android.buildType, 'apk');
  assert.equal(JSON.stringify(eas).includes('autoIncrement'), false);
});

test('production config uses the public TempleMate native identifiers', () => {
  const config = configFor('production');
  assert.equal(config.name, project.publicName);
  assert.equal(config.owner, 'jimmy1768');
  assert.equal(config.extra.eas.projectId, 'c7b8523a-2fad-4123-bc96-0c0c85a23dec');
  assert.equal(config.ios.bundleIdentifier, project.nativeIdentifiers.production.iosBundleIdentifier);
  assert.equal(config.android.package, project.nativeIdentifiers.production.androidPackage);
});

test('TestFlight and production source profiles are real, public, and isolated from development', () => {
  for (const profile of ['testflight', 'production']) {
    const config = configFor(profile);
    assert.equal(config.extra.clientMode, 'real');
    assert.equal(config.extra.apiBaseUrl, 'https://shengfukung.com.tw');
    // One build serves every temple. A slug here is what pinned a release to a
    // single tenant, so its absence is the thing worth asserting -- and the
    // local-development passthrough must not leak into a release lane either.
    assert.equal(config.extra.tenantSlug, '', 'a release lane carries no tenant');
    assert.equal(JSON.stringify(config.extra).includes('shengfukung-wenfu'), false);
    assert.equal(config.extra.easUpdateChannel, profile);
    assert.equal(config.updates.url, 'https://u.expo.dev/c7b8523a-2fad-4123-bc96-0c0c85a23dec');
    // Real incident, 2026-08-20: this assertion used to check
    // config.updates.runtimeVersion (nested, wrong) equal to a policy
    // object -- which meant it happily locked in the exact bug that shipped
    // a TestFlight build with no runtime version embedded at all. Pinned
    // to DojoMate-Expo's proven top-level literal-string form instead.
    assert.equal(config.runtimeVersion, versioning.appVersion);
    assert.equal(config.updates.runtimeVersion, undefined);
    assert.equal(eas.build[profile].channel, profile);
    assert.equal(eas.build[profile].distribution, 'store');
  }
  assert.equal(eas.build.development.channel, undefined);
});

// scripts/verify-release-interface.js also asserts this, but nothing runs that
// file -- no npm script requires it, no test loads it, and nothing else in the
// repository references it. Asserting it here puts the guard inside `npm test`,
// where it will actually fail if a tenant slug returns to a release lane.
test('no release lane carries a tenant slug in its build environment', () => {
  for (const lane of ['testflight', 'production']) {
    const env = eas.build[lane].env;
    assert.equal(env.TEMPLEMATE_PUBLIC_API_ORIGIN, 'https://shengfukung.com.tw', 'the API origin stays pinned');
    assert.equal(env.TEMPLEMATE_PUBLIC_TENANT_SLUG, undefined, `${lane} must not name a tenant`);
  }
  assert.equal(JSON.stringify(eas).includes('shengfukung-wenfu'), false, 'one build serves every temple');
});

test('both public configs declare QR-only camera access without Android audio recording', () => {
  for (const buildMode of ['development', 'production']) {
    const config = configFor(buildMode);
    const camera = config.plugins.find(plugin => Array.isArray(plugin) && plugin[0] === 'expo-camera');
    assert.deepEqual(camera, ['expo-camera', {
      cameraPermission: 'TempleMate uses your camera only to scan a temple QR code.',
      recordAudioAndroid: false
    }]);
  }
});

test('project native identifiers contain only the komainu production and development pair', () => {
  assert.deepEqual(project.nativeIdentifiers, {
    production: {
      iosBundleIdentifier: 'com.jimmy1768.komainu',
      androidPackage: 'com.jimmy1768.komainu'
    },
    development: {
      iosBundleIdentifier: 'com.jimmy1768.komainu.dev',
      androidPackage: 'com.jimmy1768.komainu.dev'
    }
  });
});
