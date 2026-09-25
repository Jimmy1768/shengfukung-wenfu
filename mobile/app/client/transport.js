const typedTransportError = (code, message) => Object.assign(new Error(message), { code });
async function productionTransport(request, { fetchImpl = globalThis.fetch, timeoutMs = 12000 } = {}) {
  if (typeof fetchImpl !== 'function') throw typedTransportError('NETWORK_UNAVAILABLE', 'Network transport is unavailable.');
  const controller = new AbortController(); const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetchImpl(request.url, { method: request.method, headers: { Accept: 'application/json', 'Content-Type': 'application/json', ...request.headers }, body: request.body, signal: controller.signal });
    if (!String(response.headers?.get?.('content-type') || '').toLowerCase().includes('application/json')) return { ok: false, status: response.status, body: { code: 'invalid_response' } };
    let body; try { body = await response.json(); } catch (_) { body = { code: 'invalid_response' }; }
    return { ok: response.ok, status: response.status, body };
  } catch (error) { if (error?.name === 'AbortError') throw typedTransportError('NETWORK_TIMEOUT', 'The server did not respond in time.'); throw typedTransportError('NETWORK_UNAVAILABLE', 'Unable to reach the trusted server.'); } finally { clearTimeout(timer); }
}
const localTestTransport = request => productionTransport(request);
module.exports = { productionTransport, localTestTransport, typedTransportError };
