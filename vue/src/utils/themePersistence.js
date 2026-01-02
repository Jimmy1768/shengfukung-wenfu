const STORAGE_KEY = 'golden-template-theme';

const isBrowser = typeof window !== 'undefined';

export const readPersistedTheme = () => {
  if (!isBrowser) {
    return null;
  }

  try {
    return window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
};

export const persistTheme = (themeId) => {
  if (!isBrowser) {
    return;
  }

  try {
    if (themeId == null) {
      window.localStorage.removeItem(STORAGE_KEY);
    } else {
      window.localStorage.setItem(STORAGE_KEY, themeId);
    }
  } catch {
    // Ignore storage errors (e.g., private mode)
  }
};
