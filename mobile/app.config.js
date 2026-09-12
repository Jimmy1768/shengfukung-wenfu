const versioning = require('./versioning');
const project = require('./app/lib/app_constants/project');
const { nativeOAuthReturnUrl } = require('./app/oauth/config');

// Fails safe toward production, mirroring DojoMate-Expo's proven
// `isDev = BUILD === 'development'` (strict equality against an unset
// variable is false). Real incident, 2026-08-20: this used to default
// the *unset* case to 'development' -- correct for `eas build`/`eas
// update`, which always set BUILD_MODE explicitly, but `eas submit`
// resolves the project's bundle identifier in a bare process with
// neither BUILD_MODE nor EAS_BUILD_PROFILE set, regardless of which
// --profile was passed on the command line. That silently pointed
// credential lookup at the dev bundle ID (com.jimmy1768.komainu.dev)
// for a `--profile testflight` submit. Same class of bug as the OTA
// publish script needing BUILD_MODE injected explicitly -- this fixes
// it at the root instead of patching each new call site that turns out
// not to set it.
const isDevelopmentClient = () => {
  const raw = process.env.BUILD_MODE || process.env.EAS_BUILD_PROFILE;
  if (!raw) return false;
  return ['development', 'dev', 'debug'].includes(String(raw).toLowerCase());
};

const releaseConfiguration = buildMode => {
  const environment = String(process.env.TEMPLEMATE_CLIENT_ENVIRONMENT || buildMode).toLowerCase();
  if (!['testflight', 'production'].includes(environment)) return null;
  return {
    clientMode: 'real',
    apiBaseUrl: 'https://shengfukung.com.tw',
    clientEnvironment: environment,
    easUpdateChannel: environment
  };
};

module.exports = () => {
  const development = isDevelopmentClient();
  // Same fail-safe direction as isDevelopmentClient: an ambiguous/unset
  // context should resolve to "unknown, not release" here (releaseConfiguration
  // returns null for anything outside testflight/production), never to a
  // specific asserted buildMode string it wasn't actually told.
  const buildMode = String(process.env.BUILD_MODE || process.env.EAS_BUILD_PROFILE || '').toLowerCase();
  const release = releaseConfiguration(buildMode);
  const nativeIdentifiers = project.nativeIdentifiers[development ? 'development' : 'production'];

  return {
    expo: {
      name: development ? project.developmentPublicName : project.publicName,
      slug: 'templemate',
      owner: 'jimmy1768',
      version: versioning.appVersion,
      scheme: 'templemate',
      orientation: 'portrait',
      icon: development ? './assets/dev-icon.png' : './assets/icon.png',
      userInterfaceStyle: 'automatic',
      newArchEnabled: true,
      splash: {
        image: './assets/splash-icon.png',
        resizeMode: 'contain',
        backgroundColor: '#ffffff'
      },
      ios: {
        supportsTablet: true,
        bundleIdentifier: nativeIdentifiers.iosBundleIdentifier,
        buildNumber: versioning.iosBuildNumber,
        // TempleMate only uses the standard HTTPS/TLS encryption iOS provides
        // to talk to the Rails backend -- no proprietary/custom crypto. This
        // answers App Store Connect's export-compliance question at upload
        // time instead of prompting for it on every build.
        infoPlist: {
          ITSAppUsesNonExemptEncryption: false
        }
      },
      android: {
        package: nativeIdentifiers.androidPackage,
        versionCode: versioning.androidVersionCode,
        compileSdkVersion: 36,
        targetSdkVersion: 36,
        adaptiveIcon: {
          foregroundImage: development ? './assets/dev-adaptive-icon.png' : './assets/adaptive-icon.png',
          backgroundColor: '#ffffff'
        },
        edgeToEdgeEnabled: true
      },
      plugins: [
        'expo-secure-store',
        'expo-dev-client',
        ['expo-camera', {
          cameraPermission: 'TempleMate uses your camera only to scan a temple QR code.',
          recordAudioAndroid: false
        }],
        'expo-updates'
      ],
      // Pinned as a literal string, not a { policy: 'appVersion' } object --
      // mirrors DojoMate-Expo's proven config/base.cjs pattern. The object-
      // policy form is schema-valid but was silently dropped by this repo's
      // build pipeline when it lived one level too deep (see git history);
      // pinning the literal value removes that whole class of failure
      // instead of trusting the policy resolves the same way every time.
      runtimeVersion: versioning.appVersion,
      updates: {
        url: 'https://u.expo.dev/c7b8523a-2fad-4123-bc96-0c0c85a23dec',
        enabled: true,
        fallbackToCacheTimeout: 0,
        requestHeaders: release?.easUpdateChannel
          ? { 'expo-channel-name': release.easUpdateChannel }
          : undefined
      },
      extra: {
        eas: {
          projectId: 'c7b8523a-2fad-4123-bc96-0c0c85a23dec'
        },
        clientMode: 'real',
        apiBaseUrl: release?.apiBaseUrl || process.env.TEMPLEMATE_LOCAL_API_BASE_URL || '',
        // Local development only, and deliberately absent from a release lane:
        // a release build is compiled with no temple and loads one from a scan.
        tenantSlug: process.env.TEMPLEMATE_LOCAL_TENANT_SLUG || '',
        clientEnvironment: release?.clientEnvironment || process.env.TEMPLEMATE_CLIENT_ENVIRONMENT || 'development',
        easUpdateChannel: release?.easUpdateChannel || 'development',
        nativeOAuthReturnUrl,
        supportedLocales: ['zh-TW', 'en'],
        supportedThemes: ['light', 'dark'],
        android16TargetSdk: 36
      }
    }
  };
};
