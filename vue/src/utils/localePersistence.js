const STORAGE_KEY = 'golden-template-locale';

const isBrowser = typeof window !== 'undefined';

const readPersistedLocale = () => {
  if (!isBrowser) {
    return null;
  }

  try {
    return window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
};

const persistLocale = (locale) => {
  if (!isBrowser) {
    return;
  }

  try {
    if (locale == null) {
      window.localStorage.removeItem(STORAGE_KEY);
    } else {
      window.localStorage.setItem(STORAGE_KEY, locale);
    }
  } catch {
    // Ignore storage errors (e.g., private mode)
  }
};

export { STORAGE_KEY, readPersistedLocale, persistLocale };
