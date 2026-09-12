// The temple a device has loaded. Everything fixture-shaped that used to live
// here -- fixture tenants, link parsing against example.test origins, the
// switch-temple dance -- went with the dummy client. A real device loads a
// temple by scanning its code, and that is the only way it loads one.
const { PLATFORM_CONNECT_ORIGIN } = require('../real/config');

const productionConnectionPath = '/templemate/connect';

const initialBinding = () => ({ state: 'unbound', tenant: null, error: null });
const activePresentationTenant = binding => binding?.tenant || null;

// The code names a temple; it does not prove one. The slug returned here is an
// input to a backend check, never an authority on its own -- scanner.js asks
// the server, and a slug the server rejects does not load. That division is
// the whole security model: this function decides the payload is well formed
// and comes from the platform, and nothing more.
//
// The origin is the platform's, not the temple's, and not the API's. Each
// client temple has its own Vue domain, so pinning a tenant host would mean a
// rebuild per client; this host is the part that stays still.
//
// Deliberately no query string at all. The previous format carried an optional
// v=1 and the slug lives in the path now (a path segment, so a phone's own
// camera opens a real page), which leaves nothing a query could legitimately
// say -- so anything asking for one is malformed.
const parseProductionConnectionLink = (value, origin = PLATFORM_CONNECT_ORIGIN) => {
  try {
    const url = new URL(value);
    if (url.origin !== origin || url.protocol !== 'https:' || url.username || url.password || url.hash || url.search) return { ok: false, reason: 'invalid_connection_link' };
    const prefix = `${productionConnectionPath}/`;
    if (!url.pathname.startsWith(prefix)) return { ok: false, reason: 'invalid_connection_link' };
    const segment = url.pathname.slice(prefix.length);
    // Exactly one segment. A slug is not format-checked beyond this on purpose:
    // Temple validates only presence, so a client-side pattern would be a
    // second, stricter rule that could refuse a temple the backend accepts.
    // Structure is ours to judge; identity is the server's.
    if (!segment || segment.includes('/')) return { ok: false, reason: 'invalid_connection_link' };
    let slug;
    try { slug = decodeURIComponent(segment).trim(); } catch (_) { return { ok: false, reason: 'invalid_connection_link' }; }
    if (!slug || slug.includes('/') || slug === '.' || slug === '..') return { ok: false, reason: 'invalid_connection_link' };
    return { ok: true, origin: url.origin, slug };
  } catch (_) { return { ok: false, reason: 'invalid_connection_link' }; }
};

module.exports = { productionConnectionPath, initialBinding, activePresentationTenant, parseProductionConnectionLink };
