import { defaultThemeId } from '../../../theme/tokens';

const isPresent = (value) => typeof value === 'string' && value.trim().length > 0;

export const MOBILE_ALLOWED_THEME_IDS = Object.freeze(['temple-1', 'temple-2']);

export function isAllowedMobileThemeId(themeId) {
  return isPresent(themeId) && MOBILE_ALLOWED_THEME_IDS.includes(themeId.trim());
}

export function resolveMobileTheme({ userPreference, projectDefault, hardcodedFallback = defaultThemeId } = {}) {
  const candidates = [
    { value: userPreference, source: 'user_preference' },
    { value: projectDefault, source: 'project_default' },
    { value: hardcodedFallback, source: 'hardcoded_fallback' }
  ];

  for (const candidate of candidates) {
    if (isAllowedMobileThemeId(candidate.value)) {
      return { themeId: candidate.value.trim(), source: candidate.source };
    }
  }

  return { themeId: 'temple-1', source: 'hardcoded_fallback' };
}

