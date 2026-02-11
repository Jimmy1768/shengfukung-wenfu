<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import { useHeroImage, useTempleNews } from '@/app/siteContent.js';

const heroImage = useHeroImage('news');
const newsFeed = useTempleNews();

function formatDate(value) {
  if (!value) return '日期待定';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleDateString('zh-TW');
}

const posts = computed(() =>
  (newsFeed.value || []).map((post) => ({
    ...post,
    dateLabel: formatDate(post.published_at)
  }))
);
const hasPosts = computed(() => posts.value.length > 0);
</script>

<template>
  <div>
    <PageHero
      title="最新消息"
      subtitle="短公告即可：時間、重點、聯絡方式。"
      :image-url="heroImage"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle title="公告列表" subtitle="由後台管理的最新消息。" />
        <div v-if="hasPosts" class="stack">
          <SimpleCard
            v-for="post in posts"
            :key="post.id || post.title"
            :title="post.title"
            :body="post.body"
          >
            <div class="meta">發佈：{{ post.dateLabel }}</div>
          </SimpleCard>
        </div>
        <div v-else class="empty">目前尚無最新消息，可以稍後再查看。</div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.meta {
  margin-top: var(--spacing-xs);
  font-size: 13px;
  opacity: 0.75;
}

.empty {
  padding: var(--spacing-md);
  text-align: center;
  opacity: 0.78;
  border-radius: var(--radius-lg);
  border: 1px dashed color-mix(in srgb, var(--border) 80%, transparent);
}
</style>
