<script setup>
import { computed, ref, watch } from 'vue';
import { RouterLink } from 'vue-router';
import LocaleSelector from '../components/LocaleSelector.vue';
import ThemeSelector from '../components/ThemeSelector.vue';
import translations from '../locales/translations';
import { readPersistedLocale, persistLocale } from '../utils/localePersistence';
import { readPersistedTheme, persistTheme } from '../utils/themePersistence';
import { themes } from '../theme/themes';
import { adminUrl } from '../utils/origins';

const localeMetadata = {
  'en-US': { label: 'English (US)', flag: '🇺🇸' },
  'zh-TW': { label: '繁體中文', flag: '🇹🇼' },
  'ja-JP': { label: '日本語', flag: '🇯🇵' },
  'ko-KR': { label: '한국어', flag: '🇰🇷' }
};
const defaultLocale = 'en-US';
const availableLocales = Object.keys(translations);
const localeOptions = availableLocales.map((locale) => ({
  value: locale,
  label: localeMetadata[locale]?.label ?? locale,
  flag: localeMetadata[locale]?.flag ?? ''
}));
const getValidLocale = (value) => (availableLocales.includes(value) ? value : null);
const marketingThemeIds = ['golden-light', 'golden-dark'];
const marketingDefaultThemeId = 'golden-dark';
const themeOptions = marketingThemeIds
  .map((themeId) => themes[themeId])
  .filter((theme) => Boolean(theme))
  .map((theme) => ({
    value: theme.id,
    label: theme.label
  }));
const getValidTheme = (value) =>
  typeof value === 'string' && marketingThemeIds.includes(value) ? value : null;
const storedLocale = getValidLocale(readPersistedLocale());
const selectedLocale = ref(storedLocale ?? defaultLocale);
const storedTheme = getValidTheme(readPersistedTheme());
const selectedTheme = ref(storedTheme ?? marketingDefaultThemeId);
const copy = computed(() => translations[selectedLocale.value]);

const hoveredFeatureKey = ref(null);
const activeFeatureKey = ref(null);
let hoverIntentTimer = null;

const featureKeyFor = (entry) => entry?.id ?? entry?.title ?? entry?.label ?? null;
const pillFeatureKeyFor = (pill) => pill?.featureId ?? pill?.id ?? pill?.label ?? null;

const clearHoverIntent = () => {
  if (hoverIntentTimer) {
    window.clearTimeout(hoverIntentTimer);
    hoverIntentTimer = null;
  }
};

const setHoveredFeature = (value) => {
  hoveredFeatureKey.value = value;
};

const setActiveFeatureWithIntent = (value) => {
  setHoveredFeature(value);
  clearHoverIntent();
  if (!value) return;

  hoverIntentTimer = window.setTimeout(() => {
    activeFeatureKey.value = value;
  }, 500);
};

const clearHoveredFeature = () => {
  setHoveredFeature(null);
  clearHoverIntent();
};

const features = computed(() => copy.value?.features ?? []);

const activeIndex = computed(() => {
  const list = features.value;
  if (!list.length) return 0;

  const key = activeFeatureKey.value;
  const idx = key ? list.findIndex((f) => featureKeyFor(f) === key) : -1;
  return idx >= 0 ? idx : 0;
});

const slotStyle = (i) => {
  const count = features.value.length || 1;
  const slot = (i - activeIndex.value + count) % count;
  return {
    '--slot': String(slot)
  };
};

const previewLink = computed(() => ({
  path: '/marketing/demo',
  query: {
    locale: selectedLocale.value,
    theme: selectedTheme.value
  }
}));
const adminConsoleBase = adminUrl();
const buildAdminLink = (locale, theme) => {
  const params = new URLSearchParams();
  if (locale && locale !== defaultLocale) {
    params.set('locale', locale);
  }
  if (theme && theme !== marketingDefaultThemeId) {
    params.set('theme', theme);
  }
  const queryString = params.toString();
  if (!queryString) {
    return adminConsoleBase;
  }
  const separator = adminConsoleBase.includes('?') ? '&' : '?';
  return `${adminConsoleBase}${separator}${queryString}`;
};
const adminLink = computed(() => buildAdminLink(selectedLocale.value, selectedTheme.value));

const applyTheme = (themeId) => {
  if (typeof document === 'undefined') {
    return;
  }
  document.documentElement.dataset.theme = themeId;
};

watch(selectedLocale, (newLocale) => {
  persistLocale(newLocale);
});

watch(
  selectedTheme,
  (newTheme) => {
    const normalized = getValidTheme(newTheme) ?? marketingDefaultThemeId;
    if (normalized !== newTheme) {
      selectedTheme.value = normalized;
      return;
    }
    persistTheme(normalized);
    applyTheme(normalized);
  },
  { immediate: true }
);
</script>

<template>
  <main class="hero">
    <div class="hero-inner">
      <section class="text-block">
        <p class="eyebrow">{{ copy.branding }}</p>
        <h1>{{ copy.heroTitle }}</h1>
        <p class="hero-subtitle">{{ copy.heroSubtitle }}</p>
        <p class="hero-support">{{ copy.heroSupport }}</p>
        <ul class="pill-list">
          <li
            v-for="pill in copy.heroPills"
            :key="pill.id || pill.label"
            class="pill"
            :class="{ 'is-active': hoveredFeatureKey === pillFeatureKeyFor(pill) }"
            role="button"
            tabindex="0"
            :aria-label="pill.label"
            @mouseenter="setActiveFeatureWithIntent(pillFeatureKeyFor(pill))"
            @mouseleave="clearHoveredFeature"
            @focus="setActiveFeatureWithIntent(pillFeatureKeyFor(pill))"
            @blur="clearHoveredFeature"
          >
            <span class="pill-icon" aria-hidden="true">{{ pill.icon }}</span>
            <span class="sr-only">{{ pill.label }}</span>
          </li>
        </ul>
        <div class="selector-row">
          <LocaleSelector
            v-model="selectedLocale"
            :locales="localeOptions"
            :label="copy.localeLabel"
            :helper="copy.localeHelp"
          />
          <ThemeSelector
            v-model="selectedTheme"
            :options="themeOptions"
            :label="copy.themeLabel"
            :helper="copy.themeHelp"
          />
        </div>
        <div class="cta-row">
          <RouterLink class="cta primary" :to="previewLink">
            {{ copy.ctas.preview }}
          </RouterLink>
          <a class="cta secondary" :href="adminLink">
            {{ copy.ctas.admin }}
          </a>
        </div>
      </section>
      <section class="offer-section surface-card">
        <header class="offer-header">
          <p class="offer-eyebrow">{{ copy.offerEyebrow }}</p>
          <h2>{{ copy.offerTitle }}</h2>
          <p class="offer-intro">{{ copy.offerIntro }}</p>
        </header>
        <div class="offer-grid">
          <article
            v-for="(feature, i) in copy.features"
            :key="feature.id || feature.title"
            class="offer-card"
            :class="{ 'is-linked': hoveredFeatureKey === featureKeyFor(feature) }"
            :style="slotStyle(i)"
            @mouseenter="setHoveredFeature(featureKeyFor(feature))"
            @mouseleave="setHoveredFeature(null)"
            @focusin="setHoveredFeature(featureKeyFor(feature))"
            @focusout="setHoveredFeature(null)"
          >
            <div class="offer-title-row">
              <span class="offer-icon">{{ feature.icon }}</span>
              <h3>{{ feature.title }}</h3>
            </div>
            <p>{{ feature.body }}</p>
          </article>
        </div>
      </section>
    </div>
  </main>
</template>

<style scoped>
.hero {
  min-height: 100vh;
  padding: 5vw clamp(1rem, 4vw, 3rem);
  background: radial-gradient(circle at top left, var(--accent), var(--surface-muted) 55%, var(--surface));
  color: var(--text);
  transition: background 200ms ease, color 200ms ease;
  position: relative;
}

.hero::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    radial-gradient(circle at 75% 10%, color-mix(in srgb, var(--surface-raised) 18%, transparent), transparent 55%),
    radial-gradient(circle at 10% 85%, color-mix(in srgb, var(--surface-raised) 14%, transparent), transparent 60%);
  opacity: 0.9;
}

.hero-inner {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 1120px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: minmax(320px, 1fr) minmax(320px, 0.95fr);
  gap: clamp(1.5rem, 3vw, 3rem);
  align-items: start;
}

.text-block {
  max-width: 720px;
  display: flex;
  flex-direction: column;
  gap: 0.65rem;
}

.eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.4rem;
  font-size: 0.75rem;
  margin-bottom: 0.75rem;
  color: var(--text-muted);
}

h1 {
  font-size: clamp(2.75rem, 5vw, 4.5rem);
  margin-bottom: 1rem;
  color: var(--text);
}

.hero-subtitle,
.hero-support {
  line-height: 1.6;
  margin-bottom: 0.75rem;
  color: var(--text);
}

.hero-support {
  font-size: 1rem;
  color: var(--text-muted);
  max-width: 52ch;
}

.pill-list {
  list-style: none;
  padding: 0;
  margin: 0 0 1.5rem 0;

  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 0.75rem;
  max-width: 520px;
}

.pill {
  display: inline-flex;
  align-items: center;
  padding: 0.35rem 0.5rem;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--surface-raised) 85%, transparent);
  box-shadow: var(--shadow-soft);
  font-weight: 600;
  transition: transform 180ms ease, box-shadow 180ms ease;
  justify-content: center;
  min-height: 44px;
  min-width: 0;
  overflow: hidden;
}

.pill:hover {
  transform: translateY(-2px);
}

.pill.is-active {
  transform: translateY(-2px);
  box-shadow: var(--shadow-soft);
}

.pill-icon {
  font-size: 1rem;
  display: inline-block;
  transform: scaleX(0.82);
  transform-origin: center;
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

.selector-row {
  margin: 0.75rem 0 1rem;
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: flex-start;
}

.selector-row :deep(.locale-selector),
.selector-row :deep(.theme-selector) {
  width: clamp(140px, 70%, 280px);
}

.selector-row :deep(select) {
  width: 100%;
  min-width: 0;
}

.cta-row {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.cta {
  border-radius: 999px;
  padding: 0.85rem 1.75rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease, opacity 0.2s ease;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 1px solid transparent;
}

.cta.primary {
  background: var(--primary);
  color: var(--primary-foreground);
  box-shadow: var(--shadow-soft);
}

.cta.secondary {
  background: transparent;
  border-color: var(--border);
  color: var(--text);
  backdrop-filter: blur(6px);
}

.cta:hover {
  transform: translateY(-2px);
  opacity: 0.9;
  box-shadow: var(--shadow-soft);
}

.offer-section {
  width: 100%;
  padding: clamp(1.5rem, 3vw, 2.5rem);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border);
  background: var(--surface-raised);
  box-shadow: var(--shadow-soft);
  position: sticky;
  top: clamp(1rem, 2vw, 2rem);
}

.offer-header {
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  margin-bottom: 1.5rem;
}

.offer-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  font-size: 0.75rem;
  color: var(--text-muted);
}

.offer-intro {
  margin: 0;
  color: var(--text-muted);
}

.offer-grid {
  position: relative;
  height: 560px;
  overflow: hidden;
  display: block;
}

.offer-grid::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    linear-gradient(
      to bottom,
      var(--surface-raised) 0%,
      transparent 14%,
      transparent 86%,
      var(--surface-raised) 100%
    );
}

.offer-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.03);
  transition: transform 200ms ease, box-shadow 200ms ease, border-color 200ms ease;

  position: absolute;
  left: 0;
  right: 0;
  top: 0;

  --cardStep: 148px;
  transform: translateY(calc(var(--slot) * var(--cardStep)));
  z-index: calc(10 - var(--slot));

  opacity: calc(1 - (var(--slot) * 0.08));
}

.offer-card:hover {
  transform: translateY(calc(var(--slot) * var(--cardStep))) translateY(-4px);
  box-shadow: var(--shadow-soft);
}

.offer-card:focus-within {
  transform: translateY(calc(var(--slot) * var(--cardStep))) translateY(-4px);
  box-shadow: var(--shadow-soft);
}

.offer-card.is-linked {
  /* More pronounced focus: slightly larger + more padding, and ensure it layers above others */
  padding: 1.45rem;
  z-index: 30;
  transform: translateY(calc(var(--slot) * var(--cardStep))) translateY(-6px) scale(1.045);
  box-shadow: var(--shadow-soft);
}

.offer-icon {
  transition: transform 200ms ease;
  font-size: 1.25rem;
}

.offer-title-row {
  display: flex;
  align-items: center;
  gap: 0.6rem;
}

.offer-title-row .offer-icon {
  font-size: 1.2rem;
  line-height: 1;
}

.offer-title-row h3 {
  margin: 0;
}

.offer-card h3 {
  margin: 0;
  font-size: 1.15rem;
}

.offer-card p {
  margin: 0;
  color: var(--text-muted);

  /* Default: 2-line clamp with ellipsis (keeps carousel spacing consistent across locales) */
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
  overflow: hidden;
}

.offer-card.is-linked p {
  /* Expand: show full text when this card is the active/linked target */
  display: block;
  -webkit-line-clamp: unset;
  overflow: visible;
}

@keyframes fadeUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.text-block,
.offer-section {
  animation: fadeUp 420ms ease-out both;
}

.offer-section {
  animation-delay: 80ms;
}

@media (prefers-reduced-motion: reduce) {
  .text-block,
  .offer-section,
  .pill,
  .cta,
  .offer-card {
    animation: none;
    transition: none;
  }
}

@media (max-width: 980px) {
  .hero-inner {
    grid-template-columns: 1fr;
  }

  .offer-section {
    position: static;
  }

  .pill-list {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    max-width: 520px;
  }

  .offer-grid {
    height: auto;
    overflow: visible;
    display: grid;
    gap: 0.85rem;
  }

  .offer-grid::after {
    display: none;
  }

  .offer-card {
    position: static;
    left: auto;
    right: auto;
    top: auto;
    transform: none;
    opacity: 1;
    z-index: auto;
  }

  .offer-card:hover,
  .offer-card:focus-within,
  .offer-card.is-linked {
    transform: translateY(-2px);
  }

  .offer-card.is-linked {
    padding: 1.25rem;
  }

  .offer-card p {
    display: block;
    -webkit-line-clamp: unset;
    overflow: visible;
  }
}

@media (max-width: 420px) {
  .pill-list {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
