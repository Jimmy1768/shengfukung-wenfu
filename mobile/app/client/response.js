// Real gap found live, 2026-08-20, testing an Apple identity whose email
// doesn't match any existing account through the "I already have an
// account" resolution path: the Rails side already handles this safely
// (existing_account_proof_failed -- deliberately the same generic failure
// for "no such email" and "wrong password", so the client can't be used to
// enumerate which emails have accounts), but this dictionary had no entry
// for it, or for six other resolution-specific codes
// (rails/app/controllers/api/v1/account/native_oauth_resolutions_controller.rb's
// full rescue set) -- all of them silently fell back to the generic
// message below instead of something specific. Not a crash either way
// (nativeError() always produces a valid Error, submitResolution's catch
// always calls showError, the transaction stays in account_resolution so
// the user can retry) -- just a worse message than it should be.
const messageFor = code => ({
  validation_failed: 'Please review the highlighted fields.', invalid_credentials: 'Email or password is incorrect.',
  session_invalid: 'Your session is no longer valid.', session_replayed: 'Your session was replayed and has been cleared.',
  session_revoked: 'Your session has been revoked.', account_closed: 'This account is closed.',
  tenant_not_found: 'The selected temple was not found.', tenant_required: 'A temple is required.',
  not_found: 'The requested record was not found.', registration_intake_frozen: 'Registration is currently unavailable.',
  registration_not_editable: 'This registration can no longer be edited.', invalid_preferences: 'Preferences are invalid.',
  // Deliberately doesn't say "no account with that email" -- matches the
  // backend's own choice not to reveal which emails have accounts.
  existing_account_proof_failed: "That email and password don't match an existing account.",
  resolution_invalid: 'This sign-in link is no longer valid. Please start again.',
  resolution_expired: 'This sign-in link has expired. Please start again.',
  resolution_consumed: 'This sign-in link has already been used. Please start again.',
  resolution_provider_mismatch: 'Something went wrong matching your sign-in method. Please start again.',
  account_resolution_unavailable: "Account linking isn't available right now. Please try again later.",
  oauth_identity_conflict: 'This sign-in method is already linked to a different account.'
}[code] || 'The request could not be completed.');

function nativeError(status, body = {}) {
  const code = body.code || body.error || (status === 401 ? 'session_invalid' : status === 404 ? 'not_found' : 'request_failed');
  const error = new Error(messageFor(code));
  error.code = code;
  error.status = status;
  error.details = body.details || null;
  return error;
}

const nameFor = user => user?.native_name || user?.english_name || user?.email || '';
const mapDependent = item => ({ id: String(item.id), dependentId: item.dependent_id ? String(item.dependent_id) : String(item.id), name: item.native_name || item.english_name || '', relationship: item.relationship_label || '' });
// TempleRegistration#lifecycle_stage. blocked_on_billing means the temple's
// own platform billing is frozen -- never surfaced to the patron as such.
const LIFECYCLE_STAGES = ['awaiting_admin_completion', 'awaiting_payment', 'awaiting_fulfilment', 'blocked_on_billing', 'fulfilled', 'cancelled'];
const READ_ONLY_STAGES = ['fulfilled', 'cancelled'];
const mapRegistration = item => {
  const offering = item.offering || {};
  const lifecycle = item.lifecycle || item.fulfillment_status || item.status || 'pending';
  const stage = LIFECYCLE_STAGES.includes(item.lifecycle_stage) ? item.lifecycle_stage : null;
  return {
    id: String(item.id), offering: { id: offering.id ? String(offering.id) : '', slug: offering.slug || '', title: offering.title || '', account_action: offering.account_action || '', price_cents: offering.price_cents ?? item.unit_price_cents ?? 0, currency: offering.currency || item.currency || '' }, registrantName: item.registrant_name || '', registrantScope: item.registrant_scope || 'self', dependentId: item.dependent_id ? String(item.dependent_id) : null, quantity: item.quantity || 1, totalAmountCents: item.total_amount_cents ?? 0,
    state: lifecycle, lifecycle, lifecycleStage: stage, paymentState: item.payment_state || item.payment_status || null,
    // Prefer the six-state stage when the server sends it. The dummy adapter
    // does not, so the coarse fallback stays for fixtures and for any build
    // talking to an older server.
    readOnly: stage ? READ_ONLY_STAGES.includes(stage) : ['completed', 'fulfilled', 'cancelled'].includes(lifecycle)
  };
};
function snapshotFromBootstrap(payload = {}) {
  const user = payload.user || {};
  return {
    profile: { id: user.id ? String(user.id) : '', email: user.email || '', name: nameFor(user), user },
    dependents: (payload.dependents || []).map(mapDependent),
    registrations: (payload.registrations || []).map(mapRegistration),
    certificates: payload.certificates || [], events: payload.events || [], services: payload.services || [], gatherings: payload.gatherings || [], gallery: payload.galleries || [],
    preferences: payload.preferences || {}, temple: payload.temple || null
  };
}
const collectionFrom = (payload, name) => payload?.[name] || [];
module.exports = { LIFECYCLE_STAGES, READ_ONLY_STAGES, nativeError, snapshotFromBootstrap, mapDependent, mapRegistration, nameFor, collectionFrom };
