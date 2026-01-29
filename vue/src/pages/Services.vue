<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import { useHeroImage, useTempleEvents } from '@/app/siteContent.js';
import { formatCurrency, formatDateRange, statusLabel } from '@/utils/events.js';

const heroImage = useHeroImage('services');
const eventList = useTempleEvents();

const offerings = computed(() => {
  if (!eventList.value?.length) return [];
  return eventList.value.map((event) => ({
    slug: event.slug,
    title: event.title,
    description: event.description || '從後台編輯的服務說明將顯示於此。',
    price: formatCurrency(event.price_cents, event.currency),
    schedule: formatDateRange(event.starts_on, event.ends_on),
    status: statusLabel(event.timeline_status)
  }));
});

const hasOfferings = computed(() => offerings.value.length > 0);
</script>

<template>
  <div>
    <PageHero
      title="參拜 / 服務"
      subtitle="展示目前開放的 offerings（線上或現場服務），含檔期與費用。"
      :image-url="heroImage"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle title="服務項目" subtitle="由後台 offerings 管理，可依檔期即時更新。" />

        <div v-if="hasOfferings" class="grid">
          <SimpleCard
            v-for="item in offerings"
            :key="item.slug"
            :title="item.title"
          >
            <div class="info">
              <div>狀態：{{ item.status }}</div>
              <div>費用：約 {{ item.price }}</div>
              <div>期間：{{ item.schedule }}</div>
              <p>{{ item.description }}</p>
              <router-link class="link" :to="`/events/${item.slug}`">查看詳情 →</router-link>
            </div>
          </SimpleCard>
        </div>
        <div v-else class="empty">
          目前沒有公開的服務項目，請稍後再查看或直接聯絡廟方。
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

.link {
  color: var(--primary);
  font-weight: 700;
  text-decoration: none;
}

.empty {
  padding: var(--spacing-lg);
  text-align: center;
  opacity: 0.75;
  border-radius: var(--radius-lg);
  border: 1px dashed color-mix(in srgb, var(--border) 75%, transparent);
}
</style>
