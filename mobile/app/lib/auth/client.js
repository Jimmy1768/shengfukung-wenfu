import Constants from 'expo-constants';

const defaultLoginPath = '/api/v1/mobile/sessions';
const defaultRefreshPath = '/api/v1/mobile/sessions/refresh';
const defaultLogoutPath = '/api/v1/mobile/sessions';

const getExtras = () => {
  const expoConfig = Constants?.expoConfig ?? Constants?.manifest ?? {};
  return expoConfig.extra ?? {};
};

const getApiConfig = () => {
  const extra = getExtras();
  return extra.api ?? {};
};

const normalizePath = (path, fallback) => {
  const normalized = typeof path === 'string' && path.trim().length > 0 ? path.trim() : fallback;
  if (!normalized.startsWith('/')) {
    return `/${normalized}`;
  }
  return normalized;
};

const buildUrl = (path, fallback) => {
  const api = getApiConfig();
  const base = (api.baseUrl || '').replace(/\/+$/, '');
  if (!base) {
    throw new Error('Missing MOBILE_API_BASE_URL. Set it in Expo extra config to enable JWT logins.');
  }
  const suffix = normalizePath(path, fallback);
  return `${base}${suffix}`;
};

const parseJson = async (response) => {
  let payload = null;
  try {
    payload = await response.json();
  } catch (_) {
    payload = null;
  }

  if (!response.ok) {
    const message = payload?.error || payload?.message || 'Unable to sign in. Check the credentials and try again.';
    throw new Error(message);
  }

  return payload || {};
};

const extractTokens = (payload) => {
  const accessToken = payload.access_token || payload.accessToken;
  const refreshToken = payload.refresh_token || payload.refreshToken;
  return { accessToken, refreshToken };
};

export async function authenticateWithJwt({ email, password }) {
  if (!email || !password) {
    throw new Error('Email and password are required.');
  }

  const api = getApiConfig();
  const endpoint = buildUrl(api.loginPath, defaultLoginPath);
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ email, password })
  });

  const payload = await parseJson(response);
  const tokens = extractTokens(payload);
  if (!tokens.accessToken || !tokens.refreshToken) {
    throw new Error('Server did not return access + refresh tokens.');
  }

  return {
    ...tokens,
    payload
  };
}

export async function refreshJwtSession(refreshToken) {
  if (!refreshToken) {
    throw new Error('Missing refresh token.');
  }

  const api = getApiConfig();
  const endpoint = buildUrl(api.refreshPath, defaultRefreshPath);
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ refresh_token: refreshToken })
  });

  const payload = await parseJson(response);
  const tokens = extractTokens(payload);
  if (!tokens.accessToken) {
    throw new Error('Refresh response is missing an access token.');
  }

  return {
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken || refreshToken,
    payload
  };
}

export async function revokeJwtSession(refreshToken) {
  if (!refreshToken) {
    return;
  }
  const api = getApiConfig();
  const endpoint = buildUrl(api.logoutPath, defaultLogoutPath);
  await fetch(endpoint, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ refresh_token: refreshToken })
  }).catch(() => {});
}
