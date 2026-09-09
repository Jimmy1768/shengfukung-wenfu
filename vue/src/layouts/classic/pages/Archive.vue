<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
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

// Photos rendered as 90px object-fit: cover thumbnails, with nothing to click,
// so an album could be seen but not viewed -- every picture arrived cropped and
// there was no way to open it. This gives the strip a viewer.
const viewer = ref({ photos: [], index: 0 });
const isViewerOpen = computed(() => viewer.value.photos.length > 0);
const currentPhoto = computed(() => viewer.value.photos[viewer.value.index] || null);
const viewerCaption = computed(() =>
  isViewerOpen.value ? `${viewer.value.title}（${viewer.value.index + 1}／${viewer.value.photos.length}）` : ''
);

function openViewer(entry, index) {
  viewer.value = { photos: entry.photo_urls || [], index, title: entry.title };
  lockScroll(true);
}

function closeViewer() {
  viewer.value = { photos: [], index: 0 };
  lockScroll(false);
}

// The overlay covers the viewport, so a wheel scroll behind it is invisible
// while it happens and then dumps the visitor somewhere else in the list the
// moment they close. The shift the vanishing scrollbar causes is hidden by the
// overlay itself.
function lockScroll(locked) {
  document.body.style.overflow = locked ? 'hidden' : '';
}

// Wraps, so the album can be browsed round rather than dead-ending at each end.
function step(offset) {
  const total = viewer.value.photos.length;
  if (!total) return;
  viewer.value.index = (viewer.value.index + offset + total) % total;
}

function onKeydown(event) {
  if (!isViewerOpen.value) return;
  if (event.key === 'Escape') closeViewer();
  if (event.key === 'ArrowRight') step(1);
  if (event.key === 'ArrowLeft') step(-1);
}

onMounted(() => window.addEventListener('keydown', onKeydown));
onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKeydown);
  lockScroll(false);
});
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
          subtitle="從後台新增的圖文記錄會顯示在這裡。"
        />
        <div v-if="hasEntries" class="stack">
          <SimpleCard
            v-for="entry in entries"
            :key="entry.id || entry.title"
            :title="entry.title"
            :body="entry.body"
          >
            <div class="meta">活動日期：{{ formatEventDate(entry.event_date) }}</div>
            <div
              v-if="entry.photo_urls?.length"
              class="photos"
            >
              <button
                v-for="(url, index) in entry.photo_urls"
                :key="`${entry.id || entry.title}-${index}`"
                type="button"
                class="photo-button"
                :aria-label="`檢視 ${entry.title} 照片 ${index + 1}`"
                @click="openViewer(entry, index)"
              >
                <img
                  class="photo"
                  :src="url"
                  :alt="`${entry.title} 照片 ${index + 1}`"
                  loading="lazy"
                />
              </button>
            </div>
          </SimpleCard>
        </div>
        <div v-else class="empty">
          目前尚未發布活動回顧，請稍後再查看。
        </div>
      </div>
    </section>

    <!-- Teleported and click-outside-to-close, matching ContactDrawer rather
         than introducing a second overlay idiom on the same site. -->
    <Teleport to="body">
      <transition name="photo-viewer-fade">
        <div
          v-if="isViewerOpen"
          class="photo-viewer"
          role="dialog"
          aria-modal="true"
          :aria-label="viewerCaption"
          @click.self="closeViewer"
        >
          <button type="button" class="photo-viewer__close" aria-label="關閉" @click="closeViewer">×</button>

          <button
            v-if="viewer.photos.length > 1"
            type="button"
            class="photo-viewer__step photo-viewer__step--prev"
            aria-label="上一張"
            @click="step(-1)"
          >‹</button>

          <figure class="photo-viewer__figure" @click.self="closeViewer">
            <img :src="currentPhoto" :alt="viewerCaption" class="photo-viewer__image" />
            <figcaption class="photo-viewer__caption">{{ viewerCaption }}</figcaption>
          </figure>

          <button
            v-if="viewer.photos.length > 1"
            type="button"
            class="photo-viewer__step photo-viewer__step--next"
            aria-label="下一張"
            @click="step(1)"
          >›</button>
        </div>
      </transition>
    </Teleport>
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

.photo-button {
  padding: 0;
  border: 0;
  background: none;
  cursor: zoom-in;
  display: block;
  line-height: 0;
}

.photo-button:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
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

.photo-viewer {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-sm);
  padding: var(--spacing-lg);
  background: rgb(0 0 0 / 82%);
}

.photo-viewer__figure {
  margin: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--spacing-sm);
  max-width: min(1100px, 100%);
  max-height: 100%;
}

/* contain, not cover: the thumbnails crop, and the whole point of opening one
   is to see the photo the temple actually uploaded. */
.photo-viewer__image {
  max-width: 100%;
  max-height: 78vh;
  object-fit: contain;
  border-radius: var(--radius-md);
}

.photo-viewer__caption {
  color: rgb(255 255 255 / 82%);
  font-size: 0.9rem;
}

.photo-viewer__close,
.photo-viewer__step {
  background: rgb(255 255 255 / 12%);
  color: #fff;
  border: 0;
  border-radius: 999px;
  cursor: pointer;
  line-height: 1;
}

.photo-viewer__close {
  position: absolute;
  top: var(--spacing-md);
  right: var(--spacing-md);
  width: 2.5rem;
  height: 2.5rem;
  font-size: 1.6rem;
}

.photo-viewer__step {
  width: 3rem;
  height: 3rem;
  font-size: 2rem;
  flex: 0 0 auto;
}

.photo-viewer__close:hover,
.photo-viewer__step:hover {
  background: rgb(255 255 255 / 24%);
}

.photo-viewer-fade-enter-active,
.photo-viewer-fade-leave-active {
  transition: opacity 160ms ease;
}

.photo-viewer-fade-enter-from,
.photo-viewer-fade-leave-to {
  opacity: 0;
}

@media (max-width: 640px) {
  .photo-viewer {
    padding: var(--spacing-sm);
  }

  .photo-viewer__step {
    width: 2.5rem;
    height: 2.5rem;
    font-size: 1.6rem;
  }
}
</style>
