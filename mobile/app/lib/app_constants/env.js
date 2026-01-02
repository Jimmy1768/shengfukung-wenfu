const path = require('path');

// Walk up from mobile/app/lib/app_constants to repo root
const ROOT = path.resolve(__dirname, '../../../..');
const ENVIRONMENTS_PATH = path.join(ROOT, 'shared', 'app_constants', 'env.json');

let ENVIRONMENTS = {};
try {
  // eslint-disable-next-line global-require, import/no-dynamic-require
  ENVIRONMENTS = require(ENVIRONMENTS_PATH);
} catch {
  ENVIRONMENTS = {};
}

const coerce = (value, fallback = '') => {
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }
  return fallback;
};

const knownEnvs = Object.keys(ENVIRONMENTS);
const defaultEnv = knownEnvs.includes('production')
  ? 'production'
  : knownEnvs[0] || 'production';

const resolveEnvironmentKey = (explicit) => {
  const cascaded = coerce(
    explicit,
    coerce(process.env.APP_ENV, coerce(process.env.BUILD_MODE, process.env.NODE_ENV))
  ).toLowerCase();
  if (cascaded && knownEnvs.includes(cascaded)) {
    return cascaded;
  }
  return defaultEnv;
};

const resolveApiBaseUrl = (envKey) => {
  const envOverride = coerce(process.env.MOBILE_API_BASE_URL, '');
  if (envOverride) {
    return envOverride.replace(/\/+$/, '');
  }

  const key = resolveEnvironmentKey(envKey);
  const envConfig = ENVIRONMENTS[key] || {};
  const candidate = coerce(envConfig.apiBaseUrl, '');
  if (candidate) {
    return candidate.replace(/\/+$/, '');
  }

  const fallback = knownEnvs
    .map((name) => coerce(ENVIRONMENTS[name]?.apiBaseUrl, ''))
    .find(Boolean);

  return (fallback || 'http://localhost:3000').replace(/\/+$/, '');
};

module.exports = {
  environments: ENVIRONMENTS,
  resolveEnvironmentKey,
  resolveApiBaseUrl
};
