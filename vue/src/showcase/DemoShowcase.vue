<!-- Paste/replace the contents of your DemoShowcase.vue with this version. -->
<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { RouterLink, useRoute, useRouter } from 'vue-router';
import { defaultBrandId, brands } from '../sourcegrid/brands';
import { pricingContent } from '../sourcegrid/pricing';
import { defaultTemplateId, templateRegistry } from '../sourcegrid/templates/registry';
import translations from '../locales/translations';
import { persistLocale, readPersistedLocale } from '../utils/localePersistence';
import { persistTheme, readPersistedTheme } from '../utils/themePersistence';
import { defaultThemeId, themes } from '../theme/themes';
import brandCopyCatalog from '../sourcegrid/copy';
import { adminUrl } from '../utils/origins';
import ContactDrawer from '../components/ContactDrawer.vue';
import { collectContactMetadata, formatContactMetadata } from '../utils/contactMetadata';
import applyBrandCopy from '../sourcegrid/templates/utils/applyBrandCopy';

const templates = templateRegistry;
const initialBrand = brands.find((brand) => brand.id === defaultBrandId) ?? brands[0];
const selectedBrandId = ref(initialBrand.id);
const selectedTemplateId = ref(initialBrand.recommendedTemplate || defaultTemplateId);
const activePage = ref('home');
const route = useRoute();
const router = useRouter();

const availableLocales = Object.keys(translations);
const defaultLocale = 'zh-TW';
const adminDefaultLocale = 'zh-TW';
const adminLocaleMap = {
  'en-US': 'en',
  'zh-TW': 'zh-TW',
  'ja-JP': 'ja',
  'ko-KR': 'ko'
};
const mapLocaleForAdmin = (localeCode) => adminLocaleMap[localeCode] ?? adminDefaultLocale;
const templateThemeLocks = {
  'bistro-noir': 'golden-dark'
};
const adminConsoleBase = adminUrl();
const localeFallback = translations[defaultLocale];

const extractQueryValue = (value) => (Array.isArray(value) ? value[0] : value);
const normalizeLocale = (locale) => (availableLocales.includes(locale) ? locale : defaultLocale);
const getValidLocale = (value) =>
  typeof value === 'string' && availableLocales.includes(value) ? value : null;
const normalizeTheme = (theme) => (typeof theme === 'string' && themes[theme] ? theme : null);

const storedLocale = getValidLocale(readPersistedLocale());
const routeLocaleCandidate = extractQueryValue(route.query.locale);
const initialLocale = getValidLocale(routeLocaleCandidate) ?? storedLocale ?? defaultLocale;
const selectedLocale = ref(initialLocale);
persistLocale(initialLocale);
const storedTheme = normalizeTheme(readPersistedTheme());
const routeThemeCandidate = extractQueryValue(route.query.theme);
const initialTheme = normalizeTheme(routeThemeCandidate) ?? storedTheme ?? defaultThemeId;
const selectedTheme = ref(initialTheme);
persistTheme(initialTheme);

const contactForm = reactive({
  name: '',
  email: '',
  message: ''
});
const formState = ref('idle');
const formMessage = ref('');
const formError = ref('');
const isContactOpen = ref(false);

const copy = computed(() => {
  const localeEntry = translations[selectedLocale.value] ?? localeFallback;
  return localeEntry?.demo ?? localeFallback?.demo;
});

// Localized brand copy is passed THROUGH to templates.
// Templates decide how/if they merge this into layout-driven structures.
const brandCopyDefaultLocale = 'en-US';
const brandCopyByLocale = computed(
  () => brandCopyCatalog[selectedLocale.value] ?? brandCopyCatalog[brandCopyDefaultLocale] ?? {}
);
const localizedBrands = computed(() =>
  brands.map((brand) => applyBrandCopy(brand, brandCopyByLocale.value.brands?.[brand.id]))
);
const selectedBrand = computed(() => {
  const list = localizedBrands.value;
  if (!list.length) {
    const fallbackCopy = brandCopyByLocale.value.brands?.[initialBrand.id];
    return applyBrandCopy(initialBrand, fallbackCopy);
  }
  return list.find((brand) => brand.id === selectedBrandId.value) ?? list[0];
});
const brandCopyForSelected = computed(() => {
  const brandId = selectedBrand.value?.id;
  return brandCopyByLocale.value.brands?.[brandId] ?? {};
});

const navItems = computed(() => copy.value.nav?.items ?? []);

const localizedPricingPackages = computed(() => {
  const packageCopy = copy.value.pricing.packages ?? {};
  return pricingContent.packages.map((pkg) => {
    const localized = packageCopy[pkg.id] ?? {};
    return {
      ...pkg,
      copy: {
        name: localized.name ?? '',
        summary: localized.summary ?? '',
        description: localized.description ?? '',
        features: localized.features ?? []
      }
    };
  });
});

const localizedAddons = computed(() => {
  const addonCopy = copy.value.pricing.addons ?? {};
  return pricingContent.addons.map((addon) => ({
    ...addon,
    displayName: addonCopy[addon.id] ?? addon.id
  }));
});

const localizedMaintenance = computed(() => {
  const maintenanceCopy = copy.value.pricing.maintenance ?? {};
  return pricingContent.maintenance.map((plan) => {
    const localized = maintenanceCopy[plan.id] ?? {};
    return {
      ...plan,
      displayName: localized.name ?? plan.id,
      scope: localized.scope ?? ''
    };
  });
});

const demoSubject = computed(() => copy.value.contact.autoReplySubject);
const demoBodyPreview = computed(() => copy.value.contact.autoReplyBody);
const submitButtonLabel = computed(() =>
  formState.value === 'sending' ? copy.value.contact.sending : copy.value.contact.submit
);

const buildAdminLink = (locale, theme) => {
  const params = new URLSearchParams();
  const adminLocale = mapLocaleForAdmin(locale);
  if (adminLocale && adminLocale !== adminDefaultLocale) {
    params.set('locale', adminLocale);
  }
  if (theme && theme !== defaultThemeId) {
    params.set('theme', theme);
  }
  const queryString = params.toString();
  if (!queryString) {
    return adminConsoleBase;
  }
  const separator = adminConsoleBase.includes('?') ? '&' : '?';
  return `${adminConsoleBase}${separator}${queryString}`;
};
const adminConsoleLink = computed(() => buildAdminLink(selectedLocale.value, selectedTheme.value));

const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL || '').replace(/\/$/, '');
const apiEndpoint = apiBaseUrl
  ? `${apiBaseUrl}/api/v1/demo_contacts`
  : '/api/v1/demo_contacts';

const selectedTemplate = computed(
  () => templates.find((tpl) => tpl.id === selectedTemplateId.value) ?? templates[0]
);

const lockedTemplateTheme = computed(
  () => templateThemeLocks[selectedTemplateId.value] ?? null
);

const brandSignatureList = computed(() => {
  // IMPORTANT: raw brand highlight titles (templates can localize/override if desired)
  const highlights = selectedBrand.value.highlights?.map((item) => item.title) ?? [];
  if (!highlights.length) return selectedBrand.value.name;
  if (highlights.length === 1) return highlights[0];
  if (highlights.length === 2) return `${highlights[0]} & ${highlights[1]}`;
  const rest = highlights.slice(0, -1).join(', ');
  const last = highlights[highlights.length - 1];
  return `${rest}, & ${last}`;
});

const heroBackgroundStyle = computed(() => {
  const image = selectedBrand.value.assets?.gradientBackdrop;
  return image
    ? {
        backgroundImage: `linear-gradient(135deg, rgba(2,6,23,0.92), rgba(0,0,0,0.65)), url(${image})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center'
      }
    : {
        background: 'linear-gradient(135deg, rgba(2,6,23,0.92), rgba(0,0,0,0.65))'
      };
});

const setPage = (pageId) => {
  const item = navItems.value.find((nav) => nav.id === pageId);
  if (item?.disabled) return;
  activePage.value = pageId === 'custom' ? 'custom' : pageId;
};

const resetContactState = () => {
  formState.value = 'idle';
  formMessage.value = '';
  formError.value = '';
};

const openContact = () => {
  resetContactState();
  isContactOpen.value = true;
};

const closeContact = () => {
  isContactOpen.value = false;
};

const handleLocaleChange = (locale) => {
  selectedLocale.value = locale;
};
const shouldOpenContactFromQuery = (value) => {
  if (typeof value !== 'string') return false;
  const normalized = value.trim().toLowerCase();
  return ['1', 'true', 'open', 'contact'].includes(normalized);
};

const clearContactQuery = () => {
  const nextQuery = { ...route.query };
  if (nextQuery.contact) {
    delete nextQuery.contact;
    router.replace({ path: route.path, query: nextQuery });
  }
};

const handleContactSubmit = async (event) => {
  event?.preventDefault();
  formMessage.value = '';
  formError.value = '';
  formState.value = 'sending';
  const metadata = collectContactMetadata({
    locale: selectedLocale.value,
    theme: selectedTheme.value,
    brandId: selectedBrand.value?.id,
    templateId: selectedTemplateId.value
  });
  const metadataBlock = formatContactMetadata(metadata);
  const payloadMessage = [contactForm.message?.trim(), metadataBlock]
    .filter(Boolean)
    .join('\n\n');
  try {
    const response = await fetch(apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        name: contactForm.name,
        email: contactForm.email,
        message: payloadMessage,
        locale: selectedLocale.value,
        metadata
      })
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new Error(payload.error || 'Request failed');
    }

    formState.value = 'sent';
    formMessage.value = payload.message || 'Message sent.';
    contactForm.name = '';
    contactForm.email = '';
    contactForm.message = '';
  } catch (error) {
    formState.value = 'error';
    formError.value = error.message;
  }
};

const applyTheme = (themeId) => {
  if (typeof document === 'undefined') {
    return;
  }
  document.documentElement.dataset.theme = themeId;
};
applyTheme(initialTheme);

watch(
  () => route.query.locale,
  (newLocaleRaw) => {
    const normalized = normalizeLocale(extractQueryValue(newLocaleRaw));
    if (normalized !== selectedLocale.value) {
      selectedLocale.value = normalized;
    }
  }
);

watch(selectedLocale, (newLocale) => {
  const normalized = normalizeLocale(newLocale);
  persistLocale(normalized);
  const current = normalizeLocale(extractQueryValue(route.query.locale));
  if (normalized === current) return;

  const nextQuery = { ...route.query };
  if (normalized === defaultLocale) {
    delete nextQuery.locale;
  } else {
    nextQuery.locale = normalized;
  }
  router.replace({ path: route.path, query: nextQuery });
});

watch(selectedBrandId, (newId) => {
  const brand = brands.find((entry) => entry.id === newId);
  if (brand) {
    selectedTemplateId.value = brand.recommendedTemplate || defaultTemplateId;
  }
});

watch(
  () => route.query.theme,
  (newThemeRaw) => {
    const normalized = normalizeTheme(extractQueryValue(newThemeRaw)) ?? defaultThemeId;
    if (normalized !== selectedTheme.value) {
      selectedTheme.value = normalized;
    }
  }
);

watch(
  () => route.query.contact,
  (newContactRaw) => {
    const normalized = extractQueryValue(newContactRaw);
    if (shouldOpenContactFromQuery(normalized)) {
      openContact();
      clearContactQuery();
    }
  },
  { immediate: true }
);

watch(
  selectedTheme,
  (newTheme) => {
    const normalized = normalizeTheme(newTheme) ?? defaultThemeId;
    if (normalized !== newTheme) {
      selectedTheme.value = normalized;
      return;
    }
    persistTheme(normalized);
    applyTheme(normalized);
    const current = normalizeTheme(extractQueryValue(route.query.theme)) ?? defaultThemeId;
    if (normalized === current) return;

    const nextQuery = { ...route.query };
    if (normalized === defaultThemeId) {
      delete nextQuery.theme;
    } else {
      nextQuery.theme = normalized;
    }
    router.replace({ path: route.path, query: nextQuery });
  },
  { immediate: true }
);
</script>

<template>
  <div class="demo-page">
    <header class="page-hero" :style="heroBackgroundStyle">
      <p class="eyebrow">{{ copy.hero.eyebrow }}</p>
      <h1>{{ copy.hero.title }}</h1>
      <p>{{ copy.hero.description }}</p>
      <div class="hero-actions">
        <RouterLink class="btn btn-secondary hero-link-home" to="/">
          {{ copy.hero.backToLanding }}
        </RouterLink>
        <RouterLink class="btn btn-primary hero-link-marketing" to="/marketing">
          {{ copy.hero.marketingLanding }}
        </RouterLink>
        <a class="btn btn-ghost" :href="adminConsoleLink">{{ copy.hero.adminLogin }}</a>
      </div>
    </header>

    <section class="selector-panel surface-card">
      <div class="selector-field">
        <label for="brand-select">{{ copy.selector.brandLabel }}</label>
        <select id="brand-select" v-model="selectedBrandId">
          <option v-for="brand in localizedBrands" :key="brand.id" :value="brand.id">
            {{ brand.name }}
          </option>
        </select>
        <p class="selector-note">{{ selectedBrand.tagline }}</p>
      </div>
      <div class="selector-field">
        <label for="template-select">{{ copy.selector.templateLabel }}</label>
        <select id="template-select" v-model="selectedTemplateId">
          <option v-for="template in templates" :key="template.id" :value="template.id">
            {{ template.label }}
          </option>
        </select>
        <p class="selector-note">
          {{ copy.selector.storyFocusPrefix }} {{ brandSignatureList }}
        </p>
      </div>
    </section>

    <component
      :is="selectedTemplate.component"
      :key="`${selectedTemplateId}-${selectedBrandId}`"
      :nav-items="navItems"
      :active-page="activePage"
      :template-id="selectedTemplateId"
      :brand="selectedBrand"
      :brand-copy="brandCopyForSelected"
      :copy="copy"
      :pricing-packages="localizedPricingPackages"
      :addons="localizedAddons"
      :maintenance="localizedMaintenance"
      :available-locales="availableLocales"
      :selected-locale="selectedLocale"
      :contact-form="contactForm"
      :form-state="formState"
      :form-message="formMessage"
      :form-error="formError"
      :locked-theme-id="lockedTemplateTheme"
      :demo-subject="demoSubject"
      :demo-body-preview="demoBodyPreview"
      :submit-button-label="submitButtonLabel"
      @navigate="setPage"
      @contact="openContact"
      @change-locale="handleLocaleChange"
      @submit-contact="handleContactSubmit"
    />

    <ContactDrawer
      :open="isContactOpen"
      :copy="copy.contact"
      :contact-form="contactForm"
      :form-state="formState"
      :form-message="formMessage"
      :form-error="formError"
      :submit-button-label="submitButtonLabel"
      @close="closeContact"
      @submit="handleContactSubmit"
    />
  </div>
</template>

<style scoped>
.hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  align-items: center;
}

.hero-link-marketing {
  margin-left: 0.5rem;
}
.demo-page {
  padding: clamp(1.5rem, 4vw, 3rem);
  display: flex;
  flex-direction: column;
  gap: var(--spacingLg);
}

.page-hero {
  position: relative;
  color: #f8fafc;
  border: 1px solid var(--border);
  border-radius: var(--radiusLg);
  padding: clamp(1.5rem, 5vw, 3rem);
  overflow: hidden;
  box-shadow: var(--shadow-soft);
  backdrop-filter: blur(6px);
}

.page-hero::before {
  content: '';
  position: absolute;
  inset: 0;
  background: inherit;
  filter: blur(12px);
  transform: scale(1.05);
  opacity: 0.4;
}

.page-hero::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(
    135deg,
    rgba(0, 0, 0, 0.6),
    rgba(15, 23, 42, 0.5)
  );
}

.page-hero > * {
  position: relative;
  z-index: 1;
}

.hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--spacingSm);
  margin-top: var(--spacingSm);
}

.hero-actions .btn {
  min-width: 180px;
  justify-content: center;
}

.hero-actions .btn-secondary {
  color: #f8fafc;
  border-color: rgba(255, 255, 255, 0.5);
  background: rgba(248, 250, 252, 0.08);
}

.hero-actions .btn-ghost {
  color: rgba(248, 250, 252, 0.8);
}

.selector-panel {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: clamp(var(--spacingSm), 1vw, var(--spacingSm) * 1.2);
  padding: clamp(1.1rem, 2.4vw, 1.8rem);
  padding-left: clamp(1.25rem, 3vw, 2.25rem);
  align-items: stretch;
  border-radius: calc(var(--radiusLg) * 1.2);
  border: 1px solid var(--border);
  background: var(--surface-raised);
  box-shadow: var(--shadow-soft);
}

.selector-field {
  padding-block: clamp(0.85rem, 1.8vw, 1.4rem);
  padding-inline: clamp(0.9rem, 2.25vw, 1.75rem);
  background: var(--surface-muted);
  border: 1px solid var(--border);
  border-radius: var(--radiusMd);
  display: grid;
  gap: clamp(0.4rem, 0.9vw, 0.65rem);
  color: var(--text);
}

.selector-field label {
  font-size: 0.85rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--text-muted);
}

.selector-field select {
  width: 70%;
  max-width: 70%;
  justify-self: stretch;
  border-radius: var(--radiusSm);
  border: 1px solid var(--border);
  padding: 0.45rem 0.85rem;
  background: var(--surface-raised);
  color: var(--text);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.04);
}

.selector-field select:focus {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

.selector-note {
  margin: 0;
  font-size: 0.85rem;
  color: var(--text-muted);
}

@media (max-width: 640px) {
  .selector-field select {
    width: 100%;
    max-width: 100%;
  }
}
</style>
