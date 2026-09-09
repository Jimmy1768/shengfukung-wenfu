<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';

import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import {
  useHeroImage,
  useTempleArchiveEntry,
  useTempleContent
} from '@/app/siteContent.js';

const route = useRoute();
const siteContent = useTempleContent();
const archiveFallbackImage = useHeroImage('archive');

const albumId = computed(() => route.params.id?.toString() || '');
const album = useTempleArchiveEntry(albumId);

// The whole archive arrives in one request at boot, so there is nothing to
// fetch here -- but a visitor who lands on this URL directly can arrive before
// it has. "Not found" and "not loaded yet" are different answers.
const loading = computed(
  () => !album.value && ['idle', 'loading'].includes(siteContent.status)
);
const loadFailed = computed(() => !album.value && siteContent.status === 'error');

const photos = computed(() => album.value?.photo_urls || []);
const title = computed(() => album.value?.title || '活動相簿');
const summary = computed(() => album.value?.body || '這場活動的照片記錄。');

// The album's first photo is its cover. No temple-level fallback: a hero here
// would otherwise be a generic picture presented as this album's own.
const heroImage = computed(() => photos.value[0] || archiveFallbackImage.value);

function formatEventDate(value) {
  if (!value) return '日期待定';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return value;
  return parsed.toLocaleDateString('zh-TW');
}

const viewer = ref({ open: false, index: 0 });
const currentPhoto = computed(() => photos.value[viewer.value.index] || null);
const viewerCaption = computed(() =>
  viewer.value.open ? `${title.value}（${viewer.value.index + 1}／${photos.value.length}）` : ''
);

function openViewer(index) {
  viewer.value = { open: true, index };
  lockScroll(true);
}

function closeViewer() {
  viewer.value = { open: false, index: 0 };
  lockScroll(false);
}

// Wraps, so the album can be browsed round rather than dead-ending at each end.
function step(offset) {
  const total = photos.value.length;
  if (!total) return;
  viewer.value.index = (viewer.value.index + offset + total) % total;
}

// The overlay covers the viewport, so a wheel scroll behind it is invisible
// while it happens and then dumps the visitor somewhere else the moment they
// close. The shift the vanishing scrollbar causes is hidden by the overlay.
function lockScroll(locked) {
  document.body.style.overflow = locked ? 'hidden' : '';
}

function onKeydown(event) {
  if (!viewer.value.open) return;
  if (event.key === 'Escape') closeViewer();
  if (event.key === 'ArrowRight') step(1);
  if (event.key === 'ArrowLeft') step(-1);
}

onMounted(() => window.addEventListener('keydown', onKeydown));
onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKeydown);
  lockScroll(false);
});

// Moving between albums without unmounting this component would otherwise keep
// the previous album's viewer open over the new one.
watch(albumId, closeViewer);
</script>

<template>
  <div>
    <PageHero
      :title="title"
      :subtitle="summary"
      :image-url="heroImage"
      ctaText="返回活動回顧"
      ctaTo="/archive"
    />

    <section class="section">
      <div class="wrap">
        <div v-if="loading" class="album-state">載入相簿中…</div>
        <div v-else-if="loadFailed" class="album-state error">
          取得相簿時發生錯誤，請稍後再試。
        </div>
        <div v-else-if="!album" class="album-state">
          找不到此相簿，請返回活動回顧列表。
        </div>
        <template v-else>
          <SectionTitle
            :title="title"
            :subtitle="`活動日期：${formatEventDate(album.event_date)}`"
          />

          <p v-if="album.body" class="album-body">{{ album.body }}</p>

          <div v-if="photos.length" class="album-grid">
            <button
              v-for="(url, index) in photos"
              :key="`${albumId}-${index}`"
              type="button"
              class="album-thumb"
              :aria-label="`檢視 ${title} 照片 ${index + 1}`"
              @click="openViewer(index)"
            >
              <img
                class="album-thumb__image"
                :src="url"
                :alt="`${title} 照片 ${index + 1}`"
                loading="lazy"
              />
            </button>
          </div>
          <div v-else class="album-state">此相簿尚未上傳照片。</div>
        </template>
      </div>
    </section>

    <!-- Teleported and click-outside-to-close, matching ContactDrawer rather
         than introducing a second overlay idiom on the same site. -->
    <Teleport to="body">
      <transition name="photo-viewer-fade">
        <div
          v-if="viewer.open"
          class="photo-viewer"
          role="dialog"
          aria-modal="true"
          :aria-label="viewerCaption"
          @click.self="closeViewer"
        >
          <button type="button" class="photo-viewer__close" aria-label="關閉" @click="closeViewer">×</button>

          <button
            v-if="photos.length > 1"
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
            v-if="photos.length > 1"
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
.album-state {
  padding: var(--spacing-md);
  text-align: center;
  opacity: 0.78;
  border-radius: var(--radius-lg);
  border: 1px dashed color-mix(in srgb, var(--border) 80%, transparent);
}

.album-state.error {
  border-style: solid;
  border-color: color-mix(in srgb, var(--border) 60%, transparent);
}

.album-body {
  margin: var(--spacing-sm) 0 0;
  line-height: 1.7;
  opacity: 0.86;
}

/* A contact sheet, not a strip: this page exists so the whole album can be
   scanned at once and any photo opened from it. */
.album-grid {
  margin-top: var(--spacing-md);
  display: grid;
  gap: var(--spacing-sm);
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
}

.album-thumb {
  padding: 0;
  border: 0;
  background: none;
  cursor: zoom-in;
  display: block;
  line-height: 0;
}

.album-thumb:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

.album-thumb__image {
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
  border-radius: var(--radius-md);
  border: 1px solid color-mix(in srgb, var(--border) 80%, transparent);
  transition: transform 140ms ease;
}

.album-thumb:hover .album-thumb__image {
  transform: scale(1.02);
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

/* contain, not cover: the grid crops to a common shape so the album can be
   scanned, and the whole point of opening one is to see it as it was taken. */
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
