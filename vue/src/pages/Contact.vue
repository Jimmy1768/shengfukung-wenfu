<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import project from '@/app/project.js';
import { useTempleContent } from '@/app/siteContent.js';
import placeholders from '@shared/app_constants/temple_profile_placeholders.json';

const siteContent = useTempleContent();
const contactPlaceholder = placeholders.contact || {};
const servicePlaceholder = placeholders.service_times || {};
const contact = computed(() => siteContent.data?.contact || contactPlaceholder);
const heroSubtitle = computed(
  () =>
    siteContent.data?.service_times?.notes ||
    servicePlaceholder.notes ||
    `地址、地圖、開放時間、停車與大眾運輸（${project.name} Placeholder）`
);
</script>

<template>
  <div>
    <PageHero title="聯絡 / 交通" :subtitle="heroSubtitle" />

    <section class="section">
      <div class="wrap">
        <div class="grid">
          <SimpleCard title="聯絡資訊">
            <div class="info">
              <div>電話：{{ contact.phone }}</div>
              <div>地址：{{ contact.addressZh }}</div>
              <div v-if="contact.plusCode">Plus Code：{{ contact.plusCode }}</div>
              <a v-if="contact.mapUrl" class="map-link" :href="contact.mapUrl" target="_blank" rel="noreferrer">
                在 Google 地圖開啟
              </a>
            </div>
          </SimpleCard>
          <SimpleCard title="地址 / 地圖">
            <div class="info">
              <div>{{ contact.addressEn }}</div>
              <a v-if="contact.mapUrl" class="map-link" :href="contact.mapUrl" target="_blank" rel="noreferrer">
                Directions（Google Maps）
              </a>
            </div>
          </SimpleCard>
        </div>

        <div class="sp" />

        <SectionTitle title="交通方式" subtitle="把最常見的 2–3 種方式寫清楚。" />
        <div class="article">
          <p>（Placeholder）捷運：XX 站 → 走路 10 分鐘。</p>
          <p>（Placeholder）公車：XX 線 → XX 站下車。</p>
          <p>（Placeholder）停車：附近停車場位置與費用提示。</p>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.info {
  display: grid;
  gap: var(--spacing-xs);
  font-size: 14px;
  line-height: 1.7;
}

.map-link {
  color: var(--primary);
  font-weight: 700;
}
</style>
