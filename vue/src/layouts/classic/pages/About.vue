<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import { useHeroImage, useTempleContent } from '@/app/siteContent.js';
import placeholders from '@shared/app_constants/temple_profile_placeholders.json';

const siteContent = useTempleContent();
const heroImage = useHeroImage('about');
const aboutPlaceholder = placeholders.about || {};

const aboutContent = computed(
  () => siteContent.data?.about || aboutPlaceholder
);

const heroSubtitle = computed(
  () =>
    aboutContent.value?.hero_subtitle ||
    aboutPlaceholder.hero_subtitle ||
    '把歷史、主祀神明、參拜禮儀，用清楚的段落呈現（Placeholder）。'
);

const sectionTitle = computed(
  () => aboutContent.value?.section_title || '本廟簡介'
);

const aboutCards = computed(() => {
  const cards = aboutContent.value?.cards;
  if (Array.isArray(cards) && cards.length > 0) {
    return cards;
  }
  return (
    aboutPlaceholder.cards || [
      {
        title: '沿革（Placeholder）',
        body: '例如：創建年代、地方故事、重要里程碑。'
      },
      {
        title: '主祀 / 配祀（Placeholder）',
        body: '例如：主神、陪祀神祇、簡短介紹與參拜重點。'
      },
      {
        title: '參拜禮儀（Placeholder）',
        body: '例如：入廟動線、禁忌提醒、拍照注意事項。'
      }
    ]
  );
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
        <SectionTitle :title="sectionTitle" />
        <div class="stack">
          <SimpleCard
            v-for="(card, index) in aboutCards"
            :key="card.title || index"
            :title="card.title"
            :body="card.body"
          />
        </div>
      </div>
    </section>
  </div>
</template>
