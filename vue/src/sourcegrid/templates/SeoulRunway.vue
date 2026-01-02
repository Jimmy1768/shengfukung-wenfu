<script setup>
import { computed, ref } from 'vue';
import fittingRoomHero from '@/assets/media/clothing/clothing_fitting_area.png';
import PricingPanel from '../components/PricingPanel.vue';

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

const heroImage = computed(
  () => props.brand?.assets?.hero || props.brand?.assets?.secondary
);
const lookbook = computed(() => props.brand?.assets?.elements ?? []);

const activeIndex = ref(0);

const dialItems = computed(() => {
  const items = lookbook.value && lookbook.value.length
    ? lookbook.value
    : [];
  const safe = items.length ? items : [{ image: heroImage.value }, { image: heroImage.value }];
  const maxItems = 10;
  const repeated = [];
  while (repeated.length < maxItems) repeated.push(...safe);
  return repeated.slice(0, maxItems);
});

const rotateDial = (direction) => {
  const max = dialItems.value.length;
  activeIndex.value = (activeIndex.value + direction + max) % max;
};
</script>

<template>
  <section
    class="template-shell seoul-runway"
    :data-template="templateId"
    :style="{ backgroundImage: `url(${fittingRoomHero})` }"
  >
    <main class="sr-main">
      <!-- LANDING -->
      <article v-if="activePage === 'home'" class="sr-home">
        <section class="sr-home-layout">
          <div class="sr-column sr-column-copy">
            <h2>{{ copy.home?.headline || 'Edit-ready looks, boutique floor.' }}</h2>
            <p class="sr-body">
              {{ copy.home?.body || 'Curated racks, appointment styling, and night window installs tuned to the streetlights outside.' }}
            </p>
            <div class="sr-tags" v-if="lookbook.length">
              <span
                v-for="look in lookbook.slice(0, 5)"
                :key="look.id || look.label"
                class="sr-tag"
              >
                {{ look.label || copy.home?.tagFallback || 'Drop' }}
              </span>
            </div>
          </div>

          <div class="sr-column sr-dial-column">
            <div class="sr-dial" @wheel.prevent="rotateDial($event.deltaY > 0 ? 1 : -1)">
              <div class="sr-dial-center">
                <div
                  class="sr-dial-main"
                  :style="{ backgroundImage: `url(${dialItems[activeIndex]?.image})` }"
                >
                  <div class="sr-dial-main-overlay" />
                  <p class="sr-dial-main-label">
                    {{ dialItems[activeIndex]?.label || 'Look' }}
                  </p>
                </div>
              </div>

              <div class="sr-dial-ring">
                <div
                  v-for="(item, i) in dialItems"
                  :key="i"
                  class="sr-dial-thumb"
                  :style="{
                    '--i': i,
                    '--active': activeIndex
                  }"
                  @click="activeIndex = i"
                >
                  <div
                    class="sr-dial-thumb-img"
                    :style="{ backgroundImage: `url(${item.image})` }"
                  ></div>
                </div>
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
        />
      </article>

      <!-- PLACEHOLDER -->
      <article v-else class="sr-panel sr-placeholder">
        <h2>{{ copy.placeholder?.heading }}</h2>
        <p class="sr-body sr-muted">
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

/* HERO */

.sr-main {
  position: relative;
  z-index: 1;
  padding: 0 clamp(1.75rem, 4vw, 3rem) clamp(2rem, 4vw, 3rem);
}

/* MAIN */

.sr-main {
  padding: 0 clamp(1.75rem, 4vw, 3rem) clamp(2rem, 4vw, 3rem);
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

.sr-panel-header {
  display: grid;
  gap: 0.35rem;
  margin-bottom: 0.75rem;
}

.sr-mini-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  font-size: 0.78rem;
  opacity: 0.85;
}

.sr-body {
  font-size: 0.95rem;
  line-height: 1.6;
}

.sr-muted {
  color: rgba(148, 163, 184, 0.96);
}

/* HOME LAYOUT */

.sr-home-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  grid-template-rows: auto auto;
  gap: clamp(1.75rem, 3.5vw, 2.75rem);
}

.sr-column-copy h2 {
  font-size: 1.3rem;
}

.sr-column-copy {
  color: #f9fafb;
  max-width: 28rem;
  grid-column: 2;
  grid-row: 1;
  align-self: start;
  justify-self: end;
}

.sr-dial-column {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 440px;
  grid-column: 1;
  grid-row: 2;
  align-self: end;
  justify-self: start;
}

.sr-dial {
  position: relative;
  width: min(60vw, 560px);
  aspect-ratio: 1 / 1;
  max-width: 100%;
}

.sr-dial-center {
  position: absolute;
  inset: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 5;
}

.sr-dial-main {
  width: 62%;
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
  display: flex;
  justify-content: center;
  align-items: center;
  pointer-events: none;
}

.sr-dial-thumb {
  --radius: 220px;
  position: absolute;
  top: 50%;
  left: 50%;
  pointer-events: auto;
  transform:
    rotate(calc((var(--i) - var(--active)) * 36deg))
    translateY(calc(-1 * var(--radius)))
    rotate(calc((var(--active) - var(--i)) * 36deg));
  transition: transform 300ms ease-out;
}

.sr-dial-thumb-img {
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
  .sr-hero {
    grid-template-columns: minmax(0, 1fr);
  }

  .sr-home-layout {
    display: grid;
    grid-template-columns: minmax(0, 1fr) minmax(320px, 1.1fr);
    gap: clamp(1.75rem, 3.5vw, 2.75rem);
    align-items: center;
  }
}

@media (max-width: 720px) {
  .sr-main {
    padding-inline: 1.25rem;
  }

  .sr-hero {
    display: grid;
    grid-template-columns: minmax(260px, 0.9fr) minmax(320px, 1.1fr);
    gap: clamp(1.75rem, 4vw, 3rem);
    padding: clamp(1.75rem, 4vw, 3rem);
    align-items: stretch;
  }

  .sr-hero-image {
    border-radius: 32px;
    background-size: cover;
    background-position: center;
    box-shadow:
      0 28px 70px rgba(0, 0, 0, 0.9),
      0 0 0 1px rgba(15, 23, 42, 0.9);
    min-height: 360px;
    aspect-ratio: 3 / 5;
  }
}
</style>
