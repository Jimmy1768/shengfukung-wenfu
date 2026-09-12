const { parseProductionConnectionLink } = require('./binding');

// Where the slug is checked. Any native route resolves the temple before it
// authenticates, so this answers about the temple the slug names rather than
// about whichever temple the origin happens to be -- which is the bug the old
// path had: it asked the configured origin who *it* was and compared that to a
// compiled-in constant, so a code for any other temple could not succeed.
const verificationPath = '/api/v1/account/native/bootstrap';

const refused = error => ({ state: 'binding_failed', tenant: null, error, source: 'qr' });

// One path. The code must come from the platform origin, and the temple it
// names must be confirmed by the server before anything loads. The code's own
// claim never wins: it supplies a slug, and the server decides whether that
// slug is a temple and what it is called.
const scanCameraPayload = async ({ payload, config, transport }) => {
  const parsed = parseProductionConnectionLink(payload);
  if (!parsed.ok) return refused(parsed.reason);
  try {
    const response = await transport({
      method: 'GET',
      url: `${config.apiBaseUrl}${verificationPath}?temple_slug=${encodeURIComponent(parsed.slug)}`,
      headers: { Accept: 'application/json' }
    });
    // A slug the server does not recognise is refused outright, and this is the
    // only signal that decides it. tenant_not_found is returned before any
    // authentication runs, so it is reachable whatever the session state.
    if (response?.status === 404 || response?.body?.code === 'tenant_not_found') return refused('temple_validation_failed');
    const temple = response?.body?.temple;
    const id = String(temple?.slug || '').trim();
    const name = String(temple?.name || '').trim();
    // The answer must be about the temple that was asked for. A server replying
    // with a different temple is refused rather than followed -- that mismatch
    // is precisely what went unnoticed when the client trusted the origin to
    // describe itself.
    if (!response?.ok || !id || !name || id !== parsed.slug) return refused('temple_validation_failed');
    return { state: 'bound', tenant: { id, name }, error: null, source: 'qr' };
  } catch (_) { return refused('temple_validation_failed'); }
};

module.exports = { scanCameraPayload, verificationPath };
