const fs = require('fs');
const path = require('path');
const project = require('./app/lib/app_constants/project');
const environments = require('./app/lib/app_constants/env');
const { defaultThemeId } = require('./theme/tokens');
const versioning = require('./versioning');

const CONFIG_PLUGIN_ENV_VAR = 'GOLDEN_TEMPLATE_EXPO_PLUGIN';

const coerce = (value, fallback) => {
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }

  return fallback;
};

const truthyStrings = new Set(['1', 'true', 'yes', 'on']);
const oauthProviderSpecs = [
  {
    key: 'google',
    clientIdEnv: 'OAUTH_GOOGLE_CLIENT_ID',
    clientSecretEnv: 'OAUTH_GOOGLE_CLIENT_SECRET'
  },
  {
    key: 'facebook',
    clientIdEnv: 'OAUTH_FACEBOOK_CLIENT_ID',
    clientSecretEnv: 'OAUTH_FACEBOOK_CLIENT_SECRET'
  },
  {
    key: 'apple',
    clientIdEnv: 'OAUTH_APPLE_CLIENT_ID',
    clientSecretEnv: 'OAUTH_APPLE_CLIENT_SECRET'
  }
];

const resolveBuildMode = () => {
  const cascaded = coerce(
    process.env.BUILD_MODE,
    coerce(process.env.EAS_BUILD_PROFILE, coerce(process.env.APP_ENV, ''))
  );

  if (typeof cascaded === 'string') {
    return cascaded.trim().toLowerCase();
  }

  return '';
};

const devBuildValues = new Set(['development', 'dev', 'debug', 'dropletdev']);
const isDevClientBuild = () => devBuildValues.has(resolveBuildMode());

const trailingJoin = (origin, path) => {
  const base = origin.replace(/\/+$/, '');
  if (!path || path === '/' || path === '') {
    return base || '/';
  }
  if (path.startsWith('?') || path.startsWith('#')) {
    return `${base}${path}`;
  }
  return `${base}/${path.replace(/^\/+/, '')}`;
};

const resolveConfigPluginModule = () => {
  const explicit = coerce(process.env[CONFIG_PLUGIN_ENV_VAR], '');
  if (explicit) {
    return explicit;
  }

  const localPluginDir = path.join(__dirname, 'plugins-local');
  if (fs.existsSync(localPluginDir)) {
    return './plugins-local';
  }

  try {
    require.resolve('@golden-template/expo-config-plugins');
    return '@golden-template/expo-config-plugins';
  } catch {
    return null;
  }
};

const buildConfigPlugins = devClientBuild => {
  const plugins = ['expo-secure-store', 'expo-dev-client'];
  const pluginModule = resolveConfigPluginModule();

  if (pluginModule) {
    const pluginOptions = {
      apnsEnvironment: coerce(process.env.APN_ENV, undefined),
      skipMainOrientationUnlock: truthyStrings.has(
        coerce(process.env.EXPO_SKIP_MAIN_ORIENTATION_UNLOCK, '').toLowerCase()
      ),
      legacyEdgeToEdgeFallback: truthyStrings.has(
        coerce(process.env.EXPO_LEGACY_EDGE_TO_EDGE, '').toLowerCase()
      ),
      androidReleaseOptimizations: !devClientBuild
    };

    plugins.push([
      pluginModule,
      pluginOptions
    ]);
  } else {
    console.warn(
      'Golden Template Expo config plugins are not configured. Set GOLDEN_TEMPLATE_EXPO_PLUGIN to the shared package or keep mobile/plugins-local available.'
    );
  }

  return plugins;
};

const resolveEasProjectId = () => coerce(process.env.EAS_PROJECT_ID, project.easProjectId);
const resolveEnabledOauthProviders = () =>
  oauthProviderSpecs
    .filter(spec => coerce(process.env[spec.clientIdEnv], '') && coerce(process.env[spec.clientSecretEnv], ''))
    .map(spec => spec.key);

module.exports = () => {
  const devClientBuild = isDevClientBuild();
  const marketingFallback = process.env.NODE_ENV === 'production' ? '/marketing' : 'http://localhost:5173/marketing';
  const marketingOrigin = coerce(process.env.PROJECT_MARKETING_ORIGIN, marketingFallback);

  const environmentKey = environments.resolveEnvironmentKey();
  const apiBaseUrl = environments.resolveApiBaseUrl(environmentKey);
  const adminLoginPath = coerce(process.env.MOBILE_JWT_LOGIN_PATH, '/api/v1/mobile/sessions');
  const adminRefreshPath = coerce(process.env.MOBILE_JWT_REFRESH_PATH, '/api/v1/mobile/sessions/refresh');

  const defaultAdminEmail = coerce(
    process.env.PROJECT_DEFAULT_ADMIN_EMAIL,
    `admin@${project.slug}.local`
  );
  const defaultAdminPassword = coerce(process.env.PROJECT_DEFAULT_ADMIN_PASSWORD, 'Password123!');
  const easProjectId = resolveEasProjectId();
  const easExtra = {};
  if (easProjectId) {
    easExtra.projectId = easProjectId;
  }
  const oauthProviders = resolveEnabledOauthProviders();

  return {
    expo: {
      name: devClientBuild ? `${project.name} (Dev)` : project.name,
      slug: project.expoSlug || project.slug,
      version: versioning.appVersion,
      scheme: project.scheme,
      orientation: 'portrait',
      icon: devClientBuild ? './assets/dev-icon.png' : './assets/icon.png',
      userInterfaceStyle: 'automatic',
      newArchEnabled: true,
      splash: {
        image: './assets/splash-icon.png',
        resizeMode: 'contain',
        backgroundColor: '#ffffff'
      },
      ios: {
        supportsTablet: true,
        bundleIdentifier: project.iosBundleIdentifier,
        buildNumber: versioning.iosBuildNumber
      },
      android: {
        adaptiveIcon: {
          foregroundImage: devClientBuild
            ? './assets/dev-adaptive-icon.png'
            : './assets/adaptive-icon.png',
          backgroundColor: '#ffffff'
        },
        edgeToEdgeEnabled: true,
        package: project.androidPackage,
        versionCode: versioning.androidVersionCode
      },
      web: {
        favicon: './assets/favicon.png'
      },
      plugins: buildConfigPlugins(devClientBuild),
      extra: {
        environment: environmentKey,
        eas: easExtra,
        defaultThemeId,
        api: {
          baseUrl: apiBaseUrl,
          loginPath: adminLoginPath,
          refreshPath: adminRefreshPath
        },
        demoCredentials: {
          email: defaultAdminEmail,
          password: defaultAdminPassword
        },
        oauth: {
          providers: oauthProviders,
          available: oauthProviders.length > 0
        },
        marketingLinks: {
          demo: trailingJoin(marketingOrigin, '/demo'),
          home: trailingJoin(marketingOrigin, '/')
        }
      }
    }
  };
};
