<script setup>
import { computed, nextTick, ref, onMounted, onUnmounted } from 'vue';
import PricingPanel from '../components/PricingPanel.vue';
import { buildHeroCtas } from './utils/buildHeroCtas';

const props = defineProps({
  navItems: {
    type: Array,
    default: () => []
  },
  activePage: {
    type: String,
    default: ''
  },
  templateId: {
    type: String,
    default: ''
  },
  brand: {
    type: Object,
    default: () => ({})
  },
  brandName: {
    type: String,
    default: ''
  },
  brandTagline: {
    type: String,
    default: ''
  },
  brandStoryline: {
    type: String,
    default: ''
  },
  copy: {
    type: Object,
    default: () => ({})
  },
  pricingPackages: { type: Array, default: () => [] },
  addons: { type: Array, default: () => [] },
  maintenance: { type: Array, default: () => [] }
});

const heroEl = ref(null);
const tileEls = ref([]);
const activeTileIndex = ref(0);
const tileParallax = ref([]);
const mainEl = ref(null);

let tileObserver = null;

const setTileRef = (el, index) => {
  if (!el) return;
  tileEls.value[index] = el;
};

const emit = defineEmits(['navigate', 'contact']);

const handleNav = (item) => {
  if (item.disabled) return;
  emit('navigate', item.id);
};

const handleScroll = () => {
  if (!heroEl.value) return;
  const viewport = window.innerHeight || document.documentElement.clientHeight;
  if (!viewport) return;

  tileEls.value.forEach((el, index) => {
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const center = rect.top + rect.height / 2;
    const distanceFromCenter = (center - viewport / 2) / viewport; // roughly -1..1
    let value = -distanceFromCenter;
    if (value > 1) value = 1;
    if (value < -1) value = -1;
    tileParallax.value[index] = value;
  });
};

onMounted(() => {
  if ('IntersectionObserver' in window) {
    tileObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const index = tileEls.value.indexOf(entry.target);
            if (index !== -1) {
              activeTileIndex.value = index;
            }
          }
        });
      },
      {
        root: null,
        threshold: 0.45
      }
    );

    tileEls.value.forEach((el) => {
      if (el) tileObserver.observe(el);
    });
  }

  window.addEventListener('scroll', handleScroll, { passive: true });
});

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll);
  if (tileObserver) {
    tileEls.value.forEach((el) => {
      if (el) tileObserver.unobserve(el);
    });
    tileObserver.disconnect();
    tileObserver = null;
  }
});

const displayBrandName = computed(() => props.brand?.name || props.brandName);
const displayTagline = computed(() => props.brand?.tagline || props.brandTagline);
const displayStoryline = computed(
  () => props.brand?.description || props.brandStoryline
);
const heroCtas = computed(() => buildHeroCtas({ brand: props.brand, copy: props.copy }));
const ritualScenes = computed(() => {
  const scenes =
    props.brand?.assets?.ritualScenes ??
    props.brand?.assets?.settings ??
    [];
  if (scenes.length) {
    return scenes;
  }
  const elements = props.brand?.assets?.elements ?? [];
  if (elements.length) {
    return elements;
  }
  return [];
});
const defaultGlassScenes = [
  {
    tag: 'Sequence 01',
    label: 'Glass atelier',
    body: 'Sculpted panes hovering over charcoal plinths.'
  },
  {
    tag: 'Sequence 02',
    label: 'Light lab',
    body: 'Neon grids refracting off mirrored corridors.'
  },
  {
    tag: 'Sequence 03',
    label: 'Gallery floor',
    body: 'Suspended shelves and curated specimens.'
  },
  {
    tag: 'Sequence 04',
    label: 'Night study',
    body: 'After-hours tastings beneath violet light.'
  }
];
const galleryScenes = computed(() => {
  const scenes = ritualScenes.value;
  if (scenes.length) {
    return scenes.slice(0, 4);
  }
  return defaultGlassScenes;
});

const defaultFeatureDrops = [
  {
    tag: 'Detail 01',
    label: 'Refraction study',
    body: 'Micro-etching and prism cuts tuned for slow light.'
  },
  {
    tag: 'Detail 02',
    label: 'Mirror corridor',
    body: 'Layered glass fins that stretch the grid into depth.'
  },
  {
    tag: 'Detail 03',
    label: 'Cold neon wash',
    body: 'Soft gradients that keep the surfaces weightless.'
  },
  {
    tag: 'Detail 04',
    label: 'Gallery cadence',
    body: 'A deliberate sequence—pause, pivot, reveal.'
  },
  {
    tag: 'Detail 05',
    label: 'Specimen shelf',
    body: 'Curated objects staged as if floating in air.'
  },
  {
    tag: 'Detail 06',
    label: 'Night clarity',
    body: 'Sharper contrast, quieter noise, cleaner edges.'
  }
];

const featureDrops = computed(() => {
  const assets = props.brand?.assets ?? {};
  const source =
    assets.elements?.length
      ? assets.elements
      : assets.settings?.length
        ? assets.settings
        : assets.ritualScenes?.length
          ? assets.ritualScenes
          : [];

  if (source.length) {
    return source.slice(0, 6).map((item, index) => {
      const normalized = typeof item === 'string' ? { label: item } : item;
      return {
        tag: normalized.tag || defaultFeatureDrops[index]?.tag || `Detail 0${index + 1}`,
        label: normalized.label || defaultFeatureDrops[index]?.label || `Detail 0${index + 1}`,
        body:
          normalized.description ||
          normalized.body ||
          defaultFeatureDrops[index]?.body ||
          copy.home?.sceneFallback,
        image: normalized.image
      };
    });
  }

  return defaultFeatureDrops;
});
const heroTileFallbackImages = computed(() => {
  const assets = props.brand?.assets ?? {};
  const disallow = new Set(
    [
      assets.hero,
      assets.heroFeature,
      assets.secondary,
      assets.pricingFeature,
      assets.pricingHero
    ].filter(Boolean)
  );
  const usedImages = new Set();
  const fallback = [];

  const pushImage = (image) => {
    if (!image || disallow.has(image) || usedImages.has(image)) return;
    usedImages.add(image);
    fallback.push(image);
  };

  const pushFromCollection = (collection = []) => {
    collection.forEach((item) => {
      const image = typeof item === 'string' ? item : item?.image;
      if (!image) return;
      pushImage(image);
    });
  };

  pushFromCollection(assets.elements);
  pushFromCollection(assets.settings);
  pushFromCollection(assets.ritualScenes);
  pushFromCollection(assets.gallery);
  pushFromCollection(assets.pricingShots);

  return fallback;
});

const heroTileButtons = computed(() => {
  const fallbacks = heroTileFallbackImages.value;
  let fallbackIndex = 0;

  return heroCtas.value.map((cta) => {
    if (cta.image) {
      return cta;
    }

    const fallbackImage = fallbacks[fallbackIndex++];
    if (!fallbackImage) {
      return cta;
    }

    return {
      ...cta,
      image: fallbackImage
    };
  });
});

const featureDropsWithImages = computed(() => {
  const fallbacks = heroTileFallbackImages.value;
  let fallbackIndex = 0;

  return featureDrops.value.map((drop) => {
    if (drop?.image) return drop;
    const fallbackImage = fallbacks[fallbackIndex++];
    if (!fallbackImage) return drop;
    return { ...drop, image: fallbackImage };
  });
});

const handlePricingToggle = async () => {
  const targetPage = props.activePage === 'pricing' ? 'home' : 'pricing';
  emit('navigate', targetPage);
  await nextTick();
  requestAnimationFrame(() => {
    if (typeof window === 'undefined') return;
    if (mainEl.value) {
      mainEl.value.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });
};

const handleContactClick = () => {
  emit('contact');
};
</script>

<template>
  <section
    class="template-shell glass-grid"
    :data-template="templateId"
    :class="`tile-${activeTileIndex}`"
  >
    <!-- HERO: glassmorphism floating tiles over neon gradient wash -->
    <header class="kg-hero">
      <div class="kg-hero-bg">
        <!-- TODO: gradient neon wash, optional subtle noise texture -->
      </div>

      <div class="kg-hero-content">
        <div class="kg-hero-text">
          <p class="kg-eyebrow">{{ displayBrandName }}</p>
          <h1 class="kg-title">{{ displayTagline }}</h1>
          <p class="kg-story">
            {{ displayStoryline }}
          </p>

          <h2 class="kg-subtitle">
            {{ copy.home?.gridTitle || 'Curated Glass Series' }}
          </h2>
          <p class="kg-lead">
            {{ copy.home?.gridSubtitle || 'A refined selection of pieces showcasing light, texture, and spatial clarity.' }}
          </p>

          <div class="kg-cta">
            <button type="button" class="kg-hero-button" @click="handleContactClick">
              {{ copy.cta?.button || 'Book a stay' }}
            </button>
          </div>

        </div>

        <div class="kg-hero-tiles" ref="heroEl">
          <!-- 3 floating glass tiles wired for scroll + hover -->
          <button
            v-for="(cta, index) in heroTileButtons"
            :key="cta.id || index"
            class="kg-tile"
            :class="[
              `kg-tile--slot-${index}`,
              { 'kg-tile--offset-front': index === 1 },
              { 'kg-tile--offset-back': index === 2 },
              { 'kg-tile--active': activeTileIndex === index }
            ]"
            :ref="(el) => setTileRef(el, index)"
            :style="{ '--kgScroll': tileParallax[index] ?? 0 }"
            type="button"
            @click="handlePricingToggle"
          >
            <div
              v-if="cta.image"
              class="kg-tile-thumb"
              :style="{ backgroundImage: `url(${cta.image})` }"
            />
            <div class="kg-tile-pill">
              <p class="kg-tile-label">
                {{ cta.label }}
              </p>
              <p class="kg-tile-desc">
                {{ cta.description || copy.home?.sceneFallback }}
              </p>
            </div>
          </button>
        </div>
      </div>
    </header>

    <!-- NAV: sleek pill nav under hero -->
    <nav class="kg-nav">
      <button
        v-for="item in navItems"
        :key="item.id"
        :class="[
          'kg-nav-link',
          { 'kg-nav-link--active': activePage === item.id, 'kg-nav-link--disabled': item.disabled }
        ]"
        type="button"
        @click="handleNav(item)"
      >
        {{ item.label }}
      </button>
    </nav>

    <!-- BODY: product grid / content via slot -->
    <main class="kg-body" ref="mainEl">
      <template v-if="activePage === 'home'">
        <div class="kg-body-inner">
          <div class="kg-panel-grid">
            <article
              v-for="(scene, index) in galleryScenes"
              :key="scene.id || index"
              class="kg-panel"
            >
              <div
                class="kg-panel-image"
                :style="scene.image ? { backgroundImage: `url(${scene.image})` } : undefined"
              >
                <div class="kg-panel-image-overlay" />
              </div>
              <div class="kg-panel-copy">
                <p class="kg-panel-label">
                  {{ scene.label || copy.home?.galleryFallback || defaultGlassScenes[index]?.label }}
                </p>
                <p class="kg-panel-body">
                  {{
                    scene.description ||
                      copy.home?.sceneFallback ||
                      defaultGlassScenes[index]?.body
                  }}
                </p>
              </div>
            </article>
          </div>
          <section class="kg-feature-strip">
            <header class="kg-feature-header">
              <p class="kg-feature-eyebrow">{{ copy.home?.featureEyebrow || 'Details in Motion' }}</p>
              <h2 class="kg-feature-title">{{ copy.home?.featureTitle || 'A third act of glass, light, and cadence.' }}</h2>
              <p class="kg-feature-lede">
                {{
                  copy.home?.featureSubtitle ||
                    'Short, sharp moments that make the grid feel alive—hover to widen the frame.'
                }}
              </p>
            </header>

            <div class="kg-feature-rail">
              <article
                v-for="(drop, index) in featureDropsWithImages"
                :key="drop.id || index"
                class="kg-feature-card"
                :style="{ '--kgFeatureDelay': index * 70 + 'ms' }"
              >
                <div
                  class="kg-feature-media"
                  :style="drop.image ? { backgroundImage: `url(${drop.image})` } : undefined"
                  aria-hidden="true"
                >
                  <div class="kg-feature-media-glow" />
                </div>
                <div class="kg-feature-copy">
                  <p class="kg-feature-tag">{{ drop.tag || `Detail 0${index + 1}` }}</p>
                  <p class="kg-feature-label">{{ drop.label }}</p>
                  <p class="kg-feature-body">{{ drop.body }}</p>
                </div>
              </article>
            </div>
          </section>
          <slot />
        </div>
      </template>

      <article v-else-if="activePage === 'pricing'" class="kg-pricing-panel">
        <PricingPanel
          :brand="brand"
          :copy="copy.pricing"
          :pricing-packages="pricingPackages"
          :addons="addons"
          :maintenance="maintenance"
          @back="handlePricingToggle"
        />
      </article>

      <article v-else class="kg-body-inner">
        <slot />
      </article>
    </main>
  </section>
</template>

<style scoped>
.template-shell {
  border-radius: var(--radiusLg);
  overflow: hidden;
  border: 1px solid color-mix(in srgb, var(--primary) 45%, transparent);
  background:
    radial-gradient(circle at 0% 0%, var(--kgAmbient, color-mix(in srgb, var(--accent) 20%, transparent)), transparent 55%),
    radial-gradient(circle at 100% 0%, color-mix(in srgb, var(--primary) 20%, transparent), transparent 55%),
    var(--surfaceMuted);
  transition: background 420ms cubic-bezier(0.22, 0.61, 0.36, 1);
}

.glass-grid {
  --kgAmbient: color-mix(in srgb, var(--accent) 20%, transparent);
}

.glass-grid.tile-0 {
  /* Primary hero tile: slightly cooler accent */
  --kgAmbient: color-mix(in srgb, var(--primary) 32%, transparent);
}

.glass-grid.tile-1 {
  /* Secondary offset tile: warmer accent */
  --kgAmbient: color-mix(in srgb, var(--accent) 40%, transparent);
}

.glass-grid.tile-2 {
  /* Third tile: neutral, slightly desaturated glass tone */
  --kgAmbient: color-mix(in srgb, var(--accent) 18%, var(--primary) 18%);
}

/* HERO */

.kg-hero {
  position: relative;
  padding: clamp(1.2rem, 3vw, 2.2rem) clamp(1.8rem, 4vw, 2.8rem);
}

.kg-hero-bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    radial-gradient(circle at 10% 0%, color-mix(in srgb, var(--kgAmbient, rgba(236, 72, 153, 0.5)) 85%, transparent), transparent 55%),
    radial-gradient(circle at 90% 0%, rgba(59, 130, 246, 0.45), transparent 55%),
    linear-gradient(145deg, #020617, #020617);
  opacity: 0.85;
  /* TODO: optional noise overlay */
}

.kg-hero-content {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(260px, 0.9fr);
  gap: clamp(2rem, 4vw, 3rem);
  align-items: center;
}

/* Text */

.kg-hero-text {
  color: rgba(248, 250, 252, 0.95);
}

.kg-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.28em;
  font-size: 0.7rem;
  opacity: 0.8;
  margin-bottom: 0.5rem;
}

.kg-title {
  font-size: clamp(2.2rem, 3.6vw, 3rem);
  letter-spacing: 0.08em;
}

.kg-story {
  margin-top: 0.85rem;
  max-width: 32rem;
  line-height: 1.7;
  color: rgba(248, 250, 252, 0.85);
}

.kg-subtitle {
  margin-top: 1.4rem;
  font-size: 1.3rem;
  font-weight: 600;
  letter-spacing: 0.04em;
  color: rgba(248, 250, 252, 0.95);
}

.kg-lead {
  margin-top: 0.4rem;
  max-width: 30rem;
  line-height: 1.6;
  color: rgba(248, 250, 252, 0.85);
}

.kg-cta {
  margin-top: 1.3rem;
}

.kg-hero-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.35rem;
  border-radius: 999px;
  padding: 0.75rem 1.75rem;
  border: 1px solid color-mix(in srgb, var(--primaryForeground) 60%, transparent);
  background: linear-gradient(
      135deg,
      color-mix(in srgb, var(--primaryForeground) 10%, rgba(15, 23, 42, 0.5)),
      rgba(15, 23, 42, 0.3)
    ),
    rgba(15, 23, 42, 0.25);
  color: rgba(248, 250, 252, 0.95);
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  font-size: 0.85rem;
  cursor: pointer;
  backdrop-filter: blur(18px);
  box-shadow:
    0 10px 26px rgba(0, 0, 0, 0.45),
    0 0 0 1px rgba(255, 255, 255, 0.08);
  transition:
    border-color 200ms ease,
    background 200ms ease,
    transform 200ms ease,
    box-shadow 200ms ease;
}

.kg-hero-button:hover {
  border-color: color-mix(in srgb, var(--primary) 65%, rgba(248, 250, 252, 0.6));
  background: linear-gradient(
      135deg,
      color-mix(in srgb, var(--primary) 30%, rgba(15, 23, 42, 0.5)),
      rgba(15, 23, 42, 0.45)
    ),
    rgba(15, 23, 42, 0.45);
  transform: translateY(-1px);
  box-shadow:
    0 16px 35px rgba(0, 0, 0, 0.55),
    0 0 0 1px rgba(255, 255, 255, 0.12);
}

/* Tiles */

.kg-hero-tiles {
  position: relative;
  min-height: 220px;
  display: grid;
  place-items: center;
  perspective: 1200px;
}

.kg-tile {
  --kg-hover-dx: 12px;
  --kg-hover-dy: -12px;
  --kg-hover-scale: 1.08;
  width: 210px;
  height: 260px;
  border-radius: 1.4rem;
  background:
    radial-gradient(circle at 0% 0%, rgba(248, 250, 252, 0.18), transparent 60%),
    rgba(15, 23, 42, 0.45);
  box-shadow:
    0 18px 45px rgba(0, 0, 0, 0.8),
    0 0 0 1px rgba(248, 250, 252, 0.08);
  backdrop-filter: blur(26px);
  transform-origin: center center;
  transform:
    translateY(calc(var(--kgScroll, 0) * -8px))
    translateX(calc(var(--kgScroll, 0) * 4px))
    rotateX(calc(var(--kgScroll, 0) * 4deg));
  transition:
    transform 420ms cubic-bezier(0.22, 0.61, 0.36, 1),
    box-shadow 420ms ease-out;
  position: relative;
  overflow: hidden;
  border: none;
  padding: 0;
  background-clip: padding-box;
  color: inherit;
  font: inherit;
  text-align: left;
  cursor: pointer;
}
.kg-tile-thumb {
  position: absolute;
  top: 1rem;
  left: 50%;
  transform: translateX(-50%);
  width: 72px;
  height: 72px;
  border-radius: 16px;
  background-size: cover;
  background-position: center;
  box-shadow:
    0 8px 20px rgba(0, 0, 0, 0.65),
    0 0 0 1px rgba(248, 250, 252, 0.2);
}
.kg-tile-pill {
  position: absolute;
  inset: auto 1rem 1.1rem;
  color: #f8fafc;
  text-shadow: 0 3px 12px rgba(2, 6, 23, 0.6);
}
.kg-tile-label {
  font-size: 0.98rem;
  font-weight: 600;
  letter-spacing: 0.04em;
}
.kg-tile-desc {
  margin-top: 0.25rem;
  font-size: 0.9rem;
  opacity: 0.85;
  line-height: 1.4;
}

.kg-tile--offset-front {
  position: absolute;
  right: 0;
  bottom: -12px;
  transform: translateX(18%) translateY(8%);
  opacity: 0.85;
}

.kg-tile--offset-back {
  position: absolute;
  left: -6%;
  top: -10%;
  transform: translateX(-8%) translateY(-4%) scale(0.92);
  opacity: 0.6;
}

.kg-tile--active {
  box-shadow:
    0 26px 70px rgba(0, 0, 0, 0.9),
    0 0 0 1px rgba(248, 250, 252, 0.18);
}

.kg-tile--slot-0 {
  --kg-hover-dx: 22px;
  --kg-hover-dy: -16px;
  --kg-hover-scale: 1.12;
}
.kg-tile--slot-1 {
  --kg-hover-dx: 8px;
  --kg-hover-dy: -6px;
  --kg-hover-scale: 1.08;
}
.kg-tile--slot-2 {
  --kg-hover-dx: -24px;
  --kg-hover-dy: 22px;
  --kg-hover-scale: 1.12;
}
.kg-tile:hover {
  background: rgba(15, 23, 42, 0.85);
  box-shadow:
    0 32px 76px rgba(0, 0, 0, 0.9),
    0 0 0 1px rgba(248, 250, 252, 0.24);
  transform:
    translateY(calc(var(--kgScroll, 0) * -8px + var(--kg-hover-dy)))
    translateX(calc(var(--kgScroll, 0) * 4px + var(--kg-hover-dx)))
    rotateX(calc(var(--kgScroll, 0) * 4deg))
    scale(var(--kg-hover-scale));
}

/* NAV */

.kg-nav {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  padding: 0.9rem clamp(2.1rem, 5vw, 3.1rem);
  border-top: 1px solid color-mix(in srgb, var(--border), rgba(255, 255, 255, 0.1));
  background: color-mix(in srgb, var(--surface), rgba(0, 0, 0, 0.3));
}

.kg-nav-link {
  border-radius: 999px;
  border: 1px solid color-mix(in srgb, var(--border), rgba(255, 255, 255, 0.14));
  padding: 0.35rem 1.2rem;
  background: transparent;
  color: var(--text);
  cursor: pointer;
  font-size: 0.9rem;
}

.kg-nav-link--active {
  border-color: var(--primary);
  background: color-mix(in srgb, var(--primary) 24%, transparent);
  color: var(--primaryForeground);
}

.kg-nav-link--disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

/* BODY */

.kg-body {
  background: var(--surface);
}

/* Feature strip (3rd section) */

.kg-feature-strip {
  margin-top: 1.2rem;
  padding: 2.2rem 0 0;
  border-top: 1px solid color-mix(in srgb, var(--border), rgba(255, 255, 255, 0.12));
}

.kg-feature-header {
  padding: 0 clamp(0.2rem, 1vw, 0.6rem) 1.2rem;
  color: var(--primaryForeground);
}

.kg-feature-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.28em;
  font-size: 0.7rem;
  opacity: 0.78;
}

.kg-feature-title {
  margin-top: 0.6rem;
  font-size: clamp(1.35rem, 2.3vw, 1.75rem);
  letter-spacing: 0.04em;
}

.kg-feature-lede {
  margin-top: 0.55rem;
  max-width: 44rem;
  line-height: 1.65;
  color: color-mix(in srgb, var(--primaryForeground) 76%, rgba(255, 255, 255, 0.44));
}

.kg-feature-rail {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(260px, 340px);
  gap: 1.15rem;
  overflow-x: auto;
  padding: 0.8rem 0 2.1rem;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
}

.kg-feature-card {
  scroll-snap-align: start;
  border-radius: 1.35rem;
  background: rgba(15, 23, 42, 0.42);
  box-shadow:
    0 22px 60px rgba(0, 0, 0, 0.7),
    0 0 0 1px rgba(248, 250, 252, 0.12);
  backdrop-filter: blur(26px);
  overflow: hidden;
  transform: translateY(10px);
  opacity: 0.96;
  transition:
    transform 420ms cubic-bezier(0.22, 0.61, 0.36, 1),
    box-shadow 420ms ease-out;
}

.kg-feature-media {
  height: 190px;
  background-size: cover;
  background-position: center;
  position: relative;
  transform: scale(1.06);
  transition: transform 520ms cubic-bezier(0.22, 0.61, 0.36, 1);
}

.kg-feature-media-glow {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 20% 20%, rgba(248, 250, 252, 0.16), transparent 55%),
    linear-gradient(180deg, rgba(2, 6, 23, 0.18), rgba(2, 6, 23, 0.86));
}

.kg-feature-copy {
  padding: 1.1rem 1.2rem 1.25rem;
  color: var(--primaryForeground);
}

.kg-feature-tag {
  text-transform: uppercase;
  letter-spacing: 0.22em;
  font-size: 0.68rem;
  opacity: 0.78;
}

.kg-feature-label {
  margin-top: 0.55rem;
  font-size: 1rem;
  font-weight: 600;
  letter-spacing: 0.04em;
}

.kg-feature-body {
  margin-top: 0.4rem;
  line-height: 1.6;
  color: color-mix(in srgb, var(--primaryForeground) 78%, rgba(248, 250, 252, 0.62));
}

@media (hover: hover) {
  .kg-feature-card:hover {
    transform: translateY(-6px) scale(1.02);
    box-shadow:
      0 34px 90px rgba(0, 0, 0, 0.82),
      0 0 0 1px rgba(248, 250, 252, 0.18);
  }

  .kg-feature-card:hover .kg-feature-media {
    transform: scale(1);
  }
}

.kg-pricing-panel {
  padding: clamp(1.5rem, 3vw, 2.5rem);
  border-radius: var(--radiusLg);
  border: 1px solid color-mix(in srgb, var(--border), rgba(255, 255, 255, 0.15));
  background: rgba(15, 23, 42, 0.82);
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.45);
}

.kg-body-inner {
  padding: clamp(1.4rem, 3vw, 2.1rem);
}

.kg-panel-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 2.4rem;
  margin-bottom: 2.5rem;
}

.kg-panel {
  min-height: 420px;
  border-radius: 1.6rem;
  background: rgba(15, 23, 42, 0.45);
  box-shadow:
    0 28px 75px rgba(0, 0, 0, 0.75),
    0 0 0 1px rgba(248, 250, 252, 0.12);
  backdrop-filter: blur(28px);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  transition: transform 420ms cubic-bezier(0.22, 0.61, 0.36, 1),
              box-shadow 420ms ease-out;
}

.kg-panel:hover {
  transform: translateY(-6px) scale(1.02);
  box-shadow:
    0 38px 105px rgba(0, 0, 0, 0.85),
    0 0 0 1px rgba(248, 250, 252, 0.18);
}
.kg-panel-image {
  flex: 1;
  min-height: 240px;
  background-size: cover;
  background-position: center;
  position: relative;
}
.kg-panel-image-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, rgba(2, 6, 23, 0.2), rgba(2, 6, 23, 0.85));
}
.kg-panel-copy {
  padding: 1.4rem 1.6rem 1.6rem;
  color: var(--primaryForeground);
}
.kg-panel-label {
  font-size: 1.1rem;
  font-weight: 600;
  letter-spacing: 0.05em;
}
.kg-panel-body {
  margin-top: 0.35rem;
  line-height: 1.6;
  color: color-mix(in srgb, var(--primaryForeground) 80%, rgba(248, 250, 252, 0.65));
}

/* RESPONSIVE */

@media (max-width: 880px) {
  .kg-hero {
    padding: 2.1rem 1.6rem 2rem;
  }

  .kg-hero-content {
    grid-template-columns: minmax(0, 1fr);
    gap: 1.8rem;
  }

  .kg-hero-tiles {
    min-height: 180px;
  }

  .kg-nav {
    padding-inline: 1.4rem;
  }

  .kg-body-inner {
    padding-inline: 1.2rem;
  }

  .kg-panel-grid {
    grid-template-columns: minmax(0, 1fr);
  }

  .kg-feature-rail {
    grid-auto-columns: minmax(240px, 82vw);
    padding-bottom: 1.6rem;
  }
}
</style>
