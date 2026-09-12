const { storageKey, storageScope } = require('../core/storage_scope');
const { isReleaseConfig } = require('../real/config');

// Deliberately not scoped by tenant. This key is what *tells* the app which
// temple it is on, so scoping it by that answer was circular -- it worked only
// while the tenant was compiled in. One device holds one loaded temple at a
// time, so one key per environment is the whole story.
const trustedBindingKey = config => storageKey(storageScope({ environment: config?.environment }), 'trusted-binding');

const normalizedBinding = (binding, config) => {
  if (!isReleaseConfig(config) || binding?.state !== 'bound' || binding?.source !== 'qr') return null;
  const id = String(binding.tenant?.id || '').trim();
  const name = String(binding.tenant?.name || '').trim();
  // No comparison against a configured tenant: there is no longer one to
  // compare against, and that was the mechanism that pinned a build to a single
  // temple. What makes a stored binding trustworthy is that it was produced by
  // a scan the server confirmed (source 'qr'), not that it matches a constant.
  if (!id || !name) return null;
  return { state: 'bound', tenant: { id, name }, error: null, source: 'qr' };
};

function createTrustedBindingStorage({ store, config }) {
  const key = trustedBindingKey(config);
  return {
    async load() {
      if (!isReleaseConfig(config)) return null;
      const raw = await store.getItem(key);
      if (!raw) return null;
      try {
        const binding = normalizedBinding(JSON.parse(raw), config);
        if (binding) return binding;
      } catch (_) {}
      await store.deleteItem(key);
      return null;
    },
    async save(binding) {
      const trusted = normalizedBinding(binding, config);
      if (!trusted) throw new Error('Trusted release binding is required.');
      await store.setItem(key, JSON.stringify(trusted));
      return trusted;
    },
    // The ONLY thing that forgets a temple. Sign-out, session expiry, account
    // closure and the sign-in paths all used to clear it as a side effect;
    // each of those was a bug, and each was found separately.
    clear() { return store.deleteItem(key); }
  };
}

module.exports = { createTrustedBindingStorage, normalizedBinding, trustedBindingKey };
