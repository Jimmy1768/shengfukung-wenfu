<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
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

// This page is the index: one card per album, opening the album's own page. It
// used to render every photo of every album inline as a strip of 90px crops,
// so a visitor scrolled past dozens of cropped fragments and could not reach
// any album as a thing in itself.
function coverPhoto(entry) {
  return (entry.photo_urls || [])[0] || '';
}

function photoCount(entry) {
  return (entry.photo_urls || []).length;
}
</script>

<template>
  <div>
    <PageHero
      title="活動回顧"
      subtitle="過往法會或社群活動的圖文記錄，方便重溫與分享。"
      :image-url="heroImage"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle
          title="過往活動"
          subtitle="點選相簿即可瀏覽該場活動的所有照片。"
        />
        <div v-if="hasEntries" class="album-list">
          <router-link
            v-for="entry in entries"
            :key="entry.id || entry.title"
            class="album-card"
            :to="`/archive/${entry.id}`"
          >
            <div class="album-card__cover">
              <img
                v-if="coverPhoto(entry)"
                class="album-card__image"
                :src="coverPhoto(entry)"
                :alt="`${entry.title} 封面`"
                loading="lazy"
              />
              <div v-else class="album-card__placeholder">尚無照片</div>
            </div>
            <div class="album-card__copy">
              <h3 class="album-card__title">{{ entry.title }}</h3>
              <p class="album-card__meta">
                活動日期：{{ formatEventDate(entry.event_date) }}
                <span v-if="photoCount(entry)"> · {{ photoCount(entry) }} 張照片</span>
              </p>
              <p v-if="entry.body" class="album-card__body">{{ entry.body }}</p>
              <span class="album-card__cta">瀏覽相簿 →</span>
            </div>
          </router-link>
        </div>
        <div v-else class="empty">
          目前尚未發布活動回顧，請稍後再查看。
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.album-list {
  display: grid;
  gap: var(--spacing-md);
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
}

.album-card {
  display: flex;
  flex-direction: column;
  overflow: hidden;
  text-decoration: none;
  color: inherit;
  border-radius: var(--radius-lg);
  border: 1px solid color-mix(in srgb, var(--border) 80%, transparent);
  background: var(--surface-raised);
  transition: transform 140ms ease, box-shadow 140ms ease;
}

.album-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 24px rgb(0 0 0 / 10%);
}

.album-card:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

/* One cover, at a readable size -- the album's own first photo, never a
   temple-level default dressed up as this album's picture. */
.album-card__cover {
  aspect-ratio: 4 / 3;
  background: var(--surface-muted);
}

.album-card__image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.album-card__placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0.6;
  font-size: 13px;
}

.album-card__copy {
  padding: var(--spacing-sm) var(--spacing-md) var(--spacing-md);
  display: flex;
  flex-direction: column;
  gap: var(--spacing-xs);
}

.album-card__title {
  margin: 0;
  font-size: 1.05rem;
}

.album-card__meta {
  margin: 0;
  font-size: 13px;
  opacity: 0.75;
}

.album-card__body {
  margin: 0;
  font-size: 14px;
  line-height: 1.6;
  opacity: 0.85;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.album-card__cta {
  margin-top: auto;
  padding-top: var(--spacing-xs);
  font-weight: 600;
  font-size: 14px;
  color: var(--accent);
}

.empty {
  padding: var(--spacing-md);
  text-align: center;
  opacity: 0.78;
  border-radius: var(--radius-lg);
  border: 1px dashed color-mix(in srgb, var(--border) 80%, transparent);
}
</style>
