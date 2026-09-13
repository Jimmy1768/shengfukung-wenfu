const nativeOAuthReturnUrl = 'templemate://oauth/complete';
const publicConfigurationMatrix = Object.freeze({
  development: Object.freeze({ clientMode: 'real; a local server in development, the public origin in a release lane', apiBaseUrl: 'unknown external local/test value', returnUrl: nativeOAuthReturnUrl, providerRegistration: 'unknown/deferred' }),
  production: Object.freeze({ clientMode: 'real requires later explicit distribution configuration', apiBaseUrl: 'unknown external value', returnUrl: nativeOAuthReturnUrl, providerRegistration: 'unknown/deferred' })
});
module.exports = { nativeOAuthReturnUrl, publicConfigurationMatrix };
