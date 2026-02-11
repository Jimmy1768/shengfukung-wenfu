<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import EventCard from '@/components/site/EventCard.vue';
import { useHeroImage, useTempleContent, useTempleEvents } from '@/app/siteContent.js';
import { formatEventCard, statusLabel } from '@/utils/events.js';

const heroImage = useHeroImage('events');
const siteContent = useTempleContent();
const eventList = useTempleEvents();

const defaultLocation = computed(
  () => siteContent.data?.contact?.addressZh || '本廟'
);

const normalizedEvents = computed(() => {
  if (!eventList.value?.length) return [];
  return eventList.value.map((event) =>
    formatEventCard(event, {
      defaultLocation: defaultLocation.value,
      registrationAction: 'event'
    })
  );
});

const eventCount = computed(() => eventList.value?.length || 0);

const emptyStateMessage = computed(() =>
  eventCount.value
    ? ''
    : '目前沒有開放的法會供品，請稍後再查看或關注最新消息。'
);

const hintMessage = computed(() => {
  if (!eventCount.value) {
    return statusLabel('upcoming');
  }
  return `共有 ${eventCount.value} 檔法會供品進行中或即將開始。`;
});
</script>

<template>
  <div>
    <PageHero
      title="法會供品"
      subtitle="未登入也能瀏覽法會供品；登入後可報名與付款（稍後接 Rails）。"
      :image-url="heroImage"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle
          title="近期法會供品"
          subtitle="法會供品資訊由後台供奉項目管理，顯示目前開放或即將開放的檔期。"
        />
        <div v-if="normalizedEvents.length" class="grid">
          <EventCard v-for="event in normalizedEvents" :key="event.slug" :item="event" />
        </div>
        <div v-else class="empty">{{ emptyStateMessage }}</div>

        <div class="hint">
          法會供品進度：{{ hintMessage }}
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.empty {
  padding: var(--spacing-lg);
  text-align: center;
  opacity: 0.75;
  border-radius: var(--radius-lg);
  border: 1px dashed color-mix(in srgb, var(--border) 75%, transparent);
}

.hint {
  margin-top: var(--spacing-sm);
  opacity: 0.65;
  font-size: 13px;
  line-height: 1.6;
}
</style>
