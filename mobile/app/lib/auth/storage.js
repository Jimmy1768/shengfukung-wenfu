import * as SecureStore from 'expo-secure-store';

const ACCESS_TOKEN_KEY = 'golden-template.admin.access';
const REFRESH_TOKEN_KEY = 'golden-template.admin.refresh';

const memoryStore = {};

const setItem = async (key, value) => {
  if (!value) {
    await deleteItem(key);
    return;
  }

  try {
    await SecureStore.setItemAsync(key, value);
  } catch (error) {
    memoryStore[key] = value;
  }
};

const getItem = async (key) => {
  try {
    const stored = await SecureStore.getItemAsync(key);
    if (stored !== null && stored !== undefined) {
      return stored;
    }
  } catch (error) {
    // Fall through to memory store.
  }

  return memoryStore[key] ?? null;
};

const deleteItem = async (key) => {
  try {
    await SecureStore.deleteItemAsync(key);
  } catch (error) {
    delete memoryStore[key];
  }
};

export async function persistTokens({ accessToken, refreshToken }) {
  await Promise.all([
    setItem(ACCESS_TOKEN_KEY, accessToken),
    setItem(REFRESH_TOKEN_KEY, refreshToken)
  ]);
}

export async function loadTokens() {
  const [accessToken, refreshToken] = await Promise.all([
    getItem(ACCESS_TOKEN_KEY),
    getItem(REFRESH_TOKEN_KEY)
  ]);

  return { accessToken, refreshToken };
}

export async function clearTokens() {
  await Promise.all([deleteItem(ACCESS_TOKEN_KEY), deleteItem(REFRESH_TOKEN_KEY)]);
}
