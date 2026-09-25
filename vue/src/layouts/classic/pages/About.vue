<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import { useHeroImage, useTempleContent } from '@/app/siteContent.js';

const siteContent = useTempleContent();
const heroImage = useHeroImage('about');

// Genuine default copy, kept as a literal rather than read from the shared
// placeholder JSON. It describes the page to a visitor and says nothing to an
// admin, so it is the one string here that is safe to show a temple that has
// written nothing -- and holding it locally is what lets this file have no
// fallback into the placeholder file at all.
const DEFAULT_HERO_SUBTITLE = '認識本廟的歷史、信仰與參拜文化。';

const aboutContent = computed(() => siteContent.data?.about || {});

const heroSubtitle = computed(
  () => aboutContent.value?.hero_subtitle || DEFAULT_HERO_SUBTITLE
);

const sectionTitle = computed(
  () => aboutContent.value?.section_title || '本廟簡介'
);

// A card is its title and its body together. A title with no body is scaffolding
// for an admin -- it tells a visitor a section exists and then shows them
// nothing -- so an empty-bodied card is dropped rather than rendered hollow.
// There is no invented card: a temple that has written no about content shows
// no cards, and the section below hides with them.
const aboutCards = computed(() => {
  const cards = aboutContent.value?.cards;
  if (!Array.isArray(cards)) {
    return [];
  }
  return cards.filter((card) => card && String(card.body || '').trim().length > 0);
});
</script>

<template>
  <div>
    <PageHero
      title="關於本廟"
      :subtitle="heroSubtitle"
      :image-url="heroImage"
    />

    <section class="section">
      <div class="wrap">
        <template v-if="aboutCards.length > 0">
          <SectionTitle :title="sectionTitle" />
          <div class="stack">
            <SimpleCard
              v-for="(card, index) in aboutCards"
              :key="card.title || index"
              :title="card.title"
              :body="card.body"
            />
          </div>
        </template>
      </div>
    </section>
  </div>
</template>
