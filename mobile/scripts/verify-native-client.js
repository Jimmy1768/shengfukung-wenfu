const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const versioning = require(path.join(root, 'versioning.js'));
const pkg = require(path.join(root, 'package.json'));
const eas = require(path.join(root, 'eas.json'));
const project = require(path.join(root, 'app', 'lib', 'app_constants', 'project.js'));
const { nativeOAuthReturnUrl, publicConfigurationMatrix } = require(path.join(root, 'app', 'oauth', 'config.js'));

const configFor = buildMode => {
  const previous = process.env.BUILD_MODE;
  process.env.BUILD_MODE = buildMode;
  try {
    return require(path.join(root, 'app.config.js'))().expo;
  } finally {
    if (previous === undefined) delete process.env.BUILD_MODE;
    else process.env.BUILD_MODE = previous;
  }
};

const sourceFiles = directory => fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
  const entryPath = path.join(directory, entry.name);
  if (entry.isDirectory()) return ['node_modules', 'android', 'ios'].includes(entry.name) ? [] : sourceFiles(entryPath);
  return /\.(?:js|jsx)$/.test(entry.name) ? [entryPath] : [];
});

const rejectedNativeIdentifiers = [
  'tw.com.templemate.dev',
  'com.sourcegridlabs.',
  'com.jimmy1768.tenant',
  'com.jimmy1768.admin'
];
const activeSourcePaths = [path.join(root, 'app.config.js'), path.join(root, 'app')];
const activeSourceHasRejectedIdentifier = activeSourcePaths
  .flatMap(entryPath => fs.statSync(entryPath).isDirectory() ? sourceFiles(entryPath) : [entryPath])
  .some(file => rejectedNativeIdentifiers.some(identifier => fs.readFileSync(file, 'utf8').includes(identifier)));
const otaLane = require(path.join(root, 'scripts', 'verify-ota-lane.js'));
const developmentConfig = configFor('development');
const productionConfig = configFor('production');
const testflightConfig = configFor('testflight');

const fail = (message) => {
  console.error(`native-client verification failed: ${message}`);
  process.exitCode = 1;
};

if (!/^\d+\.\d+\.\d+$/.test(versioning.appVersion)) fail('version must be major.minor.patch');
if (pkg.version !== versioning.appVersion || developmentConfig.version !== versioning.appVersion || productionConfig.version !== versioning.appVersion) fail('package/config version differs from versioning.js');
// iOS build number is pinned to the exact accepted value (bumped
// deliberately per TestFlight upload, per the marketing-version-stays-
// fixed convention in ops/docs/plans/TEMPLEMATE_REFINE.md); Android
// hasn't shipped a build yet, so it still pins to 1.
if (versioning.iosBuildNumber !== '4' || versioning.androidVersionCode !== 1) fail('build values must match the current accepted pin (iOS 4, Android 1)');
if (project.name !== 'komainu') fail('internal project name must be komainu');
if (developmentConfig.owner !== 'jimmy1768' || productionConfig.owner !== 'jimmy1768') fail('development and production public config must use the exact EAS owner');
if (developmentConfig.extra.eas?.projectId !== 'c7b8523a-2fad-4123-bc96-0c0c85a23dec' || productionConfig.extra.eas?.projectId !== 'c7b8523a-2fad-4123-bc96-0c0c85a23dec') fail('development and production public config must use the exact EAS project ID');
if (developmentConfig.name !== project.developmentPublicName) fail('development launcher must be TempleMate (Dev)');
if (developmentConfig.ios.bundleIdentifier !== project.nativeIdentifiers.development.iosBundleIdentifier || developmentConfig.android.package !== project.nativeIdentifiers.development.androidPackage) fail('development config must use the public development identifiers');
if (productionConfig.name !== project.publicName) fail('production launcher must be TempleMate');
if (productionConfig.ios.bundleIdentifier !== project.nativeIdentifiers.production.iosBundleIdentifier || productionConfig.android.package !== project.nativeIdentifiers.production.androidPackage) fail('production config must use the public production identifiers');
if (testflightConfig.name !== project.publicName || testflightConfig.ios.bundleIdentifier !== project.nativeIdentifiers.production.iosBundleIdentifier || testflightConfig.android.package !== project.nativeIdentifiers.production.androidPackage) fail('testflight config must resolve to the same public (non-dev) identity as production -- BUILD_MODE=testflight must not fall through to the development default');
// Real incident, 2026-08-20: runtimeVersion lived one level too deep
// (nested under `updates` instead of a sibling of it), which this suite
// never checked -- the misplacement shipped to a real TestFlight build
// with no runtime version embedded at all, silently unable to ever
// receive an OTA update. Pin to DojoMate-Expo's proven literal-string
// form and assert it directly so this can't regress unnoticed again.
if (developmentConfig.runtimeVersion !== versioning.appVersion || productionConfig.runtimeVersion !== versioning.appVersion || testflightConfig.runtimeVersion !== versioning.appVersion) fail('runtimeVersion must be a top-level literal string equal to versioning.appVersion in every buildMode, not nested under updates or expressed as a policy object');
// Same incident: the OTA publish script itself must inject BUILD_MODE
// explicitly per lane (it cannot trust the calling shell's ambient env),
// and that injected value must stay in lockstep with the matching build
// profile's own BUILD_MODE in eas.json, or the two can silently drift
// apart the same way they did here.
for (const lane of ['testflight', 'production']) if (otaLane.LANE_ENV[lane]?.BUILD_MODE !== eas.build?.[lane]?.env?.BUILD_MODE) fail(`scripts/verify-ota-lane.js LANE_ENV.${lane}.BUILD_MODE must match eas.json build.${lane}.env.BUILD_MODE`);
if (developmentConfig.android.compileSdkVersion !== 36 || developmentConfig.android.targetSdkVersion !== 36 || productionConfig.android.compileSdkVersion !== 36 || productionConfig.android.targetSdkVersion !== 36) fail('Android compile/target SDK must be 36');
if (developmentConfig.extra.nativeOAuthReturnUrl !== nativeOAuthReturnUrl || productionConfig.extra.nativeOAuthReturnUrl !== nativeOAuthReturnUrl || nativeOAuthReturnUrl !== 'templemate://oauth/complete') fail('OAuth return must use the accepted TempleMate scheme');
if (pkg.dependencies['expo-auth-session'] !== '~7.0.11' || pkg.dependencies['expo-web-browser'] !== '~15.0.11' || pkg.dependencies['expo-crypto'] !== '~15.0.9') fail('SDK 54 OAuth package versions differ from the accepted Expo compatibility set');
if (pkg.dependencies['expo-camera'] !== '~17.0.10' || pkg.dependencies['expo-updates'] !== '~29.0.15') fail('SDK 54 QR camera/update package versions differ from the accepted Expo compatibility set');
for (const config of [developmentConfig, productionConfig]) {
  const cameraPlugin = config.plugins?.find(plugin => Array.isArray(plugin) && plugin[0] === 'expo-camera');
  if (!cameraPlugin || cameraPlugin[1]?.recordAudioAndroid !== false || !/TempleMate.*camera.*QR/i.test(cameraPlugin[1]?.cameraPermission || '')) fail('QR camera config must declare a TempleMate purpose and disable Android audio recording');
}
if (!publicConfigurationMatrix.development || !publicConfigurationMatrix.production || JSON.stringify(publicConfigurationMatrix).match(/secret|client[_-]?id|token/i)) fail('OAuth configuration matrix must remain public and nonsecret');
if (!eas.build?.development?.developmentClient || eas.build.development.android?.buildType !== 'apk') fail('development APK profile is missing');
for (const lane of ['testflight', 'production']) if (eas.build?.[lane]?.channel !== lane) fail(`${lane} release profile is invalid`);
if (JSON.stringify(eas).match(/autoIncrement/i)) fail('auto-increment configuration is forbidden');
if (!fs.existsSync(path.join(root, 'assets', 'dev-icon.png')) || !fs.existsSync(path.join(root, 'assets', 'dev-adaptive-icon.png'))) fail('development artwork is missing');
if (activeSourceHasRejectedIdentifier) fail('rejected tenant, admin, country, or SourceGrid identifier remains in active mobile source');
if (process.exitCode) process.exit(process.exitCode);
console.log('native-client verification passed: TempleMate production/development identities, 1.0.0, SDK 36, build values, and OAuth public configuration preserved.');
