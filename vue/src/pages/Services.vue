<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import { useHeroImage, useTempleServices } from '@/app/siteContent.js';
import { formatCurrency } from '@/utils/events.js';

const heroImage = useHeroImage('services');
const serviceList = useTempleServices();

const offerings = computed(() => {
  if (!serviceList.value?.length) return [];
  return serviceList.value.map((service) => ({
    slug: service.slug,
    title: service.title,
    description: service.description || '此服務的詳細說明將在近期更新。',
    price: formatCurrency(service.price_cents, service.currency),
    period: service.period_label || '長期服務',
    status: service.available_from ? '開放中' : '常態服務'
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
              <div>期間：{{ item.period }}</div>
              <p>{{ item.description }}</p>
              <router-link class="link" :to="`/services/${item.slug}`">查看詳情 →</router-link>
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
