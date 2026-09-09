const ACCOUNT_SCREENS = Object.freeze([
  'home', 'profile', 'dependents', 'registrations', 'discover', 'gallery', 'settings',
  'signup', 'recovery', 'assistance', 'privacy', 'closure', 'connection'
]);

// Gallery is its own destination. It used to be rendered at the bottom of
// Explore, so one screen held every offering a patron could register for and
// the temple's photo albums -- two unrelated things, with the albums reachable
// only by scrolling past the whole catalogue.
const accountMenu = () => ['home', 'profile', 'dependents', 'registrations', 'discover', 'gallery'];
const isAccountScreen = screen => ACCOUNT_SCREENS.includes(screen);
const isPaidFixtureReadOnly = registration => Boolean(registration?.readOnly);
const visibleTheme = dark => dark ? 'dark' : 'light';
const visibleLocale = locale => ['zh-TW', 'en'].includes(locale) ? locale : 'zh-TW';
const safeAccountScreen = screen => isAccountScreen(screen) ? screen : 'home';
const isBoundPresentation = binding => binding?.state === 'bound' || binding?.state === 'switching';
const safeBoundScreen = (screen, binding) => isBoundPresentation(binding) ? safeAccountScreen(screen) : 'home';
// TempleRegistration#lifecycle_stage -> copy key. blocked_on_billing is
// deliberately mapped to the same string as awaiting_admin_completion: the
// temple's billing state is never disclosed to the patron, exactly as the web
// does it (account.registrations.payment.online_payments_frozen reuses the
// awaiting_admin_completion wording).
const STAGE_COPY_KEYS = Object.freeze({
  awaiting_admin_completion: 'stageAwaitingAdminCompletion',
  blocked_on_billing: 'stageBlockedOnBilling',
  awaiting_payment: 'stageAwaitingPayment',
  awaiting_fulfilment: 'stageAwaitingFulfilment',
  fulfilled: 'stageFulfilled',
  cancelled: 'stageCancelled'
});

// Never returns a raw server state: an unmapped stage falls through to the
// existing draft/read-only captions and then to empty, so the patron can
// never be shown a bare "open".
const registrationCaption = (t, item) => {
  const key = STAGE_COPY_KEYS[item?.lifecycleStage];
  if (key && t?.[key]) return t[key];
  if (item?.readOnly) return t?.paidReadOnly || '';
  if (item?.state === 'draft') return t?.draft || '';
  return '';
};

const mutationOutcome = async ({ action, onSuccess }) => {
  try { const value = await action(); if (onSuccess) onSuccess(value); return { ok: true, value }; }
  catch (error) { return { ok: false, error }; }
};

module.exports = { ACCOUNT_SCREENS, STAGE_COPY_KEYS, registrationCaption, accountMenu, isAccountScreen, isPaidFixtureReadOnly, visibleTheme, visibleLocale, safeAccountScreen, safeBoundScreen, isBoundPresentation, mutationOutcome };
