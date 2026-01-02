<script setup>
import { computed, nextTick, ref } from 'vue';
import PricingPanel from '../components/PricingPanel.vue';
import { buildHeroCtas } from './utils/buildHeroCtas';

const props = defineProps({
  navItems: { type: Array, default: () => [] },
  activePage: { type: String, default: '' },
  templateId: { type: String, default: '' },
  brand: { type: Object, required: true },
  copy: { type: Object, required: true },
  pricingPackages: { type: Array, default: () => [] },
  addons: { type: Array, default: () => [] },
  maintenance: { type: Array, default: () => [] }
});

const emit = defineEmits(['navigate', 'contact']);

const heroImage = computed(
  () => props.brand?.assets?.hero || props.brand?.assets?.heroFeature
);
const heroTexture = computed(
  () => props.brand?.assets?.gradientBackdrop || props.brand?.assets?.textures?.grain || null
);
const ctaButtons = computed(() => buildHeroCtas({ brand: props.brand, copy: props.copy }));
const shellTextureStyle = computed(() => {
  const texture = props.brand?.assets?.textures?.grain;
  return texture ? { '--rh-shell-texture': `url(${texture})` } : {};
});
const ritualScenes = computed(() => {
  const scenes = props.brand?.assets?.ritualScenes ?? props.brand?.assets?.settings ?? [];
  return scenes.slice(0, 4);
});

const menuDrops = computed(() => {
  const brandItems = props.brand?.assets?.elements ?? [];

  const fallbackImages = [];
  const ritualPool = props.brand?.assets?.ritualScenes ?? [];
  ritualPool.forEach((scene) => {
    if (scene?.image) fallbackImages.push(scene.image);
  });
  const galleryPool = props.brand?.assets?.gallery ?? [];
  galleryPool.forEach((item) => {
    if (!item) return;
    if (typeof item === 'string') {
      fallbackImages.push(item);
      return;
    }
    if (item?.image) fallbackImages.push(item.image);
  });
  if (!fallbackImages.length && heroImage.value) fallbackImages.push(heroImage.value);

  const pickFallbackImage = (index) => {
    if (!fallbackImages.length) return null;
    return fallbackImages[index % fallbackImages.length];
  };

  if (brandItems.length) {
    return brandItems.slice(0, 6).map((item, index) => ({
      id: item.id || `drop-${index}`,
      title: item.label || item.title || `Signature ${index + 1}`,
      body: item.description || item.body || props.copy?.home?.sceneFallback || '',
      badge: item.tag || item.badge || (index === 0 ? 'Chef pick' : index === 1 ? 'Limited' : 'Signature'),
      image: item.image || pickFallbackImage(index)
    }));
  }

  return [
    {
      id: 'drop-1',
      title: props.copy?.home?.step2Title || 'Broth flights',
      body:
        props.copy?.home?.step2Body ||
        'Smoked, clarified, and poured in sequence while guests settle into the glow of the counter.',
      badge: 'Chef pick',
      image: pickFallbackImage(0)
    },
    {
      id: 'drop-2',
      title: props.copy?.home?.step3Title || 'Heatwave bowl',
      body:
        props.copy?.home?.step3Body ||
        'Signature bowls land in waves, toppings torched and finished to order for a bright, immediate hit.',
      badge: 'Limited',
      image: pickFallbackImage(1)
    },
    {
      id: 'drop-3',
      title: props.copy?.home?.step1Title || 'Queue at dusk',
      body:
        props.copy?.home?.step1Body ||
        'Counter-only seatings paced so the line thins as the steam rises and the lights come on.',
      badge: 'Signature',
      image: pickFallbackImage(2)
    },
    {
      id: 'drop-4',
      title: props.copy?.home?.step4Title || 'Neon afterglow',
      body:
        props.copy?.home?.step4Body ||
        'Late-night playlists, quiet second rounds, and the last sip while the glow holds.',
      badge: 'After hours',
      image: pickFallbackImage(3)
    }
  ];
});
const revealedPills = ref([]);
const mainEl = ref(null);

const revealThumb = (index) => {
  if (!revealedPills.value[index]) {
    revealedPills.value[index] = true;
    revealedPills.value = [...revealedPills.value];
  }
};

const handlePricingToggle = async () => {
  const targetPage = props.activePage === 'pricing' ? 'home' : 'pricing';
  emit('navigate', targetPage);
  await nextTick();
  requestAnimationFrame(() => {
    if (typeof window === 'undefined') return;
    const el = mainEl.value;
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
};

const handleContactClick = () => {
  emit('contact');
};

const handleNav = (item) => {
  if (item.disabled) return;
  emit('navigate', item.id);
};

</script>

<template>
  <section
    class="template-shell saffron-heatwave"
    :data-template="templateId"
    :style="shellTextureStyle"
  >
    <!-- HERO: neon counter -->
    <header class="rh-hero">
      <div
        class="rh-hero-bg"
        :style="heroImage ? { backgroundImage: `url(${heroImage})` } : undefined"
      ></div>
      <div
        v-if="heroTexture"
        class="rh-hero-texture"
        :style="{ backgroundImage: `url(${heroTexture})` }"
      ></div>
      <div class="rh-hero-inner">
        <div class="rh-hero-copy">
          <p class="rh-eyebrow">{{ brand.name }}</p>
          <h1>{{ brand.tagline }}</h1>
          <p class="rh-storyline">
            {{ brand.description }}
          </p>
          <div class="rh-hero-cta">
            <button type="button" class="rh-hero-button" @click="handleContactClick">
              {{ copy.cta?.button || 'Book a stay' }}
            </button>
          </div>
        </div>
        <div class="rh-hero-pills" v-if="ctaButtons.length">
          <button
            v-for="(cta, index) in ctaButtons"
            :key="cta.id || index"
            class="rh-pill-card"
            type="button"
            @mouseenter="revealThumb(index)"
            @focus="revealThumb(index)"
            @click="handlePricingToggle"
          >
            <div class="rh-pill-text">
              <p class="rh-pill-label">{{ cta.label }}</p>
              <p class="rh-pill-body">
                {{ cta.description || copy.home?.sceneFallback }}
              </p>
            </div>
            <div
              v-if="cta.image"
              :class="['rh-pill-thumb', { 'is-revealed': revealedPills[index] }]"
              :style="{ backgroundImage: `url(${cta.image})` }"
            ></div>
          </button>
        </div>
      </div>
    </header>

    <nav v-if="navItems.length" class="rh-nav" aria-label="Template navigation">
      <button
        v-for="item in navItems"
        :key="item.id"
        type="button"
        :class="[
          'rh-nav-link',
          { 'is-active': activePage === item.id, 'is-disabled': item.disabled }
        ]"
        :disabled="item.disabled"
        @click="handleNav(item)"
      >
        {{ item.label }}
      </button>
    </nav>

    <main class="rh-main" ref="mainEl">
      <!-- HOME -->
      <article v-if="activePage === 'home'" class="rh-panel rh-home">
        <section class="rh-track" v-if="ritualScenes.length">
          <div
            v-for="(scene, index) in ritualScenes"
            :key="scene.id || index"
            class="rh-track-item"
          >
            <span class="rh-step">0{{ index + 1 }}</span>
            <div class="rh-track-head">
              <h2>
                <template v-if="scene.label">
                  {{ scene.label }}
                </template>
                <template v-else-if="index === 0">
                  {{ copy.home?.step1Title || 'Queue at dusk.' }}
                </template>
                <template v-else-if="index === 1">
                  {{ copy.home?.step2Title || 'Broth flights.' }}
                </template>
                <template v-else-if="index === 2">
                  {{ copy.home?.step3Title || 'Heatwave service.' }}
                </template>
                <template v-else>
                  {{ copy.home?.step4Title || 'Neon afterglow at the counter.' }}
                </template>
              </h2>
            </div>
            <div class="rh-track-body">
              <div class="rh-track-text">
                <p class="rh-body">
                  <template v-if="scene.description">
                    {{ scene.description }}
                  </template>
                  <template v-else-if="index === 0">
                    {{ copy.home?.step1Body || 'Doors up at golden hour, counter-only, paced seatings so the line thins as the steam rises.' }}
                  </template>
                  <template v-else-if="index === 1">
                    {{ copy.home?.step2Body || 'Smoked, clarified, and poured in sequence while guests settle into the glow of the counter.' }}
                  </template>
                  <template v-else-if="index === 2">
                    {{ copy.home?.step3Body || 'Signature bowls land in waves, toppings torched and finished to order so each seat gets its own heatwave moment.' }}
                  </template>
                  <template v-else>
                    {{ copy.home?.step4Body || 'Guests linger over last sips, late-night playlists, and quiet second rounds while steam hangs in the air above the counter.' }}
                  </template>
                </p>
              </div>
              <div
                v-if="scene.image"
                class="rh-track-image"
                :style="{ backgroundImage: `url(${scene.image})` }"
              >
                <div class="rh-track-image-glow"></div>
              </div>
            </div>
          </div>
        </section>

        <section class="rh-drops" v-if="menuDrops.length">
          <header class="rh-panel-header">
            <p class="rh-mini-eyebrow">{{ copy.home?.galleryEyebrow || 'Signature drops' }}</p>
            <h2>{{ copy.home?.galleryHeadline || 'Menu highlights, paced like a playlist.' }}</h2>
            <p class="rh-body rh-muted">
              {{ copy.home?.sceneFallback || 'Small, deliberate selections—each one designed to land clean and bright.' }}
            </p>
          </header>

          <div class="rh-drops-grid" role="list">
            <article
              v-for="(drop, index) in menuDrops"
              :key="drop.id || index"
              class="rh-drop"
              role="listitem"
              :style="{ '--rhDropDelay': (index * 80) + 'ms' }"
            >
              <div
                v-if="drop.image"
                class="rh-drop-media"
                :style="{ backgroundImage: `url(${drop.image})` }"
                aria-hidden="true"
              >
                <div class="rh-drop-media-glow"></div>
              </div>
              <div class="rh-drop-content">
                <div class="rh-drop-head">
                  <span class="rh-drop-badge">{{ drop.badge }}</span>
                  <span class="rh-drop-index">0{{ index + 1 }}</span>
                </div>
                <h3 class="rh-drop-title">{{ drop.title }}</h3>
                <p class="rh-body rh-drop-body">{{ drop.body }}</p>
              </div>
            </article>
          </div>
        </section>
      </article>

      <!-- PRICING -->
      <article v-else-if="activePage === 'pricing'" class="rh-panel rh-pricing">
        <PricingPanel
          :brand="brand"
          :copy="copy.pricing"
          :pricing-packages="pricingPackages"
          :addons="addons"
          :maintenance="maintenance"
          @back="handlePricingToggle"
        />
      </article>

      <!-- PLACEHOLDER -->
      <article v-else class="rh-panel rh-placeholder">
        <h2>{{ copy.placeholder?.heading }}</h2>
        <p class="rh-body rh-muted">
          {{ copy.placeholder?.intro }}
        </p>
      </article>
    </main>
  </section>
</template>

<style scoped>
.template-shell {
  border-radius: var(--radiusLg);
  overflow: hidden;
  border: 1px solid color-mix(in srgb, var(--accent) 55%, transparent);
  background-image:
    radial-gradient(circle at 0% 0%, rgba(15, 23, 42, 0.98), rgba(15, 23, 42, 1)),
    var(--rh-shell-texture, none);
  background-size: cover;
  background-blend-mode: normal, soft-light;
}

/* HERO */

.rh-hero {
  position: relative;
  min-height: 260px;
  padding: clamp(1.75rem, 4vw, 3rem);
  overflow: hidden;
}

.rh-hero-bg {
  position: absolute;
  inset: -6%;
  background-size: cover;
  background-position: center;
  filter: saturate(1.15) contrast(1.05) brightness(0.9);
  opacity: 0.85;
}

.rh-hero-texture {
  position: absolute;
  inset: -6%;
  background-size: cover;
  background-position: center;
  opacity: 0.25;
  mix-blend-mode: soft-light;
  filter: contrast(0.9);
}

.rh-hero::before {
  content: "";
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 10% 0%, rgba(248, 250, 252, 0.16), transparent 50%),
    linear-gradient(135deg, rgba(15, 23, 42, 0.95), rgba(15, 23, 42, 1));
}

.rh-hero-inner {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(260px, 0.9fr);
  gap: clamp(1.5rem, 4vw, 3rem);
  align-items: center;
}

.rh-hero-copy {
  color: #f9fafb;
}

.rh-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.28em;
  font-size: 0.78rem;
  opacity: 0.8;
  margin-bottom: 0.75rem;
}

.rh-hero-copy h1 {
  font-size: clamp(2.2rem, 4vw, 3rem);
  letter-spacing: 0.03em;
}


.rh-storyline {
  margin-top: 0.75rem;
  max-width: 32rem;
  line-height: 1.6;
}

.rh-hero-cta {
  margin-top: 1.1rem;
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.rh-hero-button {
  border-radius: 999px;
  border: 1px solid rgba(248, 250, 252, 0.55);
  padding: 0.7rem 1.6rem;
  background: rgba(15, 23, 42, 0.78);
  color: #f9fafb;
  font-weight: 600;
  cursor: pointer;
  backdrop-filter: blur(14px);
  transition: transform 220ms ease, background 220ms ease, border-color 220ms ease;
}

.rh-hero-button:hover {
  transform: translateY(-2px);
  background: rgba(15, 23, 42, 0.9);
  border-color: rgba(96, 165, 250, 0.9);
}

.rh-nav {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-start;
  align-items: center;
  gap: 0.65rem;
  padding: 0.85rem clamp(1.5rem, 4vw, 2.8rem) 1.2rem;
  border-top: 1px solid rgba(248, 250, 252, 0.08);
  border-bottom: 1px solid rgba(15, 23, 42, 0.85);
  background: linear-gradient(180deg, rgba(2, 6, 23, 0.65), rgba(2, 6, 23, 0.9));
}

.rh-nav-link {
  flex: 0 0 auto;
  min-width: 0;
  border-radius: 999px;
  border: 1px solid rgba(248, 250, 252, 0.25);
  padding: 0.55rem 1.25rem;
  background: rgba(15, 23, 42, 0.75);
  color: #fefce8;
  font-weight: 600;
  letter-spacing: 0.03em;
  text-transform: uppercase;
  font-size: 0.78rem;
  cursor: pointer;
  transition:
    border-color 200ms ease,
    background 200ms ease,
    color 200ms ease,
    transform 200ms ease;
}

.rh-nav-link.is-active {
  border-color: rgba(248, 113, 113, 0.8);
  background: linear-gradient(135deg, rgba(248, 113, 113, 0.4), rgba(251, 191, 36, 0.25));
  color: #0f172a;
  box-shadow: 0 14px 28px rgba(15, 23, 42, 0.55);
}

.rh-nav-link.is-disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.rh-nav-link:disabled {
  pointer-events: none;
}

.rh-hero-pills {
  display: grid;
  gap: 0.55rem;
}

.rh-pill-card {
  border: none;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 0.55rem;
  border-radius: 18px;
  padding: 0.6rem 0.75rem;
  background: rgba(15, 23, 42, 0.96);
  border: 1px solid rgba(55, 65, 81, 0.9);
  box-shadow: 0 10px 25px rgba(15, 23, 42, 0.9);
  color: inherit;
  font: inherit;
  cursor: pointer;
  transform: translateY(0);
  transition:
    transform 200ms ease-out,
    box-shadow 200ms ease-out,
    border-color 200ms ease-out;
}

.rh-pill-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 14px 32px rgba(15, 23, 42, 0.95);
  border-color: rgba(96, 165, 250, 0.9);
}

.rh-pill-text {
  min-width: 0;
}

.rh-pill-label {
  font-weight: 600;
  margin-bottom: 0.15rem;
  color: rgba(248, 250, 252, 0.9);
}

.rh-pill-body {
  font-size: 0.85rem;
  line-height: 1.3;
  color: rgba(248, 250, 252, 0.8);
}

.rh-pill-thumb {
  width: 56px;
  height: 56px;
  border-radius: 14px;
  background-size: cover;
  background-position: center;
  box-shadow:
    0 8px 20px rgba(0, 0, 0, 0.85),
    0 0 0 1px rgba(15, 23, 42, 0.9);
  opacity: 0;
  transform: translateX(-80%) scale(0.78);
  transform-origin: center;
  transition:
    opacity 420ms ease-out,
    transform 420ms cubic-bezier(0.22, 0.61, 0.36, 1);
}

.rh-pill-thumb.is-revealed {
  opacity: 1;
  transform: translateX(0) scale(1);
}

/* MAIN */

.rh-main {
  padding: 0 clamp(1.75rem, 4vw, 3rem) clamp(2rem, 4vw, 3rem);
}

.rh-panel {
  border-radius: var(--radiusLg);
  padding: clamp(1.5rem, 3vw, 2.25rem);
  background:
    radial-gradient(circle at 0% 0%, rgba(15, 23, 42, 0.98), rgba(15, 23, 42, 1)),
    var(--rh-shell-texture, rgba(15, 23, 42, 1));
  border: 1px solid rgba(30, 64, 175, 0.6);
  box-shadow:
    0 18px 45px rgba(15, 23, 42, 0.95),
    0 0 0 1px rgba(15, 23, 42, 0.9);
  color: #e5e7eb;
}

.rh-home {
  margin-top: clamp(1.5rem, 3vw, 2.25rem);
}

.rh-panel-header {
  display: grid;
  gap: 0.35rem;
  margin-bottom: 0.75rem;
}

.rh-mini-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  font-size: 0.78rem;
  opacity: 0.85;
}

.rh-body {
  font-size: 0.95rem;
  line-height: 1.6;
}

.rh-muted {
  color: rgba(148, 163, 184, 0.96);
}

/* TRACK */

.rh-track {
  display: grid;
  gap: 1.75rem;
}

.rh-track-item {
  position: relative;
  padding-left: 2.5rem;
}

.rh-track-item::before {
  content: "";
  position: absolute;
  left: 1.1rem;
  top: 0.5rem;
  bottom: -1.4rem;
  width: 1px;
  background: linear-gradient(to bottom, rgba(248, 250, 252, 0.4), transparent);
}

.rh-track-item:last-child::before {
  display: none;
}

.rh-step {
  position: absolute;
  left: 0.2rem;
  top: 0;
  width: 1.8rem;
  height: 1.8rem;
  border-radius: 999px;
  border: 1px solid rgba(248, 250, 252, 0.55);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 0.78rem;
  letter-spacing: 0.14em;
}

.rh-track-head h2 {
  font-size: 1.1rem;
}

.rh-track-body {
  margin-top: 0.6rem;
  display: grid;
  grid-template-columns: minmax(0, 0.9fr) minmax(260px, 1.1fr);
  gap: 1.1rem;
  align-items: stretch;
}

.rh-track-image {
  position: relative;
  border-radius: 22px;
  background-size: cover;
  background-position: center;
  min-height: 230px;
  overflow: hidden;
  box-shadow:
    0 20px 55px rgba(0, 0, 0, 0.9),
    0 0 0 1px rgba(15, 23, 42, 0.9);
}

.rh-track-image::before {
  content: "";
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 0% 0%, rgba(248, 250, 252, 0.16), transparent 55%),
    linear-gradient(to top, rgba(15, 23, 42, 0.9), transparent 55%);
}

.rh-track-image-glow {
  position: absolute;
  inset: 0;
  mix-blend-mode: screen;
  background: radial-gradient(circle at 50% 100%, rgba(248, 113, 113, 0.45), transparent 65%);
}

.rh-track-item:nth-child(2) .rh-track-image {
  transform: translateY(4px);
}

.rh-track-item:nth-child(3) .rh-track-image {
  transform: translateY(8px);
}


.rh-detail-grid {
  margin-top: clamp(1.4rem, 3vw, 2.2rem);
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}

.rh-detail-card {
  border-radius: 18px;
  padding: 1rem 1.1rem;
  background: rgba(15, 23, 42, 0.95);
  border: 1px solid rgba(55, 65, 81, 0.85);
  position: relative;
}

.rh-addon-summary .rh-detail-header {
  margin-bottom: 0.8rem;
}

.rh-detail-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.8rem;
}

.rh-detail-title {
  display: flex;
  gap: 0.65rem;
  align-items: center;
}

.rh-detail-icon {
  font-size: 1.5rem;
}

.rh-detail-tagline {
  text-transform: uppercase;
  letter-spacing: 0.18em;
  font-size: 0.7rem;
  opacity: 0.7;
}

.rh-detail-price {
  text-align: right;
  font-weight: 600;
}

.rh-detail-price small {
  display: block;
  font-size: 0.75rem;
  opacity: 0.75;
}

.rh-detail-note {
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

.rh-detail-note:focus {
  outline: 2px solid rgba(248, 250, 252, 0.6);
  outline-offset: 2px;
}

.rh-detail-bubble {
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

.rh-detail-note:hover .rh-detail-bubble,
.rh-detail-note:focus .rh-detail-bubble {
  opacity: 1;
  transform: translateY(0.5rem);
}

.rh-detail-summary {
  margin: 0.75rem 0 0.9rem;
  font-size: 0.95rem;
  color: rgba(226, 232, 240, 0.95);
}

.rh-detail-section + .rh-detail-section {
  margin-top: 0.9rem;
}

.rh-detail-section-title {
  text-transform: uppercase;
  letter-spacing: 0.18em;
  font-size: 0.72rem;
  opacity: 0.78;
  margin-bottom: 0.35rem;
}

.rh-detail-section ul {
  margin: 0;
  padding-left: 1rem;
  display: grid;
  gap: 0.35rem;
  font-size: 0.9rem;
}

/* PLACEHOLDER */

.rh-placeholder {
  margin-top: clamp(1.5rem, 3vw, 2.25rem);
}

/* Responsive */

@media (max-width: 980px) {
  .rh-hero-inner {
    grid-template-columns: minmax(0, 1fr);
  }

  .rh-hero-pills {
    grid-template-columns: minmax(0, 1fr);
  }

  .rh-strip-grid {
    grid-template-columns: minmax(0, 1fr);
  }

  .rh-track-item {
    padding-left: 2rem;
  }

  .rh-track-body {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (max-width: 720px) {
  .rh-main {
    padding-inline: 1.25rem;
  }

  .rh-nav {
    padding-inline: 1.25rem;
  }

  .rh-nav-link {
    flex: 1 1 100%;
    text-align: center;
  }

  .rh-hero {
    padding-inline: 1.25rem;
  }

  .rh-track-item {
    padding-left: 1.8rem;
  }

  .rh-track-image {
    min-height: 200px;
  }
}
/* DROPS (Option A: Menu / Signature Drops) */

.rh-drops {
  margin-top: clamp(1.4rem, 3vw, 2.1rem);
}

.rh-drops-grid {
  margin-top: 1rem;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;
}

.rh-drop {
  position: relative;
  border-radius: 20px;
  padding: 0;
  background: rgba(15, 23, 42, 0.94);
  border: 1px solid rgba(55, 65, 81, 0.85);
  box-shadow:
    0 18px 45px rgba(0, 0, 0, 0.55),
    0 0 0 1px rgba(15, 23, 42, 0.9);
  overflow: hidden;
  transform: translateY(10px);
  opacity: 0;
  transition:
    transform 520ms cubic-bezier(0.22, 0.61, 0.36, 1) var(--rhDropDelay, 0ms),
    opacity 520ms ease var(--rhDropDelay, 0ms),
    border-color 220ms ease,
    box-shadow 220ms ease;
}

/* subtle “neon edge” wash */
.rh-drop::before {
  content: "";
  position: absolute;
  inset: -2px;
  background:
    radial-gradient(circle at 0% 0%, rgba(248, 113, 113, 0.22), transparent 55%),
    radial-gradient(circle at 100% 10%, rgba(96, 165, 250, 0.18), transparent 55%),
    linear-gradient(135deg, rgba(15, 23, 42, 0.95), rgba(15, 23, 42, 1));
  opacity: 0.55;
  filter: blur(10px);
  pointer-events: none;
}

/* inner film grain / texture support via existing shell texture */
.rh-drop::after {
  content: "";
  position: absolute;
  inset: 0;
  background: var(--rh-shell-texture, none);
  opacity: 0.18;
  mix-blend-mode: soft-light;
  pointer-events: none;
}

.rh-drop-media {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  filter: saturate(1.1) contrast(1.05) brightness(0.82);
  transform: scale(1.03);
  transition: transform 520ms cubic-bezier(0.22, 0.61, 0.36, 1), filter 520ms ease;
}

.rh-drop-media::before {
  content: "";
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 0% 0%, rgba(248, 250, 252, 0.16), transparent 58%),
    linear-gradient(to top, rgba(15, 23, 42, 0.92), rgba(15, 23, 42, 0.35) 55%, rgba(15, 23, 42, 0.92));
}

.rh-drop-media-glow {
  position: absolute;
  inset: 0;
  mix-blend-mode: screen;
  background:
    radial-gradient(circle at 45% 100%, rgba(248, 113, 113, 0.22), transparent 62%),
    radial-gradient(circle at 90% 20%, rgba(96, 165, 250, 0.18), transparent 58%);
}

.rh-drop-content {
  position: relative;
  z-index: 1;
  padding: 1.05rem 1.1rem 1.15rem;
}

.rh-drop-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem;
}

.rh-drop-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.35rem 0.6rem;
  border-radius: 999px;
  border: 1px solid rgba(248, 250, 252, 0.22);
  background: rgba(15, 23, 42, 0.65);
  text-transform: uppercase;
  letter-spacing: 0.18em;
  font-size: 0.66rem;
  color: rgba(248, 250, 252, 0.9);
}

.rh-drop-index {
  text-transform: uppercase;
  letter-spacing: 0.16em;
  font-size: 0.72rem;
  opacity: 0.8;
}

.rh-drop-title {
  margin-top: 0.7rem;
  font-size: 1.05rem;
  letter-spacing: 0.02em;
}

.rh-drop-body {
  margin-top: 0.55rem;
  color: rgba(226, 232, 240, 0.92);
}

/* reveal: use existing page feel without adding new JS */
.rh-home .rh-drop {
  opacity: 1;
  transform: translateY(0);
}

@media (hover: hover) {
  .rh-drop:hover {
    transform: translateY(-3px);
    border-color: rgba(96, 165, 250, 0.85);
    box-shadow:
      0 22px 60px rgba(0, 0, 0, 0.6),
      0 0 0 1px rgba(96, 165, 250, 0.22);
  }

  .rh-drop:hover .rh-drop-media {
    transform: scale(1.12);
    filter: saturate(1.15) contrast(1.08) brightness(0.86);
  }
}

@media (max-width: 980px) {
  .rh-drops-grid {
    grid-template-columns: minmax(0, 1fr);
  }
}

</style>
