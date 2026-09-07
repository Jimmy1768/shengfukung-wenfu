<script setup>
import { computed, ref } from 'vue';
import fittingRoomHero from '@/assets/media/clothing/clothing_fitting_area.webp';
import PricingPanel from '../components/PricingPanel.vue';

const props = defineProps({
  navItems: { type: Array, default: () => [] },
  activePage: { type: String, default: '' },
  templateId: { type: String, default: '' },
  brand: { type: Object, required: true },
  copy: { type: Object, required: true },
  pricingPackages: { type: Array, default: () => [] },
  addons: { type: Array, default: () => [] },
  maintenance: { type: Array, default: () => [] },
  selectedLocale: { type: String, default: 'zh-TW' }
});

const emit = defineEmits(['navigate', 'contact']);

const go = (page) => emit('navigate', page);
const openContact = () => emit('contact');

const heroImage = computed(
  () => props.brand?.assets?.hero || props.brand?.assets?.secondary
);
const lookbook = computed(() => props.brand?.assets?.elements ?? []);

const navLabelMap = computed(() => {
  const map = {};
  (props.navItems ?? []).forEach((item) => {
    if (item?.id) {
      map[item.id] = item.label;
    }
  });
  const templateNav = props.copy?.templateNav ?? {};
  return {
    home: map.home ?? templateNav.home ?? 'Home',
    pricing: map.pricing ?? templateNav.pricing ?? 'Pricing',
    book: templateNav.book ?? 'Book'
  };
});

const selectLookLabel = computed(() => props.copy?.accessibility?.selectLook ?? 'Select look');

const activeIndex = ref(0);

const dialItems = computed(() => {
  const items = lookbook.value && lookbook.value.length ? lookbook.value : [];
  const safe = items.length ? items : [{ image: heroImage.value }, { image: heroImage.value }];

  const maxItems = 10;
  const repeated = [];
  while (repeated.length < maxItems) repeated.push(...safe);
  return repeated.slice(0, maxItems);
});

const currentLook = computed(() => dialItems.value?.[activeIndex.value] || null);

const currentLookLabel = computed(() =>
  currentLook.value?.label || currentLook.value?.name || props.copy.home?.tagFallback || 'Look'
);

const currentLookBody = computed(() =>
  currentLook.value?.description ||
  currentLook.value?.body ||
  props.copy.home?.body ||
  'Curated racks, appointment styling, and night window installs tuned to the streetlights outside.'
);

const currentLookNotes = computed(() => {
  const notes = currentLook.value?.notes || currentLook.value?.bullets || currentLook.value?.highlights;
  if (Array.isArray(notes) && notes.length) return notes.slice(0, 3);

  return [
    currentLook.value?.season || 'Capsule release',
    currentLook.value?.fit || 'Cut for movement',
    currentLook.value?.material || 'Textured neutrals'
  ].filter(Boolean).slice(0, 3);
});

const rotateDial = (direction) => {
  const max = dialItems.value.length || 1;
  activeIndex.value = (activeIndex.value + direction + max) % max;
};

// Wheel throttle so fast scroll doesn't skip many steps (which causes “inward chord” motion)
const wheelAccum = ref(0);
let wheelLock = false;

const onDialWheel = (e) => {
  if (e && typeof e.preventDefault === 'function') e.preventDefault();

  wheelAccum.value += e?.deltaY || 0;

  const threshold = 240; // higher = slower / less sensitive
  if (Math.abs(wheelAccum.value) < threshold) return;

  if (wheelLock) return;
  wheelLock = true;

  rotateDial(wheelAccum.value > 0 ? 1 : -1);
  wheelAccum.value = 0;

  window.setTimeout(() => {
    wheelLock = false;
  }, 180);
};

/**
 * Ellipse orbit (track only), rotated to 45deg diagonal and mirrored on Y-axis (flip left/right).
 * Thumbs remain upright because we only translate; no rotation is applied to the thumb itself.
 */
const thumbStyle = (i) => {
  const count = dialItems.value.length || 1;

  // ellipse radii
  const rx = 300;
  const ry = 220;

  // keep active at 12 o'clock
  const step = (Math.PI * 2) / count;
  const a = (i - activeIndex.value) * step;

  // base ellipse point
  const x = Math.sin(a) * rx;
  const y = -Math.cos(a) * ry;

  // rotate track by -45deg
  const theta = -Math.PI / 4;
  const xr0 = x * Math.cos(theta) - y * Math.sin(theta);
  const yr = x * Math.sin(theta) + y * Math.cos(theta);

  // mirror on Y-axis (flip left/right)
  const xr = -xr0;

  return {
    '--x': `${xr}px`,
    '--y': `${yr}px`
  };
};
</script>

<template>
  <section
    class="template-shell seoul-runway"
    :data-template="templateId"
    :style="{ backgroundImage: `url(${fittingRoomHero})` }"
  >
    <main class="sr-main">
      <header class="sr-topbar">
        <div class="sr-topbar-left">
          <p class="sr-kicker">{{ copy.home?.kicker || brand?.name || 'Seoul Runway' }}</p>
          <h1 class="sr-title">{{ copy.home?.headline || 'A show, not a scroll.' }}</h1>
          <p class="sr-lede">{{ copy.home?.subhead || 'Spin the rack. Land on a look. Commit.' }}</p>
        </div>

        <nav class="sr-menu" aria-label="Template pages">
          <button
            type="button"
            class="sr-menu-btn"
            :aria-current="activePage === 'home' || !activePage ? 'page' : undefined"
            @click="go('home')"
          >
            {{ navLabelMap.home }}
          </button>
          <button
            type="button"
            class="sr-menu-btn"
            :aria-current="activePage === 'pricing' ? 'page' : undefined"
            @click="go('pricing')"
          >
            {{ navLabelMap.pricing }}
          </button>
          <button type="button" class="sr-menu-btn sr-menu-cta" @click="openContact">
            {{ navLabelMap.book }}
          </button>
        </nav>
      </header>

      <!-- LANDING -->
      <article v-if="!activePage || activePage === 'home'" class="sr-home">
        <section class="sr-home-layout">
          <aside class="sr-look-card" aria-live="polite">
            <h2 class="sr-look-title">{{ currentLookLabel }}</h2>
            <p class="sr-body">{{ currentLookBody }}</p>

            <ul class="sr-notes" v-if="currentLookNotes.length">
              <li v-for="(note, n) in currentLookNotes" :key="`${activeIndex}-${n}`" class="sr-note">
                {{ note }}
              </li>
            </ul>

            <div class="sr-tags" v-if="lookbook.length">
              <span v-for="look in lookbook.slice(0, 5)" :key="look.id || look.label" class="sr-tag">
                {{ look.label || copy.home?.tagFallback || 'Drop' }}
              </span>
            </div>
          </aside>

          <div class="sr-column sr-dial-column">
            <div class="sr-dial" @wheel.prevent="onDialWheel">
              <div
                class="sr-dial-ambient"
                :style="{ backgroundImage: `url(${dialItems[activeIndex]?.image})` }"
                aria-hidden="true"
              />
              <div class="sr-dial-center">
                <div class="sr-dial-main" :style="{ backgroundImage: `url(${dialItems[activeIndex]?.image})` }">
                  <div class="sr-dial-main-overlay" />
                  <p class="sr-dial-main-label">
                    {{ dialItems[activeIndex]?.label || 'Look' }}
                  </p>
                </div>
              </div>

              <div class="sr-dial-ring">
                <button
                  v-for="(item, i) in dialItems"
                  :key="i"
                  type="button"
                  class="sr-dial-thumb"
                  :style="thumbStyle(i)"
                  @click="activeIndex = i"
                  :aria-label="selectLookLabel"
                >
                  <span class="sr-dial-thumb-img" :style="{ backgroundImage: `url(${item.image})` }" />
                </button>
              </div>
            </div>
          </div>
        </section>
      </article>

      <!-- PRICING -->
      <article v-else-if="activePage === 'pricing'" class="sr-panel sr-pricing">
        <PricingPanel
          :brand="brand"
          :copy="copy.pricing"
          :pricing-packages="pricingPackages"
          :addons="addons"
          :maintenance="maintenance"
          :pricing-locale="selectedLocale"
        />
      </article>

      <!-- PLACEHOLDER -->
      <article v-else class="sr-panel sr-placeholder">
        <h2>{{ copy.placeholder?.heading }}</h2>
        <p class="sr-body sr-muted">{{ copy.placeholder?.intro }}</p>
      </article>
    </main>
  </section>
</template>

<style scoped>
.template-shell {
  border-radius: var(--radiusLg);
  overflow: hidden;
  border: 1px solid color-mix(in srgb, var(--accent) 55%, transparent);
  background-color: rgba(15, 23, 42, 0.7);
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  position: relative;
}

.seoul-runway::before {
  content: "";
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at 0% 0%, rgba(15, 23, 42, 0.55), rgba(15, 23, 42, 0.8));
  pointer-events: none;
}

.sr-main {
  position: relative;
  z-index: 1;
  padding: 0 clamp(1.75rem, 4vw, 3rem) clamp(2rem, 4vw, 3rem);
  min-height: clamp(720px, 86vh, 980px);
}

.sr-panel {
  border-radius: var(--radiusLg);
  padding: clamp(1.5rem, 3vw, 2.25rem);
  background: radial-gradient(circle at 0% 0%, rgba(15, 23, 42, 0.98), rgba(15, 23, 42, 1));
  border: 1px solid rgba(30, 64, 175, 0.6);
  box-shadow:
    0 18px 45px rgba(15, 23, 42, 0.95),
    0 0 0 1px rgba(15, 23, 42, 0.9);
  color: #e5e7eb;
}

.sr-home {
  margin-top: clamp(1.5rem, 3vw, 2.25rem);
}

/* Top hero / menu */
.sr-topbar {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 1.25rem;
  align-items: end;
  margin-top: clamp(1.25rem, 3vw, 2rem);
}

.sr-topbar-left {
  max-width: 56ch;
}

.sr-kicker {
  text-transform: uppercase;
  letter-spacing: 0.22em;
  font-size: 0.78rem;
  opacity: 0.88;
  margin: 0 0 0.6rem;
}

.sr-title {
  font-size: clamp(1.75rem, 3.4vw, 2.35rem);
  letter-spacing: -0.02em;
  margin: 0;
}

.sr-lede {
  margin: 0.65rem 0 0;
  color: rgba(226, 232, 240, 0.92);
}

.sr-menu {
  display: flex;
  gap: 0.6rem;
  align-items: center;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.sr-menu-btn {
  border-radius: 999px;
  padding: 0.6rem 0.95rem;
  border: 1px solid rgba(226, 232, 240, 0.22);
  background: rgba(15, 23, 42, 0.55);
  color: #f9fafb;
  cursor: pointer;
}

.sr-menu-btn:hover {
  background: rgba(15, 23, 42, 0.78);
}

.sr-menu-btn[aria-current="page"] {
  border-color: rgba(226, 232, 240, 0.42);
  background: rgba(15, 23, 42, 0.78);
}

.sr-menu-cta {
  border-color: rgba(30, 64, 175, 0.65);
  background: rgba(30, 64, 175, 0.22);
}

.sr-menu-cta:hover {
  background: rgba(30, 64, 175, 0.32);
}

/* HOME LAYOUT */
.sr-home-layout {
  display: grid;
  grid-template-columns: minmax(0, 260px) minmax(0, 1.4fr);
  gap: clamp(1.5rem, 3.2vw, 2.5rem);
  align-items: end;
  margin-top: clamp(1.25rem, 3vw, 2rem);
}

.sr-home-layout > * {
  min-width: 0;
}

/* Left-side look card */
.sr-look-card {
  border-radius: var(--radiusLg);
  padding: clamp(1.25rem, 2.4vw, 1.8rem);
  background: radial-gradient(circle at 0% 0%, rgba(15, 23, 42, 0.92), rgba(15, 23, 42, 0.98));
  border: 1px solid rgba(226, 232, 240, 0.16);
  box-shadow:
    0 22px 70px rgba(0, 0, 0, 0.55),
    0 0 0 1px rgba(15, 23, 42, 0.85);
  color: #f9fafb;

  min-height: 420px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  width: 100%;
  max-width: 260px;
}

.sr-look-title {
  font-size: 1.15rem;
  margin: 0 0 0.55rem;
  letter-spacing: -0.01em;
}

.sr-body {
  max-width: 28ch;
}

.sr-notes {
  margin-top: 1.25rem;
  padding-left: 1.1rem;
}

.sr-note {
  margin: 0.35rem 0;
}

.sr-tags {
  margin-top: auto;
}

.sr-tag {
  display: inline-flex;
  margin-right: 0.5rem;
  margin-top: 0.5rem;
  padding: 0.25rem 0.6rem;
  border-radius: 999px;
  border: 1px solid rgba(226, 232, 240, 0.14);
  background: rgba(15, 23, 42, 0.55);
  font-size: 0.82rem;
  color: rgba(226, 232, 240, 0.92);
}

.sr-dial-column {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 520px;
}

.sr-dial {
  position: relative;
  width: min(60vw, 560px);
  aspect-ratio: 1 / 1;
  max-width: 100%;
  isolation: isolate;
}

.sr-dial::before {
  content: "";
  position: absolute;
  inset: -10%;
  background: radial-gradient(circle, rgba(226, 232, 240, 0.12), transparent 58%);
  filter: blur(8px);
  opacity: 0.65;
  pointer-events: none;
  z-index: 0;
}

.sr-dial-ambient {
  position: absolute;
  inset: 12%;
  border-radius: 999px;
  background-size: cover;
  background-position: center;
  filter: blur(18px) brightness(0.78) saturate(0.9) contrast(1.05);
  opacity: 0.55;
  transform: scale(1.12);
  transition: opacity 240ms ease-out, transform 520ms ease-out;
  z-index: 1;
  pointer-events: none;

  -webkit-mask-image: radial-gradient(circle, rgba(0,0,0,1) 35%, rgba(0,0,0,0) 72%);
  mask-image: radial-gradient(circle, rgba(0,0,0,1) 35%, rgba(0,0,0,0) 72%);
}

.sr-dial:hover .sr-dial-ambient {
  opacity: 0.62;
  transform: scale(1.16);
}

.sr-dial-center {
  position: absolute;
  inset: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 6;
}

.sr-dial-main {
  width: 54%;
  aspect-ratio: 3 / 4;
  border-radius: 30px;
  background-size: cover;
  background-position: center;
  overflow: hidden;
  box-shadow:
    0 32px 85px rgba(0, 0, 0, 0.95),
    0 0 0 2px rgba(15, 23, 42, 0.95);
  position: relative;
}

.sr-dial-main-overlay {
  position: absolute;
  inset: 0;
  background: linear-gradient(to top, rgba(15, 23, 42, 0.9), transparent 60%);
}

.sr-dial-main-label {
  position: absolute;
  left: 0.75rem;
  bottom: 0.6rem;
  font-size: 0.85rem;
  letter-spacing: 0.03em;
}

.sr-dial-ring {
  position: absolute;
  inset: 0;
  z-index: 2;
  pointer-events: none;
}

.sr-dial-thumb {
  position: absolute;
  left: 50%;
  top: 50%;
  width: 96px;
  height: 96px;
  padding: 0;
  border: 0;
  background: transparent;
  pointer-events: auto;
  cursor: pointer;

  transform: translate3d(-50%, -50%, 0) translate3d(var(--x), var(--y), 0);
  transition: transform 560ms cubic-bezier(0.22, 0.61, 0.36, 1);
  will-change: transform;
  backface-visibility: hidden;
}

.sr-dial-thumb-img {
  display: block;
  width: 96px;
  height: 96px;
  border-radius: 22px;
  background-size: cover;
  background-position: center;
  box-shadow:
    0 18px 45px rgba(0, 0, 0, 0.95),
    0 0 0 2px rgba(15, 23, 42, 0.95);
}

/* PLACEHOLDER */
.sr-placeholder {
  margin-top: clamp(1.5rem, 3vw, 2.25rem);
}

/* Responsive */
@media (max-width: 980px) {
  .sr-topbar {
    grid-template-columns: 1fr;
    align-items: start;
  }

  .sr-menu {
    justify-content: flex-start;
  }

  .sr-home-layout {
    grid-template-columns: 1fr;
    align-items: stretch;
  }

  .sr-dial-column {
    min-height: 460px;
  }

  .sr-look-card {
    min-height: unset;
    max-width: none;
  }
}

@media (max-width: 720px) {
  .sr-main {
    padding-inline: 1.25rem;
  }
}
</style>
