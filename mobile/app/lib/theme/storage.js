import * as SecureStore from 'expo-secure-store';

const MOBILE_THEME_PREFERENCE_KEY = 'komainu.theme.preference';
const memoryStore = {};

const setItem = async (key, value) => {
  if (!value) {
    await deleteItem(key);
    return;
  }

  try {
    await SecureStore.setItemAsync(key, value);
  } catch (_error) {
    memoryStore[key] = value;
  }
};

const getItem = async (key) => {
  try {
    const stored = await SecureStore.getItemAsync(key);
    if (stored !== null && stored !== undefined) return stored;
  } catch (_error) {
    // Fall through to memory store.
  }

  return memoryStore[key] ?? null;
};

const deleteItem = async (key) => {
  try {
    await SecureStore.deleteItemAsync(key);
  } catch (_error) {
    delete memoryStore[key];
  }
};

export async function loadThemePreference() {
  return getItem(MOBILE_THEME_PREFERENCE_KEY);
}

export async function persistThemePreference(themeId) {
  await setItem(MOBILE_THEME_PREFERENCE_KEY, themeId);
}

export async function clearThemePreference() {
  await deleteItem(MOBILE_THEME_PREFERENCE_KEY);
}

