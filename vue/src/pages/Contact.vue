<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import project from '@/app/project.js';
import { useHeroImage, useTempleContent } from '@/app/siteContent.js';
import placeholders from '@shared/app_constants/temple_profile_placeholders.json';

const siteContent = useTempleContent();
const contactPlaceholder = placeholders.contact || {};
const servicePlaceholder = placeholders.service_times || {};
const visitPlaceholder = placeholders.visit_info || {};
const contact = computed(() => siteContent.data?.contact || contactPlaceholder);
const serviceTimes = computed(
  () => siteContent.data?.service_times || servicePlaceholder
);
const visitInfo = computed(
  () => siteContent.data?.visit_info || visitPlaceholder
);
const heroSubtitle = computed(
  () =>
    siteContent.data?.service_times?.notes ||
    servicePlaceholder.notes ||
    `地址、地圖、開放時間、停車與大眾運輸（${project.name} Placeholder）`
);
const heroImage = useHeroImage('contact');
</script>

<template>
  <div>
    <PageHero
      title="聯絡 / 交通"
      :subtitle="heroSubtitle"
      :image-url="heroImage"
    />

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

        <SectionTitle
          title="開放時間"
          subtitle="依後台設定即時更新。"
        />
        <div class="grid">
          <SimpleCard title="平日">
            <div class="info">{{ serviceTimes.weekday }}</div>
          </SimpleCard>
          <SimpleCard title="假日 / 特殊日">
            <div class="info">{{ serviceTimes.weekend }}</div>
          </SimpleCard>
        </div>
        <div class="sp" />
        <SimpleCard title="備註">
          <div class="info">{{ serviceTimes.notes }}</div>
        </SimpleCard>

        <div class="sp" />

        <SectionTitle title="交通 / 停車" subtitle="在後台可隨時更新資訊，方便信眾掌握動線。" />
        <div class="grid">
          <SimpleCard title="交通方式">
            <div class="info">
              <p>{{ visitInfo.transportation }}</p>
              <a v-if="contact.mapUrl" class="map-link" :href="contact.mapUrl" target="_blank" rel="noreferrer">
                在 Google Maps 開啟導航 →
              </a>
            </div>
          </SimpleCard>

          <SimpleCard title="停車 / 提醒">
            <div class="info">
              <p>{{ visitInfo.parking }}</p>
            </div>
          </SimpleCard>
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
