const path = require('path');

// app/lib/app_constants lives at mobile/app/lib/app_constants, so walk up to repo root
const ROOT = path.resolve(__dirname, '../../../..');
const DEFAULTS = require(path.join(ROOT, 'shared', 'app_constants', 'project.json'));

const coerce = (value, fallback) => {
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }

  return fallback;
};

const slugFromEnv = coerce(process.env.PROJECT_SLUG, DEFAULTS.slug);
const bundlePrefix = coerce(process.env.PROJECT_BUNDLE_PREFIX, DEFAULTS.bundlePrefix);
const fallbackScheme = coerce(process.env.PROJECT_SCHEME, DEFAULTS.scheme) || slugFromEnv.replace(/[^a-z0-9]/gi, '');
const expoSlug = coerce(process.env.EXPO_PROJECT_SLUG, slugFromEnv);
const expoScheme = coerce(process.env.EXPO_PROJECT_SCHEME, fallbackScheme);
const iosBundle = coerce(
  process.env.EXPO_IOS_BUNDLE_IDENTIFIER,
  coerce(process.env.IOS_BUNDLE_IDENTIFIER, `${bundlePrefix}.admin`)
);
const androidPackage = coerce(
  process.env.EXPO_ANDROID_PACKAGE,
  coerce(process.env.ANDROID_PACKAGE, `${bundlePrefix}.admin`)
);

const project = {
  name: coerce(process.env.PROJECT_NAME, DEFAULTS.name),
  slug: slugFromEnv,
  expoSlug,
  scheme: expoScheme,
  easProjectId: coerce(process.env.EAS_PROJECT_ID, DEFAULTS.easProjectId),
  iosBundleIdentifier: iosBundle,
  androidPackage
};

module.exports = project;
module.exports.project = project;
module.exports.default = project;
