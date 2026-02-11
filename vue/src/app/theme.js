import { defaultThemeId, themes } from '@/theme/themes.js';
import project from '@/app/project.js';

const THEME_COOKIE = 'temple_theme';
const COOKIE_MAX_AGE = 60 * 60 * 24 * 7; // 1 week
const API_BASE =
  import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') || 'http://localhost:3001';

const BUILD_THEME_KEY =
  import.meta.env.VITE_TEMPLE_THEME ||
  project.defaultThemeKey ||
  defaultThemeId;

let activeThemeKey = BUILD_THEME_KEY;

export function initTheme() {
  const stored = import.meta.env.DEV ? readThemeCookie() : null;
  const resolved = themes[stored] ? stored : BUILD_THEME_KEY;
  applyTheme(resolved);
}

export function getActiveThemeKey() {
  return activeThemeKey;
}

export function setThemeKey(themeKey) {
  const resolved = themes[themeKey] ? themeKey : BUILD_THEME_KEY;
  applyTheme(resolved);
  if (import.meta.env.DEV) {
    writeThemeCookie(resolved);
  }
}

export function availableThemes() {
  return Object.values(themes);
}

function applyTheme(themeKey) {
  activeThemeKey = themeKey;
  if (typeof document !== 'undefined') {
    document.documentElement.dataset.theme = themeKey;
  }
}

function readThemeCookie() {
  if (typeof document === 'undefined') return null;
  const match = document.cookie.match(/(?:^|; )temple_theme=([^;]+)/);
  return match ? decodeURIComponent(match[1]) : null;
}

function writeThemeCookie(value) {
  if (typeof document === 'undefined') return;
  document.cookie = `${THEME_COOKIE}=${encodeURIComponent(
    value
  )};path=/;max-age=${COOKIE_MAX_AGE}`;
}

async function persistThemeSelection(themeKey) {
  try {
    await fetch(`${API_BASE}/dev/theme`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ theme_key: themeKey })
    });
  } catch (error) {
    console.warn('Theme persistence failed', error);
  }
}
