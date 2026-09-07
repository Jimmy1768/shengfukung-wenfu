<template>
  <section class="pd-wrapper">
    <section class="pd-overview">
      <p class="pd-eyebrow">{{ deckLabels.enterprise }}</p>
      <h2>{{ pricingHeadline }}</h2>
      <p>{{ pricingSubhead }}</p>
      <p v-if="pricingIntro" class="pd-overview-note">{{ pricingIntro }}</p>
      <p class="pd-currency-note">{{ currencyNote }}</p>
    </section>

    <section v-if="valueHighlights.length" class="pd-highlight-section">
      <button
        v-for="highlight in valueHighlights"
        :key="highlight.id"
        class="pd-highlight-card"
        type="button"
        @click="scrollToDetail(highlight.id)"
      >
        <span>{{ highlight.title }}</span>
        <strong>{{ highlight.body }}</strong>
      </button>
    </section>

    <section class="pd-section">
      <header class="pd-section-header">
        <p class="pd-eyebrow">{{ deckLabels.tierIncluded }}</p>
        <h3>{{ deckLabels.packageHeadline }}</h3>
        <p>{{ deckLabels.packageNote }}</p>
      </header>

      <div class="pd-tier-grid">
        <article
          v-for="tier in packageDetails"
          :key="tier.id"
          class="pd-tier-card"
          :ref="(el) => setDetailRef(el, tier.id)"
        >
          <header class="pd-tier-header">
            <span class="pd-tier-number">{{ tier.icon }}</span>
            <div>
              <p class="pd-tier-label">{{ tier.tierLabel }}</p>
              <h4>{{ tier.title }}</h4>
            </div>
          </header>

          <div class="pd-price-box" :aria-label="deckLabels.pricingArea">
            <div>
              <span>{{ deckLabels.setup }}</span>
              <strong>{{ formatPrice(tier.setupTWD) }}</strong>
            </div>
            <div>
              <span>{{ deckLabels.monthlyMinimum }}</span>
              <strong>{{ formatPrice(tier.monthlyMinimumTWD) }}</strong>
              <em>{{ tier.monthlyMinimumLabel }}</em>
            </div>
          </div>

          <p class="pd-tier-summary">{{ tier.summary }}</p>
          <p class="pd-dependency">{{ tier.dependencyNote }}</p>

          <div class="pd-list-block">
            <p>{{ deckLabels.included }}</p>
            <ul>
              <li v-for="(item, index) in tier.included" :key="index">
                {{ item }}
              </li>
            </ul>
          </div>

          <div class="pd-list-block">
            <p>{{ deckLabels.typicalClients }}</p>
            <ul>
              <li v-for="(client, index) in tier.typicalClients" :key="index">
                {{ client }}
              </li>
            </ul>
          </div>
        </article>
      </div>
    </section>

    <section class="pd-section pd-care-section">
      <header class="pd-section-header">
        <p class="pd-eyebrow">{{ deckLabels.pricingArea }}</p>
        <h3>{{ deckLabels.monthlyCare }}</h3>
        <p>{{ deckLabels.monthlyCareNote }}</p>
      </header>

      <div class="pd-care-grid">
        <article v-for="plan in serviceTiers" :key="plan.id" class="pd-care-card">
          <header>
            <h4>{{ plan.title }}</h4>
            <strong>{{ formatPrice(plan.monthlyTWD) }}{{ monthlySuffix }}</strong>
          </header>
          <p class="pd-care-applies">{{ plan.appliesTo }}</p>
          <p>{{ plan.summary }}</p>
        </article>
      </div>
    </section>

    <section class="pd-section">
      <header class="pd-section-header">
        <p class="pd-eyebrow">{{ deckLabels.tierAddons }}</p>
        <h3>{{ copy?.addonsTitle || 'Tier-linked add-ons' }}</h3>
        <p>{{ deckLabels.tierAddonsNote }}</p>
      </header>

      <div class="pd-addon-groups">
        <article
          v-for="group in tierAddonGroups"
          :key="group.id"
          class="pd-addon-group"
        >
          <header>
            <div>
              <p class="pd-tier-label">{{ group.appliesTo }}</p>
              <h4>{{ group.title }}</h4>
            </div>
            <p>{{ group.summary }}</p>
          </header>
          <div class="pd-table-wrap">
            <table class="pd-price-table">
              <thead>
                <tr>
                  <th>{{ deckLabels.addonColumn }}</th>
                  <th>{{ deckLabels.setup }}</th>
                  <th>{{ deckLabels.monthly }}</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="addon in group.addons" :key="addon.id">
                  <td>{{ addon.title }}</td>
                  <td>{{ formatSetup(addon) }}</td>
                  <td>{{ formatMonthly(addon) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </article>
      </div>
    </section>

    <section
      id="apprelay-add-on"
      class="pd-section pd-apprelay-section"
      tabindex="-1"
    >
      <header class="pd-section-header">
        <p class="pd-eyebrow">{{ deckLabels.apprelayAddons }}</p>
        <h3>{{ deckLabels.apprelayTitle }}</h3>
        <p>{{ deckLabels.apprelayDescription }}</p>
      </header>

      <div class="pd-table-wrap">
        <table class="pd-price-table">
          <thead>
            <tr>
              <th>{{ deckLabels.apprelaySurfaceColumn }}</th>
              <th>{{ deckLabels.setup }}</th>
              <th>{{ deckLabels.monthly }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="addon in appRelayAddons" :key="addon.id">
              <td>{{ addon.title }}</td>
              <td>{{ formatSetup(addon) }}</td>
              <td>{{ formatMonthly(addon) }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section class="pd-discovery">
      <div>
        <p class="pd-eyebrow">{{ deckLabels.customScope }}</p>
        <h3>{{ discovery.title }}</h3>
        <p>{{ discovery.summary }}</p>
      </div>
      <strong>{{ formatPrice(discovery.setupTWD) }}</strong>
    </section>
  </section>
</template>

<script setup>
import { computed, nextTick, ref } from 'vue';
import { pricingContent } from '../pricing';

const props = defineProps({
  brand: { type: Object, required: true },
  copy: { type: Object, default: () => ({}) },
  pricingPackages: { type: Array, default: () => [] },
  addons: { type: Array, default: () => [] },
  maintenance: { type: Array, default: () => [] },
  pricingLocale: { type: String, default: 'zh-TW' }
});

const currencyProfiles = {
  'en-US': {
    code: 'USD',
    prefix: 'US$',
    locale: 'en-US',
    rateFromTWD: 1 / 32,
    rounding: 25
  },
  'zh-TW': {
    code: 'TWD',
    prefix: 'NT$',
    locale: 'zh-Hant',
    rateFromTWD: 1,
    rounding: 1
  },
  'ja-JP': {
    code: 'JPY',
    prefix: '¥',
    locale: 'ja-JP',
    rateFromTWD: 5,
    rounding: 5000
  },
  'ko-KR': {
    code: 'KRW',
    prefix: '₩',
    locale: 'ko-KR',
    rateFromTWD: 42,
    rounding: 50000
  }
};

const deckCopy = computed(() => props.copy || {});

const deckLabels = computed(() => ({
  enterprise: deckCopy.value?.labels?.enterprise || 'Enterprise services',
  tierIncluded: deckCopy.value?.labels?.tierIncluded || 'Tier - included',
  tierAddons: deckCopy.value?.labels?.tierAddons || 'Tier - add-on',
  apprelayAddons: deckCopy.value?.labels?.apprelayAddons || 'AppRelay add-on',
  pricingArea: deckCopy.value?.labels?.pricingArea || 'Clear pricing',
  included: deckCopy.value?.labels?.included || 'Included',
  typicalClients: deckCopy.value?.labels?.typicalClients || 'Best fit',
  packageHeadline:
    deckCopy.value?.labels?.packageHeadline || 'Cumulative Enterprise packages',
  packageNote:
    deckCopy.value?.labels?.packageNote ||
    'Tier 2 includes Tier 1. Tier 3 includes Tier 1 and Tier 2.',
  monthlyCare: deckCopy.value?.maintenanceTitle || 'Monthly platform care',
  monthlyCareNote:
    deckCopy.value?.labels?.maintenanceNote ||
    'Monthly care is separate from setup and feature add-ons.',
  tierAddonsNote:
    deckCopy.value?.labels?.tierAddonsNote ||
    'Add-ons are grouped by the tier they extend, not by one global menu.',
  currencyNote:
    deckCopy.value?.labels?.currencyNote ||
    'Display currency follows the selected language and is a marketing estimate.',
  setup: deckCopy.value?.labels?.setup || 'Setup',
  monthly: deckCopy.value?.labels?.monthly || 'Monthly',
  monthlyMinimum: deckCopy.value?.labels?.monthlyMinimum || 'Monthly minimum',
  addonColumn: deckCopy.value?.labels?.addonColumn || 'Add-on',
  apprelaySurfaceColumn:
    deckCopy.value?.labels?.apprelaySurfaceColumn || 'AppRelay surface',
  apprelayTitle: deckCopy.value?.labels?.apprelayTitle || 'AppRelay Add-On Service',
  apprelayDescription:
    deckCopy.value?.labels?.apprelayDescription ||
    'AppRelay is priced here only as an assistant/channel service attached to a client website, portal, dashboard, app, or approved channel.',
  customScope: deckCopy.value?.labels?.customScope || 'Custom scope'
}));

const valueHighlightOverrides = computed(() => deckCopy.value?.valueHighlights || []);
const valueHighlights = computed(() => {
  const defaults = pricingContent.valueHighlights || [];
  if (!valueHighlightOverrides.value.length) {
    return defaults;
  }
  const overrideMap = new Map(
    valueHighlightOverrides.value.map((entry) => [entry.id, entry])
  );
  const merged = defaults.map((highlight) => ({
    ...highlight,
    ...(overrideMap.get(highlight.id) || {})
  }));
  return merged;
});

const detailOverrides = computed(() => deckCopy.value?.details || {});
const packageDetails = computed(() => {
  const defaults = pricingContent.packageDetails || [];
  return defaults.map((detail) => {
    const override = detailOverrides.value?.[detail.id] || {};
    return {
      ...detail,
      ...override,
      included: override.included ?? detail.included,
      typicalClients: override.typicalClients ?? detail.typicalClients
    };
  });
});

const serviceTierOverrides = computed(() => deckCopy.value?.serviceTiers || {});
const serviceTiers = computed(() =>
  (pricingContent.serviceTiers || []).map((plan) => ({
    ...plan,
    ...(serviceTierOverrides.value?.[plan.id] || {})
  }))
);

const tierAddonGroupOverrides = computed(() => deckCopy.value?.tierAddonGroups || {});
const tierAddonGroups = computed(() =>
  (pricingContent.tierAddonGroups || []).map((group) => {
    const groupOverride = tierAddonGroupOverrides.value?.[group.id] || {};
    const addonOverrides = groupOverride.addons || {};
    return {
      ...group,
      ...groupOverride,
      addons: group.addons.map((addon) => ({
        ...addon,
        ...(addonOverrides[addon.id] || {})
      }))
    };
  })
);

const appRelayAddonOverrides = computed(() => deckCopy.value?.appRelayAddons || {});
const appRelayAddons = computed(() =>
  (pricingContent.appRelayAddons || []).map((addon) => ({
    ...addon,
    ...(appRelayAddonOverrides.value?.[addon.id] || {})
  }))
);

const discovery = computed(() => ({
  ...(pricingContent.discovery || {}),
  ...(deckCopy.value?.discovery || {})
}));

const pricingOverview = computed(() => pricingContent.overview || {});
const pricingHeadline = computed(
  () => props.copy?.headline || pricingOverview.value.headline || 'SourceGrid Enterprise Pricing'
);
const pricingSubhead = computed(
  () =>
    props.copy?.subhead ||
    pricingOverview.value.subhead ||
    'Cumulative website, dashboard, and app packages for companies.'
);
const pricingIntro = computed(() => props.copy?.intro || pricingOverview.value.intro || '');
const monthlySuffix = computed(() => props.copy?.maintenanceSuffix || '/mo');
const detailRefs = ref({});
const currencyProfile = computed(
  () => currencyProfiles[props.pricingLocale] || currencyProfiles['zh-TW']
);
const currencyNote = computed(
  () => `${deckLabels.value.currencyNote} ${currencyProfile.value.code}`
);

const setDetailRef = (el, id) => {
  if (!id) return;
  detailRefs.value[id] = el;
};

const scrollToDetail = async (id) => {
  if (!id) return;
  await nextTick();
  requestAnimationFrame(() => {
    const target = detailRefs.value[id];
    if (target) {
      target.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  });
};

const convertTWD = (value) => {
  const profile = currencyProfile.value;
  const raw = value * profile.rateFromTWD;
  return Math.round(raw / profile.rounding) * profile.rounding;
};

const formatPrice = (value) => {
  if (typeof value !== 'number') return '-';
  const profile = currencyProfile.value;
  const converted = convertTWD(value);
  return `${profile.prefix}${converted.toLocaleString(profile.locale)}`;
};

const formatPriceLabel = (value) => {
  if (typeof value !== 'string') return value;
  return value.replace(/NT\$([\d,]+)/g, (_match, amount) => {
    const numeric = Number(amount.replace(/,/g, ''));
    return Number.isFinite(numeric) ? formatPrice(numeric) : _match;
  });
};

const formatSetup = (item) => {
  if (item.setupLabel) return formatPriceLabel(item.setupLabel);
  if (typeof item.setupTWD === 'number') return formatPrice(item.setupTWD);
  return '-';
};

const formatMonthly = (item) => {
  if (item.monthlyLabel) return formatPriceLabel(item.monthlyLabel);
  if (typeof item.monthlyTWD === 'number') return `${formatPrice(item.monthlyTWD)}${monthlySuffix.value}`;
  return '-';
};
</script>

<style scoped>
.pd-wrapper {
  display: grid;
  gap: clamp(1.2rem, 3vw, 2rem);
}

.pd-overview,
.pd-section,
.pd-discovery {
  border: 1px solid rgba(55, 65, 81, 0.85);
  border-radius: 8px;
  background: rgba(15, 23, 42, 0.92);
  box-shadow: 0 16px 34px rgba(0, 0, 0, 0.45);
}

.pd-overview {
  padding: clamp(1.2rem, 3vw, 1.8rem);
  display: grid;
  gap: 0.5rem;
}

.pd-overview h2,
.pd-section-header h3,
.pd-discovery h3,
.pd-tier-card h4,
.pd-care-card h4,
.pd-addon-group h4 {
  margin: 0;
  color: rgba(248, 250, 252, 0.98);
}

.pd-overview p,
.pd-section-header p,
.pd-tier-summary,
.pd-list-block li,
.pd-care-card p,
.pd-addon-group p,
.pd-discovery p,
.pd-price-table td,
.pd-price-table th {
  color: rgba(226, 232, 240, 0.88);
}

.pd-overview-note {
  color: rgba(209, 213, 219, 0.82);
}

.pd-currency-note {
  color: rgba(148, 163, 184, 0.95);
  font-size: 0.92rem;
}

.pd-eyebrow,
.pd-tier-label,
.pd-list-block p {
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.14em;
  font-size: 0.72rem;
  color: rgba(203, 213, 225, 0.78);
  font-weight: 700;
}

.pd-highlight-section,
.pd-tier-grid,
.pd-care-grid {
  display: grid;
  gap: 0.9rem;
}

.pd-highlight-section {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.pd-highlight-card,
.pd-tier-card,
.pd-care-card,
.pd-addon-group {
  border: 1px solid rgba(71, 85, 105, 0.78);
  border-radius: 8px;
  background: rgba(2, 6, 23, 0.72);
}

.pd-highlight-card {
  padding: 0.9rem 1rem;
  display: grid;
  gap: 0.35rem;
  text-align: left;
  color: inherit;
  font: inherit;
  cursor: pointer;
}

.pd-highlight-card span {
  color: rgba(147, 197, 253, 0.92);
  font-size: 0.8rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0.12em;
}

.pd-highlight-card strong {
  color: rgba(248, 250, 252, 0.96);
  line-height: 1.45;
}

.pd-section {
  padding: clamp(1rem, 3vw, 1.35rem);
}

.pd-section-header {
  display: grid;
  gap: 0.35rem;
  margin-bottom: 1rem;
}

.pd-tier-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.pd-tier-card {
  padding: 1rem;
  display: grid;
  gap: 0.85rem;
}

.pd-tier-header {
  display: flex;
  gap: 0.75rem;
  align-items: center;
}

.pd-tier-number {
  width: 2.3rem;
  height: 2.3rem;
  border-radius: 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(59, 130, 246, 0.16);
  border: 1px solid rgba(147, 197, 253, 0.35);
  color: rgba(191, 219, 254, 0.98);
  font-weight: 900;
}

.pd-price-box {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0.55rem;
}

.pd-price-box div {
  min-width: 0;
  border: 1px solid rgba(71, 85, 105, 0.7);
  border-radius: 8px;
  padding: 0.75rem;
  background: rgba(15, 23, 42, 0.88);
}

.pd-price-box span,
.pd-price-box em {
  display: block;
  color: rgba(203, 213, 225, 0.76);
  font-size: 0.72rem;
  font-style: normal;
}

.pd-price-box strong {
  display: block;
  margin-top: 0.25rem;
  color: rgba(254, 243, 199, 0.98);
  font-size: 1.1rem;
}

.pd-dependency {
  margin: 0;
  border-left: 3px solid rgba(96, 165, 250, 0.72);
  padding-left: 0.65rem;
  color: rgba(191, 219, 254, 0.92);
  font-size: 0.9rem;
}

.pd-list-block {
  display: grid;
  gap: 0.4rem;
}

.pd-list-block ul {
  margin: 0;
  padding-left: 1rem;
  display: grid;
  gap: 0.3rem;
  font-size: 0.9rem;
}

.pd-care-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.pd-care-card {
  padding: 0.95rem;
  display: grid;
  gap: 0.45rem;
}

.pd-care-card header {
  display: flex;
  gap: 0.75rem;
  align-items: baseline;
  justify-content: space-between;
}

.pd-care-card strong {
  color: rgba(254, 243, 199, 0.98);
  white-space: nowrap;
}

.pd-care-applies {
  margin: 0;
  color: rgba(147, 197, 253, 0.9) !important;
  font-size: 0.86rem;
  font-weight: 700;
}

.pd-addon-groups {
  display: grid;
  gap: 1rem;
}

.pd-addon-group {
  overflow: hidden;
}

.pd-addon-group > header {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.95rem 1rem;
  border-bottom: 1px solid rgba(71, 85, 105, 0.7);
}

.pd-addon-group > header p {
  margin: 0;
  max-width: 34rem;
}

.pd-table-wrap {
  overflow-x: auto;
}

.pd-price-table {
  width: 100%;
  border-collapse: collapse;
  min-width: 520px;
}

.pd-price-table th,
.pd-price-table td {
  padding: 0.7rem 0.85rem;
  border-bottom: 1px solid rgba(51, 65, 85, 0.72);
  text-align: left;
  vertical-align: top;
}

.pd-price-table th {
  color: rgba(203, 213, 225, 0.72);
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.12em;
}

.pd-price-table td:nth-child(2),
.pd-price-table td:nth-child(3),
.pd-price-table th:nth-child(2),
.pd-price-table th:nth-child(3) {
  white-space: nowrap;
  text-align: right;
}

.pd-apprelay-section {
  border-color: rgba(16, 185, 129, 0.38);
}

.pd-discovery {
  padding: 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.pd-discovery strong {
  color: rgba(254, 243, 199, 0.98);
  font-size: 1.3rem;
  white-space: nowrap;
}

[data-theme='golden-light'] .pd-overview,
[data-theme='golden-light'] .pd-section,
[data-theme='golden-light'] .pd-discovery,
[data-theme='golden-light'] .pd-highlight-card,
[data-theme='golden-light'] .pd-tier-card,
[data-theme='golden-light'] .pd-care-card,
[data-theme='golden-light'] .pd-addon-group,
[data-theme='golden-light'] .pd-price-box div {
  background: rgba(15, 23, 42, 0.92);
  border-color: rgba(55, 65, 81, 0.75);
}

@media (max-width: 1180px) {
  .pd-tier-grid {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (max-width: 860px) {
  .pd-highlight-section,
  .pd-care-grid {
    grid-template-columns: minmax(0, 1fr);
  }

  .pd-price-box {
    grid-template-columns: minmax(0, 1fr);
  }

  .pd-addon-group > header,
  .pd-discovery {
    display: grid;
  }
}
</style>
