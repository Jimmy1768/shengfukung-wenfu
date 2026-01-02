<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import EventCard from '@/components/site/EventCard.vue';
import { useTempleSections } from '@/app/siteContent.js';

const eventsSections = useTempleSections('events');

const upcomingSection = computed(() =>
  eventsSections.value.find((section) => section.section_type === 'event_list')
);

const upcoming = computed(
  () =>
    upcomingSection.value?.payload?.events || [
      {
        slug: 'new-year-blessing',
        month: 'JAN',
        day: '05',
        title: '新年祈福法會（Placeholder）',
        when: '2026/01/05 09:00',
        where: '本廟主殿',
        summary: '這裡是活動摘要。',
        badge: '可報名'
      },
      {
        slug: 'lantern-offering',
        month: 'FEB',
        day: '12',
        title: '點燈／祈福服務日（Placeholder）',
        when: '2026/02/12 10:00',
        where: '服務處',
        summary: '這裡是活動摘要。',
        badge: '名額有限'
      }
    ]
);
</script>

<template>
  <div>
    <PageHero
      title="活動 / 法會"
      subtitle="未登入也能瀏覽活動；登入後可報名與付款（稍後接 Rails）。"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle title="近期活動" subtitle="把『時間 / 地點 / 費用 / 名額』做成固定格式。" />
        <div class="grid">
          <EventCard v-for="e in upcoming" :key="e.slug" :item="e" />
        </div>

        <div class="hint">
          ※ 之後這裡會改成呼叫 Rails API，例如 /api/events?status=upcoming
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.hint {
  margin-top: var(--spacing-sm);
  opacity: 0.65;
  font-size: 13px;
  line-height: 1.6;
}
</style>
