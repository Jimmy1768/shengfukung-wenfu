<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import EventCard from '@/components/site/EventCard.vue';
import project from '@/app/project.js';
import {
  useHeroImage,
  useTempleContent,
  useTempleEvents,
  useTempleNews
} from '@/app/siteContent.js';
import { formatEventCard } from '@/utils/events.js';

const siteContent = useTempleContent();
const heroImage = useHeroImage('home');
const events = useTempleEvents();
const newsFeed = useTempleNews();

const heroTitle = computed(
  () => siteContent.data?.tagline || project.tagline || project.name
);
const heroSubtitle = computed(
  () =>
    siteContent.data?.hero_copy ||
    `用清楚的方式呈現 ${project.name} 的活動資訊、祈福服務與公告；讓長輩也能快速找到時間、地點、方式。`
);

// No placeholder fallback: an empty object renders nothing while the fetch is
// in flight, rather than the admin-facing defaults a visitor used to see.
const contactInfo = computed(() => siteContent.data?.contact || {});
const defaultLocation = computed(
  () => contactInfo.value.addressZh || '本廟'
);
// Real events only. This used to invent two -- a new year blessing on
// 2026/01/05 and a lantern offering on 2026/02/12, each marked as a sample in
// its title and each carrying a working registration link. A visitor could read
// a date, a place and "可報名" for a service that did not exist, and the temple
// would hear about it. A temple with no events now shows no events, and the
// section hides with them.
const upcoming = computed(() => {
  if (!events.value?.length) {
    return [];
  }

  return events.value.slice(0, 2).map((event) =>
    formatEventCard(event, {
      defaultLocation: defaultLocation.value
    })
  );
});

function formatDate(value) {
  if (!value) return '日期待定';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleDateString('zh-TW');
}

const latestNews = computed(() =>
  (newsFeed.value || []).slice(0, 2).map((post) => ({
    ...post,
    dateLabel: formatDate(post.published_at)
  }))
);
</script>

<template>
  <div>
    <PageHero
      :title="heroTitle"
      :subtitle="heroSubtitle"
      :image-url="heroImage"
      ctaText="查看活動資訊"
      ctaTo="/events"
    />

    <section v-if="upcoming.length > 0" class="section">
      <div class="wrap">
        <SectionTitle
          title="活動資訊速覽"
          subtitle="先線上了解法會或社群聚會的時間、地點與名額，再登入完成報名。"
        />

        <div class="grid">
          <EventCard v-for="e in upcoming" :key="e.slug" :item="e" />
        </div>

        <div class="more">
          <router-link class="link" to="/events">查看全部活動 →</router-link>
        </div>
      </div>
    </section>

    <section class="section alt">
      <div class="wrap">
        <SectionTitle
          title="公告 / 最新消息"
          subtitle="法會報名、祈福服務與重要提醒都會同步在這裡。"
        />

        <div class="grid2">
          <SimpleCard
            v-for="post in latestNews"
            :key="post.id || post.title"
            :title="post.title"
            :body="post.body"
          >
            <div class="meta">發佈：{{ post.dateLabel }}</div>
          </SimpleCard>

          <SimpleCard v-if="!latestNews.length" title="最新消息" body="目前尚無公告，之後會顯示後台新增的內容。">
            <router-link class="link" to="/news">查看全部公告 →</router-link>
          </SimpleCard>
        </div>
        <div class="more">
          <router-link class="link" to="/news">前往最新消息 →</router-link>
        </div>
      </div>
    </section>

  </div>
</template>

<style scoped>
.link {
  color: var(--primary);
  font-weight: 700;
  text-decoration: none;
}

.meta {
  margin-top: var(--spacing-xs);
  font-size: 13px;
  opacity: 0.75;
}
</style>
