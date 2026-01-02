<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue';
import PricingPanel from '../components/PricingPanel.vue';

const props = defineProps({
  navItems: { type: Array, default: () => [] },
  activePage: { type: String, default: '' },
  templateId: { type: String, default: '' },
  brand: { type: Object, default: () => ({}) },
  brandCopy: { type: Object, default: () => ({}) },
  copy: { type: Object, default: () => ({}) },
  story: { type: Object, default: () => ({}) },
  tastingMenu: { type: Array, default: () => [] },
  gallery: { type: Array, default: () => [] },
  pricingPackages: { type: Array, default: () => [] },
  addons: { type: Array, default: () => [] },
  maintenance: { type: Array, default: () => [] },
  lockedThemeId: { type: String, default: null }
});

const emit = defineEmits(['navigate', 'contact']);
const mainEl = ref(null);

const masonryEl = ref(null);

let masonryObserver = null;
const masonryCleanupFns = [];

const setupMasonryEffects = () => {
  if (typeof window === 'undefined') return;
  const root = masonryEl.value;
  if (!root) return;

  const shots = Array.from(root.querySelectorAll('.bn-shot'));
  if (!shots.length) return;

  // Stagger index for reveal transitions
  shots.forEach((el, i) => {
    el.style.setProperty('--i', i);
  });

  // Scroll reveal
  masonryObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) e.target.classList.add('is-in');
      });
    },
    { threshold: 0.18 }
  );

  shots.forEach((el) => masonryObserver.observe(el));

  // Cursor-follow spotlight (subtle)
  shots.forEach((el) => {
    const onMove = (ev) => {
      const r = el.getBoundingClientRect();
      const x = ((ev.clientX - r.left) / r.width) * 100;
      const y = ((ev.clientY - r.top) / r.height) * 100;
      el.style.setProperty('--mx', `${x}%`);
      el.style.setProperty('--my', `${y}%`);
    };
    el.addEventListener('mousemove', onMove, { passive: true });
    masonryCleanupFns.push(() => el.removeEventListener('mousemove', onMove));
  });
};

const teardownMasonryEffects = () => {
  try {
    masonryObserver?.disconnect();
  } catch (e) {
    // no-op
  }
  masonryObserver = null;

  while (masonryCleanupFns.length) {
    const fn = masonryCleanupFns.pop();
    try {
      fn?.();
    } catch (e) {
      // no-op
    }
  }
};

onMounted(() => {
  // Delay to ensure DOM has rendered masonry items
  requestAnimationFrame(() => {
    setupMasonryEffects();
  });
});

onBeforeUnmount(() => {
  teardownMasonryEffects();
});

const heroImage = computed(() => props.brand?.assets?.hero || props.brand?.assets?.secondary || null);
const secondaryImage = computed(() => props.brand?.assets?.secondary || props.brand?.assets?.hero || null);

const fallbackFlights = [
  { name: 'Charred citrus aperitif', description: 'Smoked yuzu broth over shaved ice with embered rosemary.' },
  { name: 'Ember seared kinmedai', description: 'Toro lacquer, charcoal oil, fermented plum salt.' },
  { name: 'Midnight chocolate feuille', description: 'Burnt caramel, nocino glaze, single-origin cacao.' }
];

const featureFlights = computed(() => {
  let courses = props.tastingMenu ?? [];
  if (!courses.length) courses = props.brand?.assets?.elements ?? [];
  if (!courses.length) {
    return fallbackFlights.map((course, index) => ({
      id: index,
      name: props.copy?.home?.[`step${index + 1}Title`] || course.name,
      description: props.copy?.home?.[`step${index + 1}Body`] || course.description
    }));
  }
  return courses.slice(0, 3).map((course, index) => ({
    id: course.id || index,
    name: course.name || course.label || fallbackFlights[index]?.name || `Course ${index + 1}`,
    description:
      course.description ||
      course.body ||
      props.copy?.home?.[`step${index + 1}Body`] ||
      fallbackFlights[index]?.description ||
      ''
  }));
});

const normalizeShotList = (items, prefix = 'shot') => {
  if (!Array.isArray(items)) return [];
  return items
    .map((item, index) => {
      if (!item) return null;
      if (typeof item === 'string') {
        return { id: `${prefix}-${index}`, image: item };
      }
      const image =
        item.image ||
        item.url ||
        item.src ||
        (typeof item.asset === 'string' ? item.asset : null);
      if (!image) return null;
      return { ...item, image };
    })
    .filter(Boolean);
};

const galleryImages = computed(() => {
  const prioritizedSources = [
    normalizeShotList(props.brand?.assets?.ritualScenes, 'scene'),
    normalizeShotList(props.brand?.assets?.settings, 'setting'),
    normalizeShotList(props.brand?.assets?.gallery, 'gallery'),
    normalizeShotList(props.gallery, 'gallery-prop'),
    normalizeShotList(props.brand?.assets?.elements, 'element')
  ];

  for (const shots of prioritizedSources) {
    if (shots.length) return shots.slice(0, 10);
  }

  return [];
});

const defaultGalleryCaptions = [
  { label: 'Midnight plating', body: 'Gloved service and torchlight across porcelain.' },
  { label: 'Chef’s counter', body: 'Sumi ink menus and candlelit tasting pours.' },
  { label: 'Cellar tasting', body: 'Rare bottles decanted tableside with hush.' },
  { label: 'Salon finish', body: 'Guests drift to low sofas and late-night playlists.' },
  { label: 'Low light ritual', body: 'Warm glass, quiet tempo, deliberate pour.' },
  { label: 'After-hours hush', body: 'A final course carried through shadow.' }
];

const collageImages = computed(() => {
  // Use the first 4 images for a bold “Salon notes” collage.
  return (galleryImages.value || []).slice(0, 4);
});

const masonryImages = computed(() => {
  // Use the remaining images for the masonry grid.
  return (galleryImages.value || []).slice(4, 10);
});

const ritualStepImages = computed(() => {
  // Prefer detail/texture shots (often later in the list). Falls back to hero images.
  const imgs = (galleryImages.value || []).map((s) => s?.image).filter(Boolean);
  const picked = imgs.slice(-3);
  if (picked.length === 3) return picked;

  const fallbacks = [secondaryImage.value, heroImage.value].filter(Boolean);
  return [...picked, ...fallbacks].slice(0, 3);
});

const offeringImage = computed(() => {
  // “Release” moment: prefer a composed hero/secondary, else first gallery shot.
  return secondaryImage.value || heroImage.value || galleryImages.value?.[0]?.image || null;
});

const venueDetails = computed(() => {
  // Safe fallbacks; if you have real keys later, they’ll override.
  const d = props.story?.details || props.copy?.home?.details || {};
  return {
    hours: d.hours || 'Tue–Sun · 18:00–01:00',
    address: d.address || 'By reservation · city center',
    dress: d.dress || 'Elevated casual · dark tones welcome',
    note: d.note || 'A slow sequence. A quiet room. No rush.'
  };
});

const pressQuotes = computed(() => {
  const q = props.story?.press || props.brandCopy?.press || props.copy?.home?.press || [];
  if (Array.isArray(q) && q.length) return q.slice(0, 3);
  return [
    { quote: 'A room that makes time feel expensive.', source: 'Night Edition' },
    { quote: 'Precision, shadow, and warmth — held in balance.', source: 'The Ledger' },
    { quote: 'A tasting that moves like a film cut.', source: 'Studio Notes' }
  ];
});

const handlePricingToggle = async () => {
  const targetPage = props.activePage === 'pricing' ? 'home' : 'pricing';
  emit('navigate', targetPage);
  await nextTick();
  requestAnimationFrame(() => {
    if (typeof window === 'undefined') return;
    mainEl.value?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });
};

const handleContactClick = () => emit('contact');
</script>

<template>
  <section
    class="template-shell bistro-noir"
    :data-template="templateId"
    :data-theme="lockedThemeId || undefined"
    :class="{ 'is-dark-locked': lockedThemeId === 'golden-dark' }"
  >
    <!-- HERO: cinematic split + noir marquee -->
    <header class="bn-hero">
      <div class="bn-hero-stage">
        <div class="bn-hero-media bn-hero-media--a" :style="heroImage ? { backgroundImage: `url(${heroImage})` } : undefined">
          <div class="bn-hero-vignette" />
        </div>
        <div class="bn-hero-media bn-hero-media--b" :style="secondaryImage ? { backgroundImage: `url(${secondaryImage})` } : undefined">
          <div class="bn-hero-vignette bn-hero-vignette--soft" />
        </div>

        <div class="bn-hero-overlay">
          <p class="bn-eyebrow">{{ brand.name }}</p>
          <h1 class="bn-title">{{ brand.tagline }}</h1>
          <p class="bn-story">
            {{ brand.description || story.heroBody || copy.home?.body }}
          </p>

          <div class="bn-hero-cta">
            <button type="button" class="bn-btn bn-btn--solid" @click="handleContactClick">Reserve</button>
            <button type="button" class="bn-btn bn-btn--ghost" @click="handlePricingToggle">View tasting</button>
          </div>

          <div class="bn-meta">
            <div class="bn-meta-item">
              <span class="k">Hours</span>
              <span class="v">{{ venueDetails.hours }}</span>
            </div>
            <div class="bn-meta-item">
              <span class="k">Address</span>
              <span class="v">{{ venueDetails.address }}</span>
            </div>
            <div class="bn-meta-item">
              <span class="k">Dress</span>
              <span class="v">{{ venueDetails.dress }}</span>
            </div>
          </div>
        </div>

        <div class="bn-marquee" aria-hidden="true">
          <div class="bn-marquee-track">
            <span>NOIR</span><span>•</span><span>RITUAL</span><span>•</span><span>AFTER HOURS</span><span>•</span><span>SLOW SERVICE</span><span>•</span>
            <span>NOIR</span><span>•</span><span>RITUAL</span><span>•</span><span>AFTER HOURS</span><span>•</span><span>SLOW SERVICE</span><span>•</span>
          </div>
        </div>
      </div>
    </header>

    <!-- NAV -->
    <nav class="bn-nav">
      <button
        v-for="item in navItems"
        :key="item.id"
        type="button"
        :class="['bn-pill', { 'is-active': activePage === item.id }]"
        @click="emit('navigate', item.id)"
      >
        {{ item.label }}
      </button>
    </nav>

    <main class="bn-body" ref="mainEl">
      <template v-if="activePage === 'home'">
        <!-- RITUAL TIMELINE (uses featureFlights) -->
        <section class="bn-panel bn-ritual" v-if="featureFlights.length">
          <header class="bn-panel-head">
            <p class="bn-label">{{ story.tastingEyebrow || copy.home?.eyebrow || 'Ritual' }}</p>
            <h2>{{ story.tastingHeadline || copy.home?.headline || 'A three-step nocturne' }}</h2>
            <p class="bn-sub">{{ venueDetails.note }}</p>
          </header>

          <ol class="bn-ritual-steps">
            <li v-for="(course, idx) in featureFlights" :key="course.id" class="bn-step">
              <div class="bn-step-index">0{{ idx + 1 }}</div>
              <div class="bn-step-body">
                <p class="bn-step-name">{{ course.name }}</p>
                <p class="bn-step-desc">{{ course.description }}</p>
              </div>
              <div class="bn-step-media" aria-hidden="true">
                <div
                  class="bn-step-thumb"
                  :style="ritualStepImages[idx] ? { backgroundImage: `url(${ritualStepImages[idx]})` } : undefined"
                />
                <div class="bn-step-fade" />
              </div>
            </li>
          </ol>
        </section>

        <!-- OFFERING STRIP (full-bleed release moment) -->
        <section class="bn-offering" v-if="offeringImage">
          <div class="bn-offering-media" :style="{ backgroundImage: `url(${offeringImage})` }">
            <div class="bn-offering-sheen" />
          </div>
          <div class="bn-offering-copy">
            <p class="bn-label">{{ story.offeringEyebrow || copy.home?.offeringEyebrow || 'Offering' }}</p>
            <h2>{{ story.offeringHeadline || copy.home?.offeringHeadline || 'The room exhales' }}</h2>
            <p class="bn-sub">
              {{ story.offeringBody || copy.home?.offeringBody || 'One composed moment — then back into shadow.' }}
            </p>
          </div>
        </section>

        <!-- GALLERY: collage + masonry stage (asymmetric spans) -->
        <section class="bn-panel bn-gallery" v-if="galleryImages.length">
          <header class="bn-panel-head">
            <p class="bn-label">{{ story.galleryEyebrow || copy.home?.galleryEyebrow || 'Atmosphere' }}</p>
            <h2>{{ story.galleryHeadline || copy.home?.galleryHeadline || 'Fragments of the night' }}</h2>
          </header>

          <div class="bn-gallery-stage" ref="masonryEl">
            <!-- Salon notes: 4-image collage (stronger composition) -->
            <div class="bn-collage" v-if="collageImages.length">
              <article
                v-for="(shot, index) in collageImages"
                :key="shot.id || `c-${index}`"
                :class="['bn-shot', 'bn-collage-shot', `c-${index}`]"
              >
                <div class="bn-shot-media" :style="shot.image ? { backgroundImage: `url(${shot.image})` } : undefined" />
                <div class="bn-shot-overlay">
                  <p class="t">{{ shot.label || defaultGalleryCaptions[index]?.label }}</p>
                  <p class="b">{{ shot.description || defaultGalleryCaptions[index]?.body }}</p>
                </div>
              </article>
            </div>

            <!-- Inside the atelier: masonry grid for remaining images -->
            <div class="bn-masonry" v-if="masonryImages.length">
              <article
                v-for="(shot, index) in masonryImages"
                :key="shot.id || `m-${index}`"
                :class="['bn-shot', `s-${index}`]"
              >
                <div class="bn-shot-media" :style="shot.image ? { backgroundImage: `url(${shot.image})` } : undefined" />
                <div class="bn-shot-overlay">
                  <p class="t">{{ shot.label || defaultGalleryCaptions[index + 4]?.label }}</p>
                  <p class="b">{{ shot.description || defaultGalleryCaptions[index + 4]?.body }}</p>
                </div>
              </article>
            </div>
          </div>
        </section>

        <!-- PRESS STRIP -->
        <section class="bn-press" v-if="pressQuotes.length">
          <div class="bn-press-inner">
            <article v-for="(q, i) in pressQuotes" :key="i" class="bn-quote">
              <p class="q">“{{ q.quote }}”</p>
              <p class="s">— {{ q.source }}</p>
            </article>
          </div>
        </section>

      </template>

      <!-- PRICING (kept) -->
      <article v-else-if="activePage === 'pricing'" class="bn-panel bn-pricing">
        <PricingPanel
          :brand="brand"
          :copy="copy.pricing"
          :pricing-packages="pricingPackages"
          :addons="addons"
          :maintenance="maintenance"
          @back="handlePricingToggle"
        />
      </article>

      <article v-else class="bn-panel bn-slot">
        <slot />
      </article>
    </main>
  </section>
</template>

<style scoped>
.template-shell {
  border-radius: var(--radiusXl);
  overflow: hidden;
  border: 1px solid color-mix(in srgb, var(--primary) 32%, transparent);
  background: radial-gradient(circle at top, rgba(255,255,255,0.04), transparent 60%), var(--surface);
}

.bistro-noir {
  --bn-foreground: #fdfbfd;
  --bn-muted: rgba(253, 251, 253, 0.78);
  color: var(--bn-foreground);
  --primaryForeground: var(--bn-foreground);
  --primary-foreground: var(--bn-foreground);
  --text: var(--bn-foreground);
  --text-muted: var(--bn-muted);
}

/* HERO */
.bn-hero {
  position: relative;
  padding: clamp(1.4rem, 3vw, 2.2rem);
}
.bn-hero-stage {
  position: relative;
  border-radius: 2.2rem;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(0,0,0,0.55);
  min-height: 560px;
}
.bn-hero-media {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  filter: saturate(0.95) contrast(1.05);
}
.bn-hero-media--a {
  clip-path: polygon(0 0, 62% 0, 52% 100%, 0 100%);
  transform: scale(1.02);
}
.bn-hero-media--b {
  clip-path: polygon(58% 0, 100% 0, 100% 100%, 48% 100%);
  transform: scale(1.03);
  opacity: 0.92;
}
.bn-hero-vignette {
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at 35% 25%, rgba(0,0,0,0.18), rgba(0,0,0,0.82) 70%);
}
.bn-hero-vignette--soft {
  background: radial-gradient(circle at 70% 25%, rgba(0,0,0,0.10), rgba(0,0,0,0.72) 70%);
}

.bn-hero-overlay {
  position: relative;
  z-index: 2;
  padding: clamp(2.2rem, 4vw, 3.2rem);
  max-width: 52rem;
}
.bn-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.34em;
  font-size: 0.7rem;
  opacity: 0.75;
  margin-bottom: 0.85rem;
}
.bn-title {
  margin: 0;
  line-height: 1.02;
  text-shadow: 0 24px 60px rgba(0,0,0,0.65);
}
.bn-story {
  margin-top: 0.9rem;
  max-width: 40rem;
  line-height: 1.65;
  opacity: 0.90;
}

.bn-hero-cta {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.35rem;
  flex-wrap: wrap;
}
.bn-btn {
  border-radius: 999px;
  padding: 0.65rem 1.85rem;
  font-weight: 650;
  cursor: pointer;
}
.bn-btn--solid {
  border: 1px solid rgba(255,255,255,0.18);
  background: rgba(255,255,255,0.14);
  color: var(--primaryForeground);
}
.bn-btn--ghost {
  border: 1px solid rgba(255,255,255,0.28);
  background: transparent;
  color: var(--primaryForeground);
}

.bn-meta {
  margin-top: 1.6rem;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.9rem;
  max-width: 46rem;
}
.bn-meta-item {
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(0,0,0,0.25);
  border-radius: 1.15rem;
  padding: 0.85rem 1rem;
}
.bn-meta-item .k {
  display: block;
  font-size: 0.68rem;
  letter-spacing: 0.28em;
  text-transform: uppercase;
  opacity: 0.65;
}
.bn-meta-item .v {
  display: block;
  margin-top: 0.4rem;
  opacity: 0.92;
  line-height: 1.35;
}

/* Marquee */
.bn-marquee {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0.9rem;
  overflow: hidden;
  opacity: 0.22;
  pointer-events: none;
}
.bn-marquee-track {
  display: flex;
  gap: 1.15rem;
  white-space: nowrap;
  font-weight: 800;
  letter-spacing: 0.18em;
  transform: translateX(0);
  animation: bn-marquee 18s linear infinite;
  padding-left: 1.2rem;
}
.bn-marquee-track span {
  font-size: clamp(1.4rem, 2.4vw, 2.2rem);
}
@keyframes bn-marquee {
  from { transform: translateX(0); }
  to { transform: translateX(-40%); }
}

/* NAV */
.bn-nav {
  display: flex;
  gap: 0.6rem;
  padding: 0.9rem clamp(1.4rem, 3vw, 2.2rem);
  border-top: 1px solid rgba(255,255,255,0.10);
}
.bn-pill {
  border-radius: 999px;
  padding: 0.45rem 1.35rem;
  border: 1px solid transparent;
  background: rgba(255,255,255,0.06);
  color: var(--primaryForeground);
  cursor: pointer;
}
.bn-pill.is-active {
  border-color: rgba(255,255,255,0.24);
  background: rgba(255,255,255,0.12);
}

/* BODY / PANELS */
.bn-body {
  padding: clamp(2rem, 4vw, 3.2rem);
  display: flex;
  flex-direction: column;
  gap: 2.4rem;
}
.bn-panel {
  border-radius: 1.8rem;
  padding: clamp(1.6rem, 3vw, 2.6rem);
  background: color-mix(in srgb, var(--surface), rgba(255,255,255,0.05));
  border: 1px solid color-mix(in srgb, var(--border), rgba(255,255,255,0.10));
}
.bn-panel-head {
  margin-bottom: 1.4rem;
}
.bn-label {
  text-transform: uppercase;
  font-size: 0.72rem;
  letter-spacing: 0.26em;
  opacity: 0.68;
}
.bn-sub {
  margin-top: 0.7rem;
  opacity: 0.85;
  max-width: 52rem;
  line-height: 1.6;
}

/* Ritual */
.bn-ritual-steps {
  list-style: none;
  padding: 0;
  margin: 1.2rem 0 0;
  display: grid;
  gap: 0.9rem;
}
.bn-step {
  display: grid;
  grid-template-columns: 84px 1fr 220px;
  gap: 1rem;
  align-items: start;
  border-top: 1px solid rgba(255,255,255,0.10);
  padding-top: 1rem;
}
.bn-step-index {
  font-weight: 800;
  letter-spacing: 0.18em;
  opacity: 0.55;
  padding-top: 0.2rem;
}
.bn-step-name {
  font-weight: 700;
  margin: 0;
}
.bn-step-desc {
  margin: 0.35rem 0 0;
  opacity: 0.84;
  line-height: 1.55;
}

.bn-step-media {
  position: relative;
  height: 120px;
  align-self: center;
  border-radius: 1.2rem;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(0,0,0,0.20);
}

.bn-step-thumb {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  filter: brightness(0.85) contrast(1.05);
  opacity: 0.72;
  transform: scale(1.02);
  transition: opacity 420ms ease, transform 900ms ease;
}

/* Soft opacity + edge fade (no hard borders) */
.bn-step-fade {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 30% 35%, rgba(255,255,255,0.10), transparent 55%),
    linear-gradient(90deg, rgba(0,0,0,0.65), rgba(0,0,0,0.10) 65%, rgba(0,0,0,0.55));
  opacity: 0.85;
  pointer-events: none;
}

.bn-step:hover .bn-step-thumb,
.bn-step:focus-within .bn-step-thumb {
  opacity: 0.92;
  transform: scale(1.07) translateX(2px);
}

/* Offering (full-bleed inside panel spacing) */
.bn-offering {
  display: grid;
  grid-template-columns: 1.15fr 0.85fr;
  gap: 1.2rem;
  align-items: stretch;
  border-radius: 1.9rem;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(0,0,0,0.35);
  isolation: isolate;
  z-index: 0;
}
.bn-offering-media {
  min-height: 420px;
  background-size: cover;
  background-position: center;
  position: relative;
  filter: brightness(0.98) contrast(1.06);
  transition: filter 650ms ease;
}
.bn-offering-sheen {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, rgba(0,0,0,0.35), rgba(0,0,0,0.10));
}
.bn-offering-copy {
  padding: clamp(1.6rem, 3vw, 2.2rem);
  z-index: 1;
}


.bn-offering:hover .bn-offering-media,
.bn-offering:focus-within .bn-offering-media {
  filter: brightness(1.05) contrast(1.08);
}

/* Masonry Gallery */
.bn-masonry {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  grid-auto-rows: 92px;
  gap: 1rem;
}

.bn-gallery-stage {
  display: grid;
  gap: 1.4rem;
}

/* Salon notes collage (4 images, stronger hierarchy) */
.bn-collage {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  grid-auto-rows: 90px;
  gap: 1rem;
}

.bn-collage-shot.c-0 { grid-column: 1 / span 7; grid-row: 1 / span 6; }
.bn-collage-shot.c-1 { grid-column: 8 / span 5; grid-row: 1 / span 3; }
.bn-collage-shot.c-2 { grid-column: 8 / span 5; grid-row: 4 / span 3; }
.bn-collage-shot.c-3 { grid-column: 1 / span 12; grid-row: 7 / span 2; }

@media (max-width: 980px) {
  .bn-collage {
    grid-template-columns: repeat(6, 1fr);
    grid-auto-rows: 96px;
  }
  .bn-collage-shot.c-0 { grid-column: 1 / span 6; grid-row: 1 / span 4; }
  .bn-collage-shot.c-1 { grid-column: 1 / span 3; grid-row: 5 / span 3; }
  .bn-collage-shot.c-2 { grid-column: 4 / span 3; grid-row: 5 / span 3; }
  .bn-collage-shot.c-3 { grid-column: 1 / span 6; grid-row: 8 / span 2; }
}
.bn-shot {
  position: relative;
  border-radius: 1.5rem;
  overflow: hidden;
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(0,0,0,0.30);

  /* reveal (starts asleep) */
  opacity: 0;
  transform: translateY(16px) scale(0.985);
  transition: opacity 520ms ease, transform 520ms ease;
  transition-delay: calc(var(--i, 0) * 90ms);
  will-change: transform, opacity;
}

.bn-shot.is-in {
  opacity: 1;
  transform: translateY(0) scale(1);
}

/* cursor-follow spotlight */
.bn-shot::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: 0;
  transition: opacity 220ms ease;
  background: radial-gradient(
    220px circle at var(--mx, 50%) var(--my, 50%),
    rgba(255,255,255,0.16),
    transparent 55%
  );
  mix-blend-mode: overlay;
}

.bn-shot:hover::after {
  opacity: 1;
}
.bn-shot-media {
  position: absolute;
  inset: 0;
  background-size: cover;
  background-position: center;
  filter: brightness(0.95) contrast(1.05);
  transform: scale(1.02);
  transition: transform 900ms ease, filter 650ms ease;
}

.bn-shot:hover .bn-shot-media,
.bn-shot:focus-within .bn-shot-media {
  transform: scale(1.07) translateY(-6px);
  filter: brightness(1.05) contrast(1.08);
}

.bn-shot-overlay {
  transform: translateY(16px);
  transition: transform 360ms ease, opacity 360ms ease;
}

.bn-shot:hover .bn-shot-overlay,
.bn-shot:focus-within .bn-shot-overlay {
  transform: translateY(0);
  opacity: 1;
}
.bn-shot-overlay {
  position: absolute;
  inset: 0;
  display: grid;
  align-content: end;
  padding: 1.1rem;
  background: linear-gradient(180deg, rgba(0,0,0,0.0), rgba(0,0,0,0.70));
  opacity: 0.88;
}
.bn-shot-overlay .t {
  font-weight: 700;
  margin: 0;
}
.bn-shot-overlay .b {
  margin: 0.35rem 0 0;
  opacity: 0.86;
  line-height: 1.45;
}

/* Spans */
.bn-shot.s-0 { grid-column: 1 / span 6; grid-row: 1 / span 4; }
.bn-shot.s-1 { grid-column: 7 / span 6; grid-row: 1 / span 2; }
.bn-shot.s-2 { grid-column: 7 / span 6; grid-row: 3 / span 2; }
.bn-shot.s-3 { grid-column: 1 / span 4; grid-row: 5 / span 3; }
.bn-shot.s-4 { grid-column: 5 / span 4; grid-row: 5 / span 3; }
.bn-shot.s-5 { grid-column: 9 / span 4; grid-row: 5 / span 3; }

/* Press */
.bn-press {
  border-radius: 1.8rem;
  border: 1px solid rgba(255,255,255,0.10);
  background: rgba(0,0,0,0.35);
  padding: clamp(1.4rem, 3vw, 2rem);
}
.bn-press-inner {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.2rem;
}
.bn-quote {
  border-left: 1px solid rgba(255,255,255,0.14);
  padding-left: 1rem;
}
.bn-quote .q {
  margin: 0;
  opacity: 0.92;
  line-height: 1.55;
}
.bn-quote .s {
  margin: 0.65rem 0 0;
  opacity: 0.65;
  font-size: 0.95rem;
}

/* Responsive */
@media (max-width: 980px) {
  .bn-meta { grid-template-columns: 1fr; }
  .bn-offering { grid-template-columns: 1fr; }
  .bn-masonry { grid-template-columns: repeat(6, 1fr); grid-auto-rows: 96px; }
  .bn-shot.s-0 { grid-column: 1 / span 6; grid-row: 1 / span 3; }
  .bn-shot.s-1 { grid-column: 1 / span 3; grid-row: 4 / span 3; }
  .bn-shot.s-2 { grid-column: 4 / span 3; grid-row: 4 / span 3; }
  .bn-shot.s-3 { grid-column: 1 / span 6; grid-row: 7 / span 3; }
  .bn-shot.s-4 { grid-column: 1 / span 3; grid-row: 10 / span 3; }
  .bn-shot.s-5 { grid-column: 4 / span 3; grid-row: 10 / span 3; }
  .bn-step { grid-template-columns: 84px 1fr; }
  .bn-step-media { margin-top: 0.8rem; grid-column: 2 / -1; width: 100%; }
}

/* hard stop: prevent Offering visuals from overlapping next sections */
.bn-offering + section,
.bn-offering + .bn-panel {
  position: relative;
  z-index: 1;
}

</style>
