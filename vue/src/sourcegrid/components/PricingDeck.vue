<template>
  <section class="pd-wrapper">
    <section v-if="valueHighlights.length" class="pd-highlight-section">
      <button
        v-for="highlight in valueHighlights"
        :key="highlight.id"
        class="pd-highlight-card"
        type="button"
        @click="scrollToDetail(highlight.id)"
      >
        <header>
          <p class="pd-eyebrow">{{ highlight.title }}</p>
        </header>
        <p class="pd-highlight-body">
          {{ highlight.body }}
        </p>
        <div v-if="highlight.hover" class="pd-highlight-bubble" aria-hidden="true">
          <p>{{ highlight.hover }}</p>
        </div>
      </button>
    </section>

    <section class="pd-detail-grid">
      <article
        v-for="detail in packageDetails"
        :key="detail.id"
        class="pd-detail-card"
        :ref="(el) => setDetailRef(el, detail.id)"
      >
        <header class="pd-detail-header">
          <div class="pd-detail-title">
            <span class="pd-detail-icon">{{ detail.icon }}</span>
            <div>
              <p class="pd-detail-tagline">{{ detail.tagline }}</p>
              <h3>{{ detail.title }}</h3>
            </div>
          </div>
          <div class="pd-detail-price">
            {{ formatUSD(detail.priceUSD) }}
            <small>{{ formatTWD(detail.priceTWD) }}</small>
          </div>
          <div v-if="detail.hoverNote" class="pd-detail-note" tabindex="0">
            <span>?</span>
            <div class="pd-detail-bubble">
              <p>{{ detail.hoverNote }}</p>
            </div>
          </div>
        </header>
        <p class="pd-detail-summary">
          {{ detail.summary }}
        </p>
        <div class="pd-detail-section">
          <p class="pd-detail-section-title">{{ deckLabels.included }}</p>
          <ul>
            <li v-for="(item, index) in detail.included" :key="index">
              {{ item }}
            </li>
          </ul>
        </div>
        <div class="pd-detail-section">
          <p class="pd-detail-section-title">{{ deckLabels.typicalClients }}</p>
          <ul>
            <li v-for="(client, index) in detail.typicalClients" :key="index">
              {{ client }}
            </li>
          </ul>
        </div>
      </article>

      <article
        v-if="addonsData.length || maintenanceData.length"
        class="pd-detail-card pd-addon-summary"
      >
        <header class="pd-detail-header">
          <div class="pd-detail-title">
            <span class="pd-detail-icon">+</span>
            <div>
              <p class="pd-detail-tagline">{{ deckLabels.addonsTagline }}</p>
              <h3>{{ copy?.addonsTitle || 'Popular add-ons' }}</h3>
            </div>
          </div>
        </header>
        <ul class="pd-addon-list">
          <li v-for="addon in addonsData" :key="addon.id">
            <span>{{ addon.displayName || addon.id }}</span>
            <span class="pd-double-price">
              <strong>{{ formatUSD(addon.priceUSD) }}</strong>
              <em>{{ formatTWD(addon.priceTWD) }}</em>
            </span>
          </li>
        </ul>
        <div class="pd-detail-section pd-maintenance-block">
          <p class="pd-detail-section-title">
            {{ copy?.maintenanceTitle || 'Maintenance plans' }}
          </p>
          <ul class="pd-maintenance-list">
            <li v-for="plan in maintenanceData" :key="plan.id">
              <span>{{ plan.displayName || plan.id }}</span>
              <span class="pd-double-price">
                <strong>{{ formatUSD(plan.priceUSD) }}</strong>
                <em>{{ formatTWD(plan.priceTWD) }}</em>
              </span>
            </li>
          </ul>
          <p class="pd-maintenance-note">{{ deckLabels.maintenanceNote }}</p>
        </div>
      </article>
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
  maintenance: { type: Array, default: () => [] }
});

const deckCopy = computed(() => props.copy || {});

const deckLabels = computed(() => ({
  included: deckCopy.value?.labels?.included || 'Included',
  typicalClients: deckCopy.value?.labels?.typicalClients || 'Typical clients',
  addonsTagline: deckCopy.value?.labels?.addonsTagline || 'Add-on modules',
  maintenanceNote: deckCopy.value?.labels?.maintenanceNote || 'Billing is monthly.'
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
  valueHighlightOverrides.value.forEach((entry) => {
    if (!defaults.find((item) => item.id === entry.id)) {
      merged.push(entry);
    }
  });
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
const packagesData = computed(() =>
  props.pricingPackages?.length ? props.pricingPackages : pricingContent.packages
);
const pricingOverview = computed(() => pricingContent.overview || {});
const pricingHeadline = computed(
  () => props.copy?.headline || pricingOverview.value.headline || 'SourceGrid Labs Packages'
);
const pricingSubhead = computed(
  () =>
    props.copy?.subhead ||
    pricingOverview.value.subhead ||
    'Fixed-price websites, systems, and apps built with clear scope.'
);
const pricingIntro = computed(() => props.copy?.intro || pricingOverview.value.intro || '');

const addonsData = computed(() =>
  props.addons?.length ? props.addons : pricingContent.addons
);
const maintenanceData = computed(() =>
  props.maintenance?.length ? props.maintenance : pricingContent.maintenance
);

const detailRefs = ref({});

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

const formatUSD = (value) => `$${value.toLocaleString('en-US')}`;
const formatTWD = (value) => `NT$${value.toLocaleString('zh-Hant')}`;
</script>

<style scoped>
.pd-highlight-section {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1rem;
  margin-bottom: clamp(1.2rem, 3vw, 2rem);
}

[data-theme='golden-light'] .pd-wrapper,
[data-theme='golden-light'] .pd-wrapper p,
[data-theme='golden-light'] .pd-wrapper li,
[data-theme='golden-light'] .pd-wrapper h3,
[data-theme='golden-light'] .pd-wrapper span,
[data-theme='golden-light'] .pd-wrapper small {
  color: rgba(248, 250, 252, 0.95);
}

[data-theme='golden-light'] .pd-highlight-card,
[data-theme='golden-light'] .pd-detail-card,
[data-theme='golden-light'] .pd-detail-bubble,
[data-theme='golden-light'] .pd-highlight-bubble {
  background: rgba(15, 23, 42, 0.92);
  border-color: rgba(55, 65, 81, 0.75);
  box-shadow: 0 18px 35px rgba(5, 9, 21, 0.55);
}

[data-theme='golden-light'] .pd-detail-note {
  border-color: rgba(248, 250, 252, 0.45);
}

[data-theme='golden-light'] .pd-detail-summary,
[data-theme='golden-light'] .pd-detail-section-title,
[data-theme='golden-light'] .pd-detail-price small,
[data-theme='golden-light'] .pd-addon-list li,
[data-theme='golden-light'] .pd-maintenance-list li {
  color: rgba(248, 250, 252, 0.85);
}

.pd-highlight-card {
  position: relative;
  border-radius: 20px;
  padding: 1rem 1.1rem;
  border: 1px solid rgba(55, 65, 81, 0.85);
  background: rgba(15, 23, 42, 0.9);
  box-shadow: 0 12px 28px rgba(0, 0, 0, 0.55);
  overflow: hidden;
  text-align: left;
  color: inherit;
  font: inherit;
  cursor: pointer;
}

.pd-highlight-card:focus {
  outline: 2px solid rgba(248, 250, 252, 0.6);
  outline-offset: 2px;
}

.pd-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  font-size: 0.75rem;
  opacity: 0.75;
}

.pd-highlight-body {
  margin-top: 0.35rem;
  color: rgba(226, 232, 240, 0.95);
  font-size: 0.95rem;
}

.pd-highlight-bubble {
  position: absolute;
  inset: auto 0 0 auto;
  transform: translate(-1rem, 120%);
  background: rgba(15, 23, 42, 0.98);
  border: 1px solid rgba(55, 65, 81, 0.9);
  border-radius: 18px;
  padding: 0.75rem 0.9rem;
  width: min(240px, 90vw);
  box-shadow: 0 18px 30px rgba(0, 0, 0, 0.55);
  opacity: 0;
  pointer-events: none;
  transition: opacity 200ms ease, transform 200ms ease;
}

.pd-highlight-card:hover .pd-highlight-bubble,
.pd-highlight-card:focus .pd-highlight-bubble {
  opacity: 1;
  transform: translate(-1rem, calc(100% + 0.5rem));
}

.pd-detail-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}

.pd-detail-card {
  border-radius: 18px;
  padding: 1rem 1.1rem;
  background: rgba(15, 23, 42, 0.95);
  border: 1px solid rgba(55, 65, 81, 0.85);
  position: relative;
}

.pd-detail-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.8rem;
}

.pd-detail-title {
  display: flex;
  gap: 0.65rem;
  align-items: center;
}

.pd-detail-icon {
  font-size: 1.5rem;
}

.pd-detail-tagline {
  text-transform: uppercase;
  letter-spacing: 0.18em;
  font-size: 0.7rem;
  opacity: 0.7;
}

.pd-detail-price {
  text-align: right;
  font-weight: 600;
}

.pd-detail-price small {
  display: block;
  font-size: 0.75rem;
  opacity: 0.75;
}

.pd-detail-note {
  position: relative;
  width: 28px;
  height: 28px;
  border-radius: 999px;
  border: 1px solid rgba(248, 250, 252, 0.4);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  cursor: default;
}

.pd-detail-note:focus {
  outline: 2px solid rgba(248, 250, 252, 0.6);
  outline-offset: 2px;
}

.pd-detail-bubble {
  position: absolute;
  top: 110%;
  right: 0;
  width: min(240px, 80vw);
  border-radius: 18px;
  background: rgba(15, 23, 42, 0.98);
  border: 1px solid rgba(55, 65, 81, 0.85);
  padding: 0.7rem 0.85rem;
  font-size: 0.85rem;
  box-shadow: 0 18px 30px rgba(0, 0, 0, 0.55);
  opacity: 0;
  transform: translateY(0.25rem);
  transition: opacity 200ms ease, transform 200ms ease;
  pointer-events: none;
}

.pd-detail-note:hover .pd-detail-bubble,
.pd-detail-note:focus .pd-detail-bubble {
  opacity: 1;
  transform: translateY(0.5rem);
}

.pd-detail-summary {
  margin: 0.75rem 0 0.9rem;
  font-size: 0.95rem;
  color: rgba(226, 232, 240, 0.95);
}

.pd-detail-section + .pd-detail-section {
  margin-top: 0.9rem;
}

.pd-detail-section-title {
  text-transform: uppercase;
  letter-spacing: 0.18em;
  font-size: 0.72rem;
  opacity: 0.78;
  margin-bottom: 0.35rem;
}

.pd-detail-section ul {
  margin: 0;
  padding-left: 1rem;
  display: grid;
  gap: 0.35rem;
  font-size: 0.9rem;
}

.pd-addon-list,
.pd-maintenance-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 0.4rem;
  font-size: 0.9rem;
}

.pd-addon-list li,
.pd-maintenance-list li {
  display: flex;
  justify-content: space-between;
}

.pd-double-price {
  display: inline-flex;
  gap: 0.65rem;
  align-items: baseline;
}

.pd-double-price strong {
  font-weight: 600;
}

.pd-double-price em {
  font-style: normal;
  color: rgba(209, 213, 219, 0.85);
}

.pd-maintenance-block {
  margin-top: 1.25rem;
  padding-top: 1rem;
  border-top: 1px solid rgba(55, 65, 81, 0.6);
}

.pd-maintenance-note {
  margin-top: 0.5rem;
  font-size: 0.85rem;
  color: rgba(209, 213, 219, 0.75);
}

@media (max-width: 980px) {
  .pd-detail-grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
