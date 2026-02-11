<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import {
  useHeroImage,
  useTempleArchive
} from '@/app/siteContent.js';

const heroImage = useHeroImage('archive');
const archiveFeed = useTempleArchive();

function formatEventDate(value) {
  if (!value) return '日期待定';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleDateString('zh-TW');
}

const entries = computed(() => archiveFeed.value || []);
const hasEntries = computed(() => entries.value.length > 0);
</script>

<template>
  <div>
    <PageHero
      title="法會供品回顧"
      subtitle="過往法會供品做成『可被搜尋 / 可被分享』的圖文頁面（SEO + slug）。"
      :image-url="heroImage"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle
          title="過往供奉"
          subtitle="從後台新增的圖文記錄會顯示在這裡。"
        />
        <div v-if="hasEntries" class="stack">
          <SimpleCard
            v-for="entry in entries"
            :key="entry.id || entry.title"
            :title="entry.title"
            :body="entry.body"
          >
            <div class="meta">供奉日期：{{ formatEventDate(entry.event_date) }}</div>
            <div
              v-if="entry.photo_urls?.length"
              class="photos"
            >
              <img
                v-for="(url, index) in entry.photo_urls"
                :key="`${entry.id || entry.title}-${index}`"
                class="photo"
                :src="url"
                :alt="`${entry.title} 照片 ${index + 1}`"
                loading="lazy"
              />
            </div>
          </SimpleCard>
        </div>
        <div v-else class="empty">
          目前尚未發布供奉回顧，請稍後再查看。
        </div>
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

.photos {
  margin-top: var(--spacing-sm);
  display: grid;
  gap: var(--spacing-xs);
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
}

.photo {
  width: 100%;
  height: 90px;
  object-fit: cover;
  border-radius: var(--radius-md);
  border: 1px solid color-mix(in srgb, var(--border) 80%, transparent);
}

.empty {
  padding: var(--spacing-md);
  text-align: center;
  opacity: 0.78;
  border-radius: var(--radius-lg);
  border: 1px dashed color-mix(in srgb, var(--border) 80%, transparent);
}
</style>
