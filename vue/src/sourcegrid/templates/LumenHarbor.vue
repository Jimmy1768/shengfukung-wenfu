<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue';
import PricingPanel from '../components/PricingPanel.vue';
import { buildHeroCtas } from './utils/buildHeroCtas';
import { getEditorialAssetsForBrand } from './editorialAssets';
import applyBrandCopy from './utils/applyBrandCopy';

const props = defineProps({
  navItems: { type: Array, default: () => [] },
  activePage: { type: String, default: '' },
  templateId: { type: String, default: '' },
  brand: { type: Object, required: true },
  brandCopy: { type: Object, default: () => ({}) },
  copy: { type: Object, required: true },
  pricingPackages: { type: Array, default: () => [] },
  addons: { type: Array, default: () => [] },
  maintenance: { type: Array, default: () => [] }
});

const emit = defineEmits(['navigate', 'contact']);

const resolvedBrand = computed(() => applyBrandCopy(props.brand, props.brandCopy));

const editorialAssets = computed(() => getEditorialAssetsForBrand(props.brand?.id));

const collagePieces = computed(() => {
  const assets = editorialAssets.value;
  return [
    {
      key: 'anchor',
      image: assets.collageAnchor,
      label: props.copy?.home?.galleryHeadline || resolvedBrand.value?.name || 'Signature stay'
    },
    {
      key: 'offset',
      image: assets.collageOffset,
      label: props.copy?.home?.galleryFallback || 'Terrace light'
    },
    {
      key: 'detail',
      image: assets.collageDetail,
      label: props.copy?.home?.sceneFallback || 'Quiet ritual'
    },
    {
      key: 'atmosphere',
      image: assets.collageAtmosphere,
      label: props.copy?.home?.galleryEyebrow || 'Atmosphere'
    }
  ];
});

const heroImage = computed(
  () =>
    resolvedBrand.value?.assets?.hero ||
    resolvedBrand.value?.assets?.heroFeature ||
    resolvedBrand.value?.assets?.secondary ||
    resolvedBrand.value?.assets?.pricingHero
);

const heroParallax = ref(0);
const heroShellStyle = computed(() => ({
  '--lhHeroShift': `${heroParallax.value}px`
}));
const heroImageStyle = computed(() => {
  const style = {};
  if (heroImage.value) {
    style.backgroundImage = `url(${heroImage.value})`;
  }
  return style;
});
const heroAmbientStyle = computed(() => ({
  backgroundImage: `url(${editorialAssets.value.ambientHorizon})`
}));

const heroRef = ref(null);
const isMounted = ref(false);

const heroHighlights = computed(() => {
  const settings = resolvedBrand.value?.assets?.settings ?? [];
  if (settings.length) return settings.slice(0, 2);

  const elements = resolvedBrand.value?.assets?.elements ?? [];
  if (elements.length) return elements.slice(0, 2);

  return [
    {
      label: props.copy?.home?.galleryFallback || 'Concierge welcome',
      description:
        props.copy?.home?.sceneFallback ||
        'Private host greeting, hot towel service, and seamless check-in rituals.'
    },
    {
      label: props.copy?.home?.step2Title || 'Wellness rituals',
      description:
        props.copy?.home?.step2Body ||
        'Evening spa bookings, in-suite treatments, and chef-led tasting menus.'
    }
  ];
});

const imagePool = computed(() => {
  const images = [];

  const ritualScenes = resolvedBrand.value?.assets?.ritualScenes ?? [];
  ritualScenes.forEach((scene) => {
    if (scene?.image) images.push(scene.image);
  });

  const brandedGallery = resolvedBrand.value?.assets?.gallery ?? [];
  brandedGallery.forEach((item) => {
    if (!item) return;
    if (typeof item === 'string') {
      images.push(item);
      return;
    }
    if (item?.image) images.push(item.image);
  });

  if (!images.length && heroImage.value) images.push(heroImage.value);

  return images;
});

const pickImage = (index) => {
  const pool = imagePool.value;
  if (!pool.length) return undefined;
  return pool[index % pool.length];
};

const suiteCards = computed(() => {
  const settings = resolvedBrand.value?.assets?.settings ?? [];
  if (settings.length) {
    return settings.slice(0, 3).map((setting, index) => ({
      ...setting,
      image: setting.image || pickImage(index)
    }));
  }

  const scenes = resolvedBrand.value?.assets?.ritualScenes ?? [];
  if (scenes.length) {
    return scenes.slice(0, 3).map((scene, index) => ({
      ...scene,
      image: scene.image || pickImage(index)
    }));
  }

  return [
    {
      label: 'Skyline Suite',
      description: 'Corner suites with floor-to-ceiling glazing and curated vinyl bar carts.',
      image: pickImage(0)
    },
    {
      label: 'Garden Spa Loft',
      description: 'Two-level loft with private onsen, cedar tubs, and terrace daybeds.',
      image: pickImage(1)
    },
    {
      label: 'Townhouse Residence',
      description: 'Butler-serviced residence with dining salon, study, and chef kitchen.',
      image: pickImage(2)
    }
  ];
});

const ritualCards = computed(() => {
  const elements = resolvedBrand.value?.assets?.elements ?? [];
  if (elements.length) {
    return elements.slice(0, 4).map((element, index) => ({
      ...element,
      image: element.image || pickImage(index + 3)
    }));
  }

  const scenes = resolvedBrand.value?.assets?.ritualScenes ?? [];
  if (scenes.length) {
    return scenes.slice(0, 4).map((scene, index) => ({
      ...scene,
      image: scene.image || pickImage(index + 3)
    }));
  }

  return [
    {
      label: 'Tea Atelier',
      description: 'Daily tea flights with seasonal botanicals, incense, and vinyl playlists.',
      image: pickImage(3)
    },
    {
      label: 'Night Swim',
      description: 'Candlelit plunge pool with midnight swim valet and champagne service.',
      image: pickImage(4)
    },
    {
      label: 'Salon Supper',
      description: 'Six-course tasting at the chef’s counter with curated wine pairings.',
      image: pickImage(5)
    },
    {
      label: 'Wellness Ritual',
      description: 'In-suite spa therapists, sound baths, and bespoke aromatherapy turndown.',
      image: pickImage(6)
    }
  ];
});

const mainEl = ref(null);

const splitRefs = ref([]);
const visibleSplit = ref([]);

const suiteRefs = ref([]);
const ritualRefs = ref([]);
const visibleSuites = ref([]);
const visibleRituals = ref([]);
let revealObserver = null;

// Ritual stage (Option 1: accordion + hero image)
const activeRitualIndex = ref(0);

const activeRitual = computed(() => {
  const rituals = ritualCards.value || [];
  if (!rituals.length) return null;
  const index = Math.min(Math.max(activeRitualIndex.value, 0), rituals.length - 1);
  return rituals[index] || rituals[0];
});

const setActiveRitualIndex = (index) => {
  if (typeof index !== 'number') return;
  const total = ritualCards.value?.length ?? 0;
  if (!total) return;
  activeRitualIndex.value = Math.min(Math.max(index, 0), total - 1);
};

// Cinematic performance + accessibility
const prefersReducedMotion =
  typeof window !== 'undefined' &&
  window.matchMedia &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

let scrollTicking = false;

const handleContactClick = () => {
  emit('contact');
};

const handleNav = (item) => {
  if (item.disabled) return;
  emit('navigate', item.id);
};

const setSuiteRef = (el, index) => {
  if (el) suiteRefs.value[index] = el;
};
const setRitualRef = (el, index) => {
  if (el) ritualRefs.value[index] = el;
};
const setSplitRef = (el, index) => {
  if (el) splitRefs.value[index] = el;
};

const handleScroll = () => {
  if (prefersReducedMotion) return;
  if (scrollTicking) return;
  scrollTicking = true;

  requestAnimationFrame(() => {
    if (heroRef.value) {
      const rect = heroRef.value.getBoundingClientRect();
      const viewport =
        typeof window !== 'undefined'
          ? window.innerHeight ||
            (typeof document !== 'undefined' ? document.documentElement.clientHeight : 0)
          : 0;
      const triggerPoint = viewport * 0.55;
      const distance = rect.height + triggerPoint || 1;
      const raw = (triggerPoint - rect.top) / distance;
      const normalized = Math.min(Math.max(raw, 0), 1.35);
      heroParallax.value = normalized * -240;
    }

    scrollTicking = false;
  });
};

const applyVisibility = (entries) => {
  entries.forEach((entry) => {
    if (!entry.isIntersecting) return;
    const updateFlag = (refs, flags) => {
      const idx = refs.value.indexOf(entry.target);
      if (idx !== -1) {
        flags.value[idx] = true;
        flags.value = [...flags.value];
        revealObserver?.unobserve(entry.target);
        return true;
      }
      return false;
    };

    if (updateFlag(splitRefs, visibleSplit)) return;
    if (updateFlag(suiteRefs, visibleSuites)) return;
    updateFlag(ritualRefs, visibleRituals);
  });
};

const setupRevealObserver = () => {
  if (revealObserver) {
    revealObserver.disconnect();
    revealObserver = null;
  }
  if (typeof window === 'undefined' || !('IntersectionObserver' in window)) return;
  revealObserver = new IntersectionObserver(applyVisibility, {
    threshold: 0.25,
    rootMargin: '0px 0px -10% 0px'
  });
  [...splitRefs.value, ...suiteRefs.value, ...ritualRefs.value].forEach((el) => {
    if (el) revealObserver?.observe(el);
  });
};

const scheduleRevealSetup = () => {
  if (!isMounted.value) return;
  nextTick(() => {
    setupRevealObserver();
  });
};

watch(
  [suiteCards, ritualCards],
  () => {
    suiteRefs.value = [];
    ritualRefs.value = [];
    splitRefs.value = [];
    visibleSuites.value = [];
    visibleRituals.value = [];
    visibleSplit.value = [];
    scheduleRevealSetup();
  },
  { immediate: true }
);

watch(
  ritualCards,
  (cards) => {
    const total = cards?.length ?? 0;
    if (!total) return;
    if (activeRitualIndex.value >= total) activeRitualIndex.value = 0;
  },
  { immediate: true }
);

onMounted(() => {
  isMounted.value = true;
  window.addEventListener('scroll', handleScroll, { passive: true });
  nextTick(() => setupRevealObserver());
});

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll);
  if (revealObserver) {
    revealObserver.disconnect();
    revealObserver = null;
  }
});
</script>

<template>
  <section class="template-shell lumen-harbor" :data-template="templateId">
    <!-- HERO -->
    <header class="lh-hero" :style="heroShellStyle" ref="heroRef">
      <div class="lh-hero-ambient" :style="heroAmbientStyle" aria-hidden="true"></div>
      <div class="lh-hero-image" :style="heroImageStyle" aria-hidden="true"></div>
      <div class="lh-hero-overlay"></div>
      <div class="lh-hero-inner">
        <div class="lh-hero-copy">
          <p class="lh-eyebrow">{{ resolvedBrand.name }}</p>
          <h1 class="lh-title">{{ resolvedBrand.tagline }}</h1>
          <p class="lh-storyline">
            {{ resolvedBrand.description }}
          </p>

          <!-- Single CTA only -->
          <div class="lh-hero-cta">
            <button type="button" class="lh-hero-button" @click="handleContactClick">
              {{ copy.cta?.button || 'Book a stay' }}
            </button>
          </div>
        </div>

        <aside class="lh-hero-aside" v-if="heroHighlights.length">
          <article
            v-for="(item, index) in heroHighlights"
            :key="item.id || index"
            class="lh-hero-highlight"
          >
            <p class="lh-hero-highlight-label">
              {{ item.label || copy.home?.galleryFallback || 'Signature moment' }}
            </p>
            <p class="lh-hero-highlight-body">
              {{ item.description || copy.home?.sceneFallback }}
            </p>
          </article>
        </aside>
      </div>
    </header>

    <!-- NAV -->
    <nav class="lh-nav" aria-label="Template navigation">
      <button
        v-for="item in navItems"
        :key="item.id"
        :class="['lh-nav-link', { 'is-active': activePage === item.id, disabled: item.disabled }]"
        type="button"
        @click="handleNav(item)"
      >
        {{ item.label }}
      </button>
    </nav>

    <!-- BODY -->
    <main class="lh-body" ref="mainEl">
      <!-- HOME -->
      <template v-if="activePage === 'home'">
        <!-- POSITION 2: STAR ELEMENT FIRST (Collage) -->
        <section class="lh-collage lh-collage--top" v-if="collagePieces.length">
          <div class="lh-collage-stage">
            <div
              class="lh-collage-atmosphere"
              :style="{ backgroundImage: 'url(' + collagePieces[3].image + ')' }"
              aria-hidden="true"
            ></div>
            <div
              class="lh-collage-ambient lh-collage-ambient--linen"
              :style="{ backgroundImage: 'url(' + editorialAssets.ambientLinen + ')' }"
              aria-hidden="true"
            ></div>
            <div
              class="lh-collage-ambient lh-collage-ambient--horizon"
              :style="{ backgroundImage: 'url(' + editorialAssets.ambientHorizon + ')' }"
              aria-hidden="true"
            ></div>
            <div class="lh-collage-grain" aria-hidden="true"></div>

            <header class="lh-collage-overlay">
              <p class="lh-collage-kicker">{{ copy.home?.galleryEyebrow || 'Signature moments' }}</p>
              <h2 class="lh-collage-title">
                {{ copy.home?.galleryHeadline || 'Light, linen, and harbor air.' }}
              </h2>
              <p class="lh-collage-sub">
                {{ copy.home?.sceneFallback || 'A quiet detail designed to be felt, not announced.' }}
              </p>
            </header>

            <figure
              :class="['lh-collage-piece', 'is-anchor', { 'is-visible': visibleSplit[0] }]"
              :ref="(el) => setSplitRef(el, 0)"
              :style="{ '--revealDelay': 120 + 'ms' }"
            >
              <img class="lh-collage-image" :src="collagePieces[0].image" alt="" loading="lazy" decoding="async" />
            </figure>

            <figure
              :class="['lh-collage-piece', 'is-offset', { 'is-visible': visibleSplit[1] }]"
              :ref="(el) => setSplitRef(el, 1)"
              :style="{ '--revealDelay': 240 + 'ms' }"
            >
              <img class="lh-collage-image" :src="collagePieces[1].image" alt="" loading="lazy" decoding="async" />
            </figure>

            <figure
              :class="['lh-collage-piece', 'is-detail', { 'is-visible': visibleSplit[2] }]"
              :ref="(el) => setSplitRef(el, 2)"
              :style="{ '--revealDelay': 360 + 'ms' }"
            >
              <img class="lh-collage-image" :src="collagePieces[2].image" alt="" loading="lazy" decoding="async" />
            </figure>

            <div class="lh-collage-chips" aria-hidden="true">
              <span class="lh-chip">{{ collagePieces[0].label }}</span>
              <span class="lh-chip">{{ collagePieces[1].label }}</span>
              <span class="lh-chip">{{ collagePieces[2].label }}</span>
            </div>

            <div class="lh-collage-rule" aria-hidden="true"></div>
          </div>
        </section>

        <!-- Suites (moved DOWN so it no longer blocks the star moment) -->
        <section class="lh-suites" v-if="suiteCards.length">
          <header class="lh-section-header">
            <p class="lh-section-eyebrow">{{ copy.home?.galleryEyebrow || 'Suites & Residences' }}</p>
            <h2 class="lh-section-title">
              {{ copy.home?.headline || 'From cobblestone street to candlelit suites.' }}
            </h2>
          </header>

          <div class="lh-suite-rail">
            <article
              v-for="(suite, index) in suiteCards"
              :key="suite.id || index"
              :class="['lh-suite-card', { 'is-visible': visibleSuites[index] }]"
              :ref="(el) => setSuiteRef(el, index)"
              :style="{ '--revealDelay': index * 90 + 'ms' }"
            >
              <div
                class="lh-suite-media"
                :style="suite.image ? { backgroundImage: 'url(' + suite.image + ')' } : undefined"
              >
                <div class="lh-suite-glow"></div>
              </div>
              <div class="lh-suite-copy">
                <p class="lh-suite-tag">{{ suite.tag || ('0' + (index + 1)) }}</p>
                <h3>{{ suite.label || copy.home?.suiteFallback || 'Signature suite' }}</h3>
                <p class="lh-muted">
                  {{ suite.description || copy.home?.sceneFallback }}
                </p>
              </div>
            </article>
          </div>
        </section>

        <!-- Rituals (Option 1): accordion + hero image -->
        <section class="lh-rituals" v-if="ritualCards.length">
          <header class="lh-section-header">
            <p class="lh-section-eyebrow">{{ copy.home?.stepsEyebrow || 'Signature flow' }}</p>
            <h2 class="lh-section-title">{{ copy.home?.stepsHeadline || 'A night traced in quiet scenes.' }}</h2>
          </header>

          <div class="lh-ritual-stage" v-if="activeRitual">
            <div class="lh-ritual-hero">
              <div
                class="lh-ritual-hero-media"
                :style="activeRitual?.image ? { backgroundImage: 'url(' + activeRitual.image + ')' } : undefined"
              >
                <div class="lh-ritual-hero-sheen"></div>
              </div>

              <div class="lh-ritual-hero-copy">
                <p class="lh-ritual-hero-kicker">
                  {{ activeRitual.tag || ('0' + (activeRitualIndex + 1)) }}
                </p>
                <h3 class="lh-ritual-hero-title">
                  {{ activeRitual.label || copy.home?.galleryFallback || 'Signature ritual' }}
                </h3>
                <p class="lh-muted">{{ activeRitual.description || copy.home?.sceneFallback }}</p>
              </div>
            </div>

            <div class="lh-ritual-accordion" role="list">
              <button
                v-for="(ritual, index) in ritualCards"
                :key="ritual.id || index"
                type="button"
                :class="['lh-ritual-item', { active: activeRitualIndex === index, 'is-visible': visibleRituals[index] }]"
                :ref="(el) => setRitualRef(el, index)"
                @click="setActiveRitualIndex(index)"
                :aria-pressed="activeRitualIndex === index"
              >
                <span class="lh-ritual-item-kicker">{{ ritual.tag || ('0' + (index + 1)) }}</span>
                <span class="lh-ritual-item-title">
                  {{ ritual.label || copy.home?.galleryFallback || 'Signature ritual' }}
                </span>
                <span class="lh-ritual-item-body">{{ ritual.description || copy.home?.sceneFallback }}</span>
              </button>
            </div>
          </div>
        </section>
      </template>

      <!-- PRICING -->
      <article v-else-if="activePage === 'pricing'" class="lh-pricing">
        <PricingPanel
          :brand="resolvedBrand"
          :copy="copy.pricing"
          :pricing-packages="pricingPackages"
          :addons="addons"
          :maintenance="maintenance"
          @back="() => emit('navigate', 'home')"
        />
      </article>

      <!-- FALLBACK -->
      <article v-else class="lh-panel lh-placeholder">
        <h2>{{ copy.placeholder?.heading }}</h2>
        <p class="lh-muted">
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
  border: 1px solid color-mix(in srgb, var(--border) 70%, transparent);
  background: var(--surface);
}

/* HERO */

.lh-hero {
  position: relative;
  min-height: min(72vh, 700px);
  padding: clamp(2.4rem, 6vw, 3.6rem) clamp(2.2rem, 6vw, 4rem);
  background: #020617;
  display: grid;
  align-items: end;
  overflow: hidden;
}

.lh-hero-ambient,
.lh-hero-image,
.lh-hero-overlay {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.lh-hero-ambient {
  background-size: cover;
  background-position: center top;
  transform: scale(1.08);
  filter: blur(1.2px) saturate(135%) brightness(1.7);
  opacity: 0.82;
  z-index: 0;
}

.lh-hero-image {
  background-size: cover;
  background-position: center 32%;
  transform: translate3d(0, var(--lhHeroShift, 0px), 0);
  will-change: transform;
  z-index: 1;
  mask-image: linear-gradient(
    to bottom,
    rgba(0, 0, 0, 1) 42%,
    rgba(0, 0, 0, 0.45) 65%,
    rgba(0, 0, 0, 0.02) 100%
  );
  -webkit-mask-image: linear-gradient(
    to bottom,
    rgba(0, 0, 0, 1) 42%,
    rgba(0, 0, 0, 0.45) 65%,
    rgba(0, 0, 0, 0.02) 100%
  );
}

.lh-hero-overlay {
  background:
    radial-gradient(circle at 10% 10%, rgba(255, 255, 255, 0.08), transparent 55%),
    linear-gradient(
      to bottom,
      rgba(0, 0, 0, 0.08) 0%,
      rgba(0, 0, 0, 0.25) 55%,
      rgba(0, 0, 0, 0.42) 100%
    );
  z-index: 2;
}

.lh-hero-inner {
  position: relative;
  z-index: 3;
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.85fr);
  gap: clamp(2.2rem, 5vw, 3.4rem);
  align-items: end;
}

.lh-hero-copy {
  max-width: 42rem;
  color: var(--primaryForeground);
}

@media (prefers-color-scheme: light), [data-theme='golden-light'] .lumen-harbor .lh-hero-copy {
  color: #f8fafc;
}

.lh-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.32em;
  font-size: 0.72rem;
  opacity: 0.85;
}

.lh-title {
  margin-top: 0.65rem;
  font-size: clamp(2.6rem, 4.2vw, 3.6rem);
  letter-spacing: 0.02em;
  line-height: 1.05;
}

.lh-storyline {
  margin-top: 1rem;
  max-width: 38rem;
  line-height: 1.7;
  color: color-mix(in srgb, var(--primaryForeground) 82%, rgba(255, 255, 255, 0.35));
}

[data-theme='golden-light'] .lumen-harbor .lh-storyline {
  color: rgba(248, 250, 252, 0.9);
}

.lh-hero-cta {
  margin-top: 1.6rem;
  display: flex;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.lh-hero-button {
  border-radius: 999px;
  border: 1px solid rgba(255, 255, 255, 0.55);
  padding: 0.7rem 1.6rem;
  background: rgba(15, 23, 42, 0.55);
  color: rgba(248, 250, 252, 0.95);
  font-weight: 600;
  cursor: pointer;
  backdrop-filter: blur(14px);
  transition: transform 220ms ease, background 220ms ease, border-color 220ms ease;
}

.lh-hero-button:hover {
  transform: translateY(-2px);
  background: rgba(15, 23, 42, 0.68);
  border-color: rgba(255, 255, 255, 0.7);
}

/* Hero aside */

.lh-hero-aside {
  display: grid;
  gap: 0.9rem;
}

.lh-hero-highlight {
  border-radius: 1.25rem;
  padding: 1.1rem 1.2rem;
  background: rgba(15, 23, 42, 0.46);
  border: 1px solid rgba(255, 255, 255, 0.14);
  backdrop-filter: blur(16px);
  box-shadow: 0 18px 55px rgba(0, 0, 0, 0.35);
}

.lh-hero-highlight-label {
  text-transform: uppercase;
  letter-spacing: 0.22em;
  font-size: 0.68rem;
  opacity: 0.8;
}

.lh-hero-highlight-body {
  margin-top: 0.45rem;
  line-height: 1.55;
  color: color-mix(in srgb, var(--primaryForeground) 82%, rgba(255, 255, 255, 0.38));
}

[data-theme='golden-light'] .lumen-harbor .lh-hero-highlight-label,
[data-theme='golden-light'] .lumen-harbor .lh-hero-highlight-body {
  color: rgba(248, 250, 252, 0.9);
  opacity: 1;
}

/* NAV */

.lh-nav {
  position: sticky;
  top: 0;
  z-index: 20;
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem;
  padding: 0.9rem clamp(1.6rem, 5vw, 3.2rem);
  background: color-mix(in srgb, var(--surface) 80%, rgba(0, 0, 0, 0.35));
  border-top: 1px solid color-mix(in srgb, var(--border) 60%, transparent);
  border-bottom: 1px solid color-mix(in srgb, var(--border) 60%, transparent);
  backdrop-filter: blur(16px);
}

.lh-nav-link {
  border-radius: 999px;
  padding: 0.38rem 1.15rem;
  border: 1px solid color-mix(in srgb, var(--border) 70%, rgba(255, 255, 255, 0.12));
  background: transparent;
  color: var(--text);
  cursor: pointer;
  font-size: 0.92rem;
}

.lh-nav-link.is-active {
  border-color: color-mix(in srgb, var(--primary) 70%, transparent);
  background: color-mix(in srgb, var(--primary) 16%, transparent);
  color: var(--primaryForeground);
}

.lh-nav-link.disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

/* BODY */

.lh-body {
  background: var(--surface);
}

/* Section headers */

.lh-section-header {
  padding: clamp(2.2rem, 5vw, 3.2rem) clamp(1.6rem, 5vw, 3.2rem) 1.2rem;
}

.lh-section-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.32em;
  font-size: 0.72rem;
  opacity: 0.75;
}

.lh-section-title {
  margin-top: 0.75rem;
  font-size: clamp(1.9rem, 3vw, 2.4rem);
  letter-spacing: 0.02em;
}

.lh-muted {
  margin-top: 0.6rem;
  line-height: 1.7;
  color: color-mix(in srgb, var(--text) 82%, rgba(255, 255, 255, 0.26));
}

/* Suites rail */

.lh-suite-rail {
  padding: 0 clamp(1.6rem, 5vw, 3.2rem) clamp(2.6rem, 6vw, 3.8rem);
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(320px, 38vw);
  gap: 1.4rem;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
}

.lh-suite-card {
  scroll-snap-align: start;
  border-radius: 1.6rem;
  overflow: hidden;
  background: var(--surfaceMuted);
  border: 1px solid color-mix(in srgb, var(--border) 60%, transparent);
  box-shadow: 0 26px 80px rgba(0, 0, 0, 0.12);
  transform: translateY(12px);
  opacity: 0;
  transition: opacity 520ms ease, transform 520ms cubic-bezier(0.22, 0.61, 0.36, 1);
}

.lh-suite-card.is-visible {
  opacity: 1;
  transform: translateY(0);
}

.lh-suite-media {
  position: relative;
  height: clamp(260px, 34vh, 380px);
  background-size: cover;
  background-position: center;
}

.lh-suite-glow {
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.55), transparent 55%);
}

.lh-suite-copy {
  padding: 1.25rem 1.25rem 1.35rem;
}

.lh-suite-tag {
  text-transform: uppercase;
  letter-spacing: 0.22em;
  font-size: 0.72rem;
  opacity: 0.78;
}

.lh-suite-copy h3 {
  margin-top: 0.6rem;
  font-size: 1.22rem;
  letter-spacing: 0.02em;
}

/* Collage */

.lh-collage {
  padding: clamp(2.2rem, 5vw, 3.4rem) clamp(1.6rem, 5vw, 3.2rem) clamp(2.6rem, 6vw, 4.2rem);
}

.lh-collage--top {
  padding-top: clamp(2.6rem, 6vw, 4.2rem);
}

.lh-collage-stage {
  position: relative;
  border-radius: 2rem;
  overflow: hidden;
  min-height: clamp(620px, 78vh, 920px);
  border: 1px solid color-mix(in srgb, var(--border) 55%, transparent);
  background: rgba(2, 6, 23, 0.22);
}

.lh-collage-atmosphere {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  opacity: 0.18;
  transform: scale(1.12);
  filter: blur(2px);
  pointer-events: none;
}

.lh-collage-ambient {
  position: absolute;
  pointer-events: none;
  background-repeat: no-repeat;
  background-size: cover;
  opacity: 0.25;
  mix-blend-mode: screen;
  filter: blur(0.5px) saturate(110%);
}

.lh-collage-ambient--linen {
  top: -12%;
  left: -6%;
  width: 65%;
  height: 65%;
  transform: rotate(-8deg);
  opacity: 0.32;
}

.lh-collage-ambient--horizon {
  bottom: -10%;
  right: -8%;
  width: 72%;
  height: 72%;
  transform: rotate(6deg);
  opacity: 0.28;
}

.lh-collage-grain {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 20% 10%, rgba(255, 255, 255, 0.10), transparent 55%),
    radial-gradient(circle at 85% 40%, rgba(255, 255, 255, 0.08), transparent 55%),
    linear-gradient(to bottom, rgba(2, 6, 23, 0.18), rgba(2, 6, 23, 0.78));
  opacity: 1;
  pointer-events: none;
}

.lh-collage-overlay {
  position: absolute;
  left: clamp(2rem, 5vw, 3.6rem);
  top: clamp(2rem, 5vw, 3.6rem);
  max-width: 44rem;
  z-index: 5;
  color: rgba(248, 250, 252, 0.92);
}

.lh-collage-kicker {
  text-transform: uppercase;
  letter-spacing: 0.34em;
  font-size: 0.72rem;
  opacity: 0.85;
}

.lh-collage-title {
  margin-top: 0.85rem;
  font-size: clamp(2.4rem, 4.6vw, 3.6rem);
  letter-spacing: 0.01em;
  line-height: 1.05;
}

.lh-collage-sub {
  margin-top: 1rem;
  max-width: 34rem;
  line-height: 1.75;
  color: color-mix(in srgb, rgba(248, 250, 252, 0.92) 78%, rgba(255, 255, 255, 0.18));
}

.lh-collage-piece {
  position: absolute;
  margin: 0;
  border-radius: 2rem;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.12);
  box-shadow: 0 56px 160px rgba(0, 0, 0, 0.55);
  z-index: 2;
}

.lh-collage-piece.is-anchor {
  left: clamp(1.8rem, 4vw, 3rem);
  top: clamp(7.6rem, 14vw, 11.5rem);
  width: min(52%, 640px);
  height: min(74%, 760px);
}

.lh-collage-piece.is-offset {
  right: clamp(1.8rem, 4vw, 3rem);
  top: clamp(10rem, 18vw, 14.5rem);
  width: min(44%, 560px);
  height: min(40%, 420px);
  border-radius: 1.8rem;
}

.lh-collage-piece.is-detail {
  right: clamp(3.2rem, 8vw, 6rem);
  bottom: clamp(2rem, 6vw, 3.6rem);
  width: min(30%, 360px);
  height: min(30%, 360px);
  border-radius: 999px;
}

.lh-collage-image {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.lh-collage-chips {
  position: absolute;
  left: clamp(2rem, 5vw, 3.6rem);
  bottom: clamp(2rem, 5vw, 3.2rem);
  display: flex;
  gap: 0.55rem;
  flex-wrap: wrap;
  z-index: 6;
}

.lh-chip {
  padding: 0.55rem 0.85rem;
  border-radius: 999px;
  background: rgba(2, 6, 23, 0.62);
  border: 1px solid rgba(255, 255, 255, 0.14);
  color: rgba(248, 250, 252, 0.92);
  font-size: 0.68rem;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  opacity: 0.95;
}

.lh-collage-rule {
  position: absolute;
  left: clamp(2rem, 5vw, 3.6rem);
  right: clamp(2rem, 5vw, 3.6rem);
  bottom: clamp(1.4rem, 4vw, 2.2rem);
  height: 1px;
  background: linear-gradient(to right, transparent, rgba(255, 255, 255, 0.24), transparent);
  opacity: 0.8;
  z-index: 6;
}

/* Rituals */

.lh-ritual-stage {
  padding: 0 clamp(1.6rem, 5vw, 3.2rem) clamp(2.8rem, 6vw, 4.2rem);
  display: grid;
  grid-template-columns: minmax(0, 1.35fr) minmax(0, 0.65fr);
  gap: clamp(1.4rem, 3vw, 2.2rem);
  align-items: start;
}

.lh-ritual-hero {
  border-radius: 1.8rem;
  overflow: hidden;
  border: 1px solid color-mix(in srgb, var(--border) 60%, transparent);
  background: var(--surfaceMuted);
  box-shadow: 0 34px 110px rgba(0, 0, 0, 0.18);
}

.lh-ritual-hero-media {
  position: relative;
  min-height: clamp(360px, 56vh, 620px);
  background-size: cover;
  background-position: center;
}

.lh-ritual-hero-sheen {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 20% 10%, rgba(255, 255, 255, 0.16), transparent 62%),
    linear-gradient(to top, rgba(0, 0, 0, 0.62), transparent 60%);
}

.lh-ritual-hero-copy {
  padding: 1.35rem 1.35rem 1.45rem;
}

.lh-ritual-hero-kicker {
  text-transform: uppercase;
  letter-spacing: 0.32em;
  font-size: 0.7rem;
  opacity: 0.78;
}

.lh-ritual-hero-title {
  margin-top: 0.6rem;
  font-size: 1.35rem;
  letter-spacing: 0.02em;
}

.lh-ritual-accordion {
  display: grid;
  gap: 0.75rem;
}

.lh-ritual-item {
  text-align: left;
  border-radius: 1.25rem;
  padding: 1rem 1.05rem;
  border: 1px solid color-mix(in srgb, var(--border) 60%, transparent);
  background: color-mix(in srgb, var(--surfaceMuted) 75%, transparent);
  cursor: pointer;
  display: grid;
  gap: 0.35rem;
  transform: translateY(12px);
  opacity: 0;
  transition: opacity 520ms ease, transform 520ms cubic-bezier(0.22, 0.61, 0.36, 1);
}

.lh-ritual-item.is-visible {
  opacity: 1;
  transform: translateY(0);
}

.lh-ritual-item.active {
  background: color-mix(in srgb, var(--primary) 12%, var(--surfaceMuted));
  border-color: color-mix(in srgb, var(--primary) 45%, transparent);
}

.lh-ritual-item-kicker {
  text-transform: uppercase;
  letter-spacing: 0.28em;
  font-size: 0.66rem;
  opacity: 0.78;
}

.lh-ritual-item-title {
  font-weight: 600;
  letter-spacing: 0.02em;
}

.lh-ritual-item-body {
  line-height: 1.6;
  color: color-mix(in srgb, var(--text) 82%, rgba(255, 255, 255, 0.26));
}

/* Reveal upgrade */

.lh-suite-media,
.lh-ritual-hero-media,
.lh-collage-piece {
  --lhHoverScale: 1.03;
  clip-path: inset(18% 0 18% 0 round 28px);
  transform: translateY(18px) scale(var(--lhHoverScale));
  opacity: 0;
  transition:
    clip-path 900ms cubic-bezier(0.22, 0.61, 0.36, 1) var(--revealDelay, 0ms),
    transform 900ms cubic-bezier(0.22, 0.61, 0.36, 1) var(--revealDelay, 0ms),
    opacity 700ms ease var(--revealDelay, 0ms);
  will-change: transform, clip-path, opacity;
}

.lh-suite-card.is-visible .lh-suite-media,
.lh-ritual-hero-media,
.lh-collage-piece.is-visible {
  clip-path: inset(0 0 0 0 round 28px);
  transform: translateY(0) scale(var(--lhHoverScale, 1));
  opacity: 1;
}

/* Fallback panel */

.lh-panel {
  padding: 2.2rem clamp(1.6rem, 5vw, 3.2rem) 3rem;
}

.lh-placeholder h2 {
  font-size: 1.6rem;
}

/* RESPONSIVE */

@media (max-width: 980px) {
  .lh-hero-inner {
    grid-template-columns: minmax(0, 1fr);
  }

  .lh-hero-aside {
    margin-top: 1.6rem;
  }

  .lh-ritual-stage {
    grid-template-columns: minmax(0, 1fr);
  }

  .lh-ritual-hero-media {
    min-height: clamp(320px, 46vh, 520px);
  }

  .lh-collage-piece.is-anchor {
    left: 1.2rem;
    top: 9.5rem;
    width: 74%;
    height: 56%;
  }

  .lh-collage-piece.is-offset {
    right: 1.2rem;
    top: 56%;
    width: 64%;
    height: 30%;
  }

  .lh-collage-piece.is-detail {
    right: 1.4rem;
    bottom: 1.6rem;
    width: 34%;
    height: 34%;
  }
}

/* Cinematic hover (desktop only) */
@media (hover: hover) {
  .lh-suite-card:hover .lh-suite-media {
    --lhHoverScale: 1.04;
  }

  .lh-suite-card:hover {
    transform: translateY(-4px);
  }
}

/* Respect reduced motion */
@media (prefers-reduced-motion: reduce) {
  * {
    transition: none !important;
    animation: none !important;
    transform: none !important;
  }
}
</style>
