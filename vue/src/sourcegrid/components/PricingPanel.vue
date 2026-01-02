<script setup>
import { computed } from 'vue';
import PricingDeck from './PricingDeck.vue';
import PricingShotsStrip from './PricingShotsStrip.vue';

const props = defineProps({
  brand: { type: Object, required: true },
  copy: { type: Object, default: () => ({}) },
  pricingPackages: { type: Array, default: () => [] },
  addons: { type: Array, default: () => [] },
  maintenance: { type: Array, default: () => [] },
  showBackButton: { type: Boolean, default: false },
  backLabel: { type: String, default: '' }
});

const emit = defineEmits(['back']);

const heroImage = computed(() => {
  const assets = props.brand?.assets ?? {};
  const shotImage = Array.isArray(assets.pricingShots)
    ? assets.pricingShots.find((shot) => shot?.image)?.image
    : undefined;
  return (
    assets.pricingHero ||
    assets.pricingFeature ||
    shotImage ||
    assets.heroFeature ||
    assets.hero ||
    assets.secondary ||
    null
  );
});

const heroStyle = computed(() => {
  if (!heroImage.value) return undefined;
  return { backgroundImage: `url(${heroImage.value})` };
});

const heroEyebrow = computed(() => props.copy?.eyebrow || 'SourceGrid Labs Packages');
const heroHeadline = computed(
  () => props.copy?.headline || 'Fixed-scope website and system builds.'
);
const heroIntro = computed(
  () =>
    props.copy?.intro ||
    props.copy?.subhead ||
    'We build brand systems, content surfaces, and commerce-ready storefronts as fixed engagements.'
);

const backCtaLabel = computed(
  () => props.backLabel || props.copy?.switchCta || 'Back to experience'
);

const pricingShots = computed(() => {
  const limit = 3;
  const shots = [];
  const seen = new Set();
  const assets = props.brand?.assets ?? {};
  const fallbackLabel = props.copy?.shotFallback || props.brand?.name || 'Signature shot';

  const pushShot = (entry, defaultLabel) => {
    if (!entry) return;
    const normalized = typeof entry === 'string' ? { image: entry } : entry;
    const image = normalized?.image;
    if (!image || seen.has(image)) return;
    shots.push({
      ...normalized,
      image,
      label: normalized?.label || defaultLabel || fallbackLabel
    });
    seen.add(image);
  };

  const appendCollection = (collection = [], labelFactory) => {
    collection.forEach((entry, index) => {
      if (shots.length >= limit) return;
      const defaultLabel = labelFactory?.(index);
      pushShot(entry, defaultLabel);
    });
  };

  appendCollection(assets.pricingShots, (index) => `${fallbackLabel} ${index + 1}`);
  appendCollection(assets.settings);
  appendCollection(assets.elements);
  appendCollection(assets.gallery);
  appendCollection(assets.ritualScenes);
  appendCollection(assets.ctaButtons);

  [assets.pricingHero, assets.pricingFeature, heroImage.value, assets.heroFeature, assets.hero].forEach(
    (image) => {
      if (shots.length >= limit) return;
      pushShot(image, props.brand?.name);
    }
  );

  return shots.slice(0, limit);
});

const handleBack = () => {
  emit('back');
};
</script>

<template>
  <section class="pp-panel">
    <div class="pp-hero" :style="heroStyle">
      <div class="pp-hero-overlay" />
      <div class="pp-hero-copy">
        <p class="pp-eyebrow">{{ heroEyebrow }}</p>
        <h2>{{ heroHeadline }}</h2>
        <p class="pp-intro">
          {{ heroIntro }}
        </p>
        <button
          v-if="showBackButton"
          class="pp-pill"
          type="button"
          @click="handleBack"
        >
          {{ backCtaLabel }}
        </button>
      </div>
    </div>

    <div class="pp-deck">
      <PricingDeck
        :brand="brand"
        :copy="copy"
        :pricing-packages="pricingPackages"
        :addons="addons"
        :maintenance="maintenance"
      />
    </div>

    <PricingShotsStrip :shots="pricingShots" :copy="copy" />
  </section>
</template>

<style scoped>
.pp-panel {
  background: var(--surface);
}

.pp-hero {
  position: relative;
  min-height: 320px;
  background-size: cover;
  background-position: center;
  border-bottom: 1px solid color-mix(in srgb, var(--border) 55%, transparent);
}

.pp-hero-overlay {
  position: absolute;
  inset: 0;
  background:
    linear-gradient(to bottom, rgba(15, 23, 42, 0.1), rgba(15, 23, 42, 0.85)),
    radial-gradient(circle at 0% 0%, rgba(15, 23, 42, 0.45), transparent 55%);
}

.pp-hero-copy {
  position: relative;
  padding: clamp(2.4rem, 5vw, 3.4rem);
  max-width: 48rem;
  color: rgba(248, 250, 252, 0.95);
  display: grid;
  gap: 0.85rem;
}

.pp-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.32em;
  font-size: 0.7rem;
  opacity: 0.85;
}

.pp-intro {
  color: rgba(226, 232, 240, 0.9);
  line-height: 1.7;
}

.pp-pill {
  justify-self: start;
  margin-top: 0.5rem;
  border-radius: 999px;
  border: 1px solid rgba(248, 250, 252, 0.5);
  padding: 0.55rem 1.3rem;
  background: rgba(15, 23, 42, 0.55);
  color: rgba(248, 250, 252, 0.95);
  cursor: pointer;
  backdrop-filter: blur(12px);
  transition: background 200ms ease, color 200ms ease, border 200ms ease;
}

.pp-pill:hover {
  background: rgba(15, 23, 42, 0.8);
  border-color: rgba(248, 250, 252, 0.8);
}

.pp-deck {
  padding: clamp(1.6rem, 5vw, 3rem) clamp(1.6rem, 5vw, 3.2rem) clamp(2.8rem, 6vw, 4.4rem);
}
</style>
