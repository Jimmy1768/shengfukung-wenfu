const DEFAULT_BASE_URL = 'http://localhost:3002';
const DEFAULT_SLUG =
  import.meta.env.VITE_TEMPLE_SLUG || 'shenfukung-wenfu';

function resolveBaseUrl(value) {
  const input =
    value ||
    import.meta.env.VITE_API_BASE_URL ||
    DEFAULT_BASE_URL;
  return input.replace(/\/$/, '');
}

function resolveSlug(value) {
  return value || DEFAULT_SLUG;
}

function buildConfig(overrides = {}) {
  return {
    baseUrl: resolveBaseUrl(overrides.baseUrl),
    slug: resolveSlug(overrides.slug)
  };
}

async function request(path, overrides = {}) {
  const { baseUrl } = buildConfig(overrides);
  const url = `${baseUrl}/api/v1/${path.replace(/^\/+/, '')}`;
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Temple API request failed (${response.status})`);
  }
  return response.json();
}

async function requestJson(path, options = {}, overrides = {}) {
  const { baseUrl } = buildConfig(overrides);
  const url = `${baseUrl}/api/v1/${path.replace(/^\/+/, '')}`;
  const response = await fetch(url, {
    method: options.method || 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {})
    },
    body: options.body ? JSON.stringify(options.body) : undefined
  });

  let payload = null;
  try {
    payload = await response.json();
  } catch (_error) {
    payload = null;
  }

  if (!response.ok) {
    const message = payload?.error || `Temple API request failed (${response.status})`;
    const error = new Error(message);
    error.status = response.status;
    error.payload = payload;
    throw error;
  }

  return payload;
}

export function fetchTempleProfile(overrides = {}) {
  const { slug } = buildConfig(overrides);
  return request(`temples/${slug}`, overrides);
}

export function fetchTempleNews(options = {}) {
  const { slug } = buildConfig(options);
  const limit = Number(options.limit || 10);
  const safeLimit = Number.isFinite(limit) ? limit : 10;
  return request(`temples/${slug}/news?limit=${safeLimit}`, options);
}

export function fetchTempleArchive(overrides = {}) {
  const { slug } = buildConfig(overrides);
  return request(`temples/${slug}/archive`, overrides);
}

export function fetchTempleEvents(options = {}) {
  const { slug } = buildConfig(options);
  const limit = Number(options.limit || 20);
  const safeLimit = Number.isFinite(limit) ? limit : 20;
  const status = options.status || 'upcoming';
  const query = new URLSearchParams({
    limit: String(safeLimit),
    status
  });
  return request(`temples/${slug}/events?${query.toString()}`, options);
}

export function fetchTempleGatherings(options = {}) {
  const { slug } = buildConfig(options);
  return request(`temples/${slug}/gatherings`, options);
}

export function fetchTempleEvent(eventSlug, overrides = {}) {
  const { slug } = buildConfig(overrides);
  const safeSlug = encodeURIComponent(eventSlug);
  return request(`temples/${slug}/events/${safeSlug}`, overrides);
}

export function fetchTempleServices(options = {}) {
  const { slug } = buildConfig(options);
  const limit = Number(options.limit || 50);
  const safeLimit = Number.isFinite(limit) ? limit : 50;
  const query = new URLSearchParams({
    limit: String(safeLimit)
  });
  return request(`temples/${slug}/services?${query.toString()}`, options);
}

export function fetchTempleService(serviceSlug, overrides = {}) {
  const { slug } = buildConfig(overrides);
  const safeSlug = encodeURIComponent(serviceSlug);
  return request(`temples/${slug}/services/${safeSlug}`, overrides);
}

export function submitTempleContactRequest(payload, overrides = {}) {
  const { slug } = buildConfig(overrides);
  return requestJson(`temples/${slug}/contact_temple_requests`, {
    method: 'POST',
    body: payload
  }, overrides);
}
