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
// slug is a temple at all.
const scanCameraPayload = async ({ payload, config, transport }) => {
  const parsed = parseProductionConnectionLink(payload);
  if (!parsed.ok) return refused(parsed.reason);
  try {
    const response = await transport({
      method: 'GET',
      url: `${config.apiBaseUrl}${verificationPath}?temple_slug=${encodeURIComponent(parsed.slug)}`,
      headers: { Accept: 'application/json' }
    });
    const code = response?.body?.code;
    // The temple is resolved before the request is authenticated, so the answer
    // to "is this slug a temple?" arrives whether or not a token was sent:
    // tenant_not_found when it is not, session_invalid when it is and the call
    // simply carried no credentials. Those are the only two outcomes that mean
    // anything here, so anything else -- a 500, an unparseable body, an
    // unexpected code -- is refused rather than read as confirmation.
    if (response?.status === 404 || code === 'tenant_not_found') return refused('temple_validation_failed');

    const temple = response?.body?.temple;
    const id = String(temple?.slug || '').trim();
    const name = String(temple?.name || '').trim();

    if (response?.ok) {
      // An authenticated caller gets the temple itself. The answer must be
      // about the temple that was asked for; a server describing a different
      // one is refused rather than followed, which is the failure the old
      // code could not see when it trusted the origin to describe itself.
      if (!id || id !== parsed.slug) return refused('temple_validation_failed');
      return { state: 'bound', tenant: { id, name }, error: null, source: 'qr' };
    }

    // Confirmed, unauthenticated. There is no temple name in this answer and
    // none is needed: a temple that has not loaded yet has nothing to display,
    // and the app shows its own name until one does.
    if (response?.status === 401 || code === 'session_invalid') {
      return { state: 'bound', tenant: { id: parsed.slug, name: '' }, error: null, source: 'qr' };
    }
    return refused('temple_validation_failed');
  } catch (_) { return refused('temple_validation_failed'); }
};

module.exports = { scanCameraPayload, verificationPath };
