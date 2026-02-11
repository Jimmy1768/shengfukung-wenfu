<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import { useHeroImage, useTempleServices } from '@/app/siteContent.js';
import { formatCurrency } from '@/utils/events.js';
import { buildRegistrationLink } from '@/utils/accountLinks.js';

const heroImage = useHeroImage('services');
const serviceList = useTempleServices();

const offerings = computed(() => {
  if (!serviceList.value?.length) return [];
  return serviceList.value.map((service) => ({
    slug: service.slug,
    title: service.title,
    description: service.description || '祈福供品的詳細說明將在近期更新。',
    price: formatCurrency(service.price_cents, service.currency),
    period: service.period_label || '長期祈福',
    status: service.available_from ? '開放中' : '常態祈福',
    ctaHref: buildRegistrationLink('service', service.slug)
  }));
});

const hasOfferings = computed(() => offerings.value.length > 0);
</script>

<template>
  <div>
    <PageHero
      title="祈福供品"
      subtitle="展示目前開放的祈福供品（線上或現場服務），含檔期與費用。"
      :image-url="heroImage"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle title="祈福供品" subtitle="由後台供奉項目管理，可依檔期即時更新。" />

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
              <a class="link" :href="item.ctaHref">登入並報名 →</a>
            </div>
          </SimpleCard>
        </div>
        <div v-else class="empty">
          目前沒有公開的祈福供品，請稍後再查看或直接聯絡廟方。
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
