const DEFAULT_TEMPLE_SLUG = import.meta.env.VITE_TEMPLE_SLUG || 'shenfukung-wenfu';

function resolveAccountBaseUrl() {
  const explicit = import.meta.env.VITE_ACCOUNT_BASE_URL || import.meta.env.VITE_API_BASE_URL;
  if (explicit) {
    try {
      return new URL(explicit).origin;
    } catch (error) {
      console.warn('Invalid account base URL', explicit, error);
    }
  }
  if (import.meta.env.DEV) {
    return 'http://localhost:3002';
  }
  if (typeof window !== 'undefined' && window.location?.origin) {
    return window.location.origin;
  }
  return 'http://localhost:3002';
}

function buildAccountUrl(path, params = {}) {
  const base = resolveAccountBaseUrl();
  const url = new URL(path, base);
  const search = new URLSearchParams(params);
  search.forEach((value, key) => {
    url.searchParams.set(key, value);
  });
  return url.toString();
}

export function buildAccountLoginUrl(extraParams = {}) {
  const params = { temple: DEFAULT_TEMPLE_SLUG, ...extraParams };
  return buildAccountUrl('/account/login', params);
}

export function buildRegistrationLink(action, offeringSlug) {
  const params = { account_action: action };
  if (offeringSlug) {
    params.offering = offeringSlug;
  }
  return buildAccountLoginUrl(params);
}
