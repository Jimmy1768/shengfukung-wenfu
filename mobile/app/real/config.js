const { nativeOAuthReturnUrl } = require('../oauth/config');
const RELEASE_ENVIRONMENTS = new Set(['testflight', 'production']);
const PUBLIC_ORIGIN = 'https://shengfukung.com.tw';
// Where a scanned code must come from. Not the API origin: one Rails
// deployment serves every temple, but each client gets its own Vue domain, so
// a tenant's own host cannot be the anchor -- it varies per client while one
// app serves them all. This host is the constant, which is what makes pinning
// it worth anything. scripts/lint-source.js permits a URL literal in this file
// only, so app/tenant/binding.js imports this rather than restating it.
const PLATFORM_CONNECT_ORIGIN = 'https://sourcegridlabs.com';
const safeUrl = value => { try { return new URL(String(value)); } catch (_) { return null; } };

function resolveClientConfig(extra = {}) {
  const environment = String(extra.clientEnvironment || 'development').toLowerCase();
  const release = RELEASE_ENVIRONMENTS.has(environment);
  // One mode. The dummy client is gone; every build talks to a real server,
  // a local one in development and the public origin in a release lane.
  const mode = 'real';
  const apiBaseUrl = String(extra.apiBaseUrl || extra.localApiBaseUrl || '').replace(/\/$/, '');
  // Local development only. A release build carries no tenant at all: which
  // temple an install is on is decided by a scan at runtime, so requiring one
  // here would make every release build fail before it could show a scanner.
  const tenantSlug = String(extra.tenantSlug || extra.localTenantSlug || '').trim();
  if (mode === 'real' && !apiBaseUrl) {
    const error = new Error('Real mode requires an explicit API origin.');
    error.code = 'REAL_CONFIG_REQUIRED';
    throw error;
  }
  if (mode === 'real') {
    const url = safeUrl(apiBaseUrl);
    const host = url?.hostname?.toLowerCase();
    const localHost = host === 'localhost' || host === '127.0.0.1' || host === '::1' || host?.endsWith('.test');
    // Origin only. The tenant used to be half of this test, which is precisely
    // what pinned a release build to one temple; the origin is the security
    // property and it is unchanged.
    const publicExact = url?.origin === PUBLIC_ORIGIN;
    if (!url || !['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.hash || url.pathname !== '/' || url.search || !(publicExact || (!release && localHost))) {
      const error = new Error('Real mode requires an exact trusted API origin.');
      error.code = 'TRUSTED_API_REQUIRED';
      throw error;
    }
  }
  const oauthReturnUrl = String(extra.nativeOAuthReturnUrl || nativeOAuthReturnUrl);
  if (oauthReturnUrl !== nativeOAuthReturnUrl) {
    const error = new Error('Native OAuth return URL must use the configured templemate scheme.');
    error.code = 'NATIVE_OAUTH_RETURN_REQUIRED';
    throw error;
  }
  return { mode, apiBaseUrl, tenantSlug, environment, oauthReturnUrl, updateChannel: String(extra.easUpdateChannel || environment) };
}

const localTenantBinding = config => ({ state: 'bound', tenant: { id: config.tenantSlug, name: config.tenantSlug }, error: null, source: 'local-test' });

module.exports = { PUBLIC_ORIGIN, PLATFORM_CONNECT_ORIGIN, RELEASE_ENVIRONMENTS, resolveClientConfig, localTenantBinding };
