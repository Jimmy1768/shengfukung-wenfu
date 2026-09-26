<script setup>
import { computed, ref, watch } from 'vue';
import { useRoute } from 'vue-router';

import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import {
  loadTempleEvent,
  useHeroImage,
  useTempleContent,
  useTempleEvent
} from '@/app/siteContent.js';
import {
  formatCurrency,
  formatDateRange,
  statusLabel
} from '@/utils/events.js';
import { buildRegistrationLink } from '@/utils/accountLinks.js';

const route = useRoute();
const templeEventFallbackImage = useHeroImage('event');
const siteContent = useTempleContent();

const slug = computed(() => route.params.slug?.toString() || '');
const eventData = useTempleEvent(slug);
const loading = ref(false);
const loadError = ref(null);

const defaultLocation = computed(
  () => siteContent.data?.contact?.addressZh || '本廟'
);

// This event's own picture wins. The temple-level 'event' image is only the
// fallback for events that have none -- which is what the admin calls it
// (活動預設圖片), and why it is not one of the seven page heroes.
const heroImage = computed(
  () => eventData.value?.hero_image_url || templeEventFallbackImage.value
);

const title = computed(
  () => eventData.value?.title || `活動資訊（${slug.value}）`
);
const summary = computed(
  () =>
    eventData.value?.description ||
    '這裡會顯示活動的內容、名額與聯絡方式。'
);

const schedule = computed(() =>
  eventData.value
    ? formatDateRange(eventData.value.starts_on, eventData.value.ends_on)
    : '日期待定'
);

const location = computed(
  () => eventData.value?.metadata?.location || defaultLocation.value
);

const priceLabel = computed(() => {
  if (!eventData.value) return '敬請洽詢';
  return formatCurrency(eventData.value.price_cents, eventData.value.currency);
});

const capacityLabel = computed(() => {
  if (!eventData.value) return '尚未公布';
  if (eventData.value.capacity_remaining != null) {
    return `剩餘 ${eventData.value.capacity_remaining} 名 / 總名額 ${eventData.value.available_slots || '未公布'}`;
  }
  if (eventData.value.available_slots) {
    return `名額 ${eventData.value.available_slots}（尚未開放報名）`;
  }
  return '名額尚未設定';
});

const statusText = computed(() =>
  statusLabel(eventData.value?.timeline_status)
);

const periodLabel = computed(
  () => eventData.value?.period || '檔期待公告'
);

// The registration button lives here, on the event's own page -- a visitor
// reads the event first and registers second. timeline_status is the only
// reliable signal today: gatherings currently carry no capacity numbers, so
// capacity_remaining is only trusted when it is explicitly zero.
const registrationHref = computed(() =>
  eventData.value
    ? buildRegistrationLink(eventData.value.kind || 'event', eventData.value.slug)
    : ''
);

const registrationState = computed(() => {
  const event = eventData.value;
  if (!event) return { open: false, message: '' };
  if (event.timeline_status === 'past') {
    return { open: false, message: '此活動已結束，感謝參與。' };
  }
  if (event.capacity_remaining === 0) {
    return { open: false, message: '名額已滿，如需候補請洽廟方。' };
  }
  return { open: true, message: '' };
});

const detailsList = computed(() => [
  { label: '檔期', value: periodLabel.value },
  { label: '時間', value: schedule.value },
  { label: '地點', value: location.value },
  { label: '狀態', value: statusText.value },
  { label: '費用', value: priceLabel.value },
  { label: '名額', value: capacityLabel.value }
]);

const metadataNotes = computed(
  () => eventData.value?.metadata?.notes || ''
);

async function ensureEventLoaded() {
  const currentSlug = slug.value;
  if (!currentSlug || eventData.value || loading.value) return;
  loading.value = true;
  loadError.value = null;
  try {
    await loadTempleEvent(currentSlug);
  } catch (error) {
    loadError.value = error;
  } finally {
    loading.value = false;
  }
}

watch(
  () => slug.value,
  () => {
    loadError.value = null;
    ensureEventLoaded();
  },
  { immediate: true }
);
</script>

<template>
  <div>
    <PageHero
      :title="title"
      :subtitle="summary"
      :image-url="heroImage"
      ctaText="返回活動列表"
      ctaTo="/events"
    />

    <section class="section">
      <div class="wrap">
        <div v-if="loading" class="event-state">載入活動資訊中…</div>
        <div v-else-if="loadError" class="event-state error">
          取得活動資訊時發生錯誤，請稍後再試。
        </div>
        <div v-else-if="!eventData" class="event-state">
          找不到此活動，請返回列表。
        </div>
        <template v-else>
          <div class="grid">
            <SimpleCard title="活動資訊">
              <div class="kv">
                <template v-for="item in detailsList" :key="item.label">
                  <div class="k">{{ item.label }}</div>
                  <div class="v">{{ item.value }}</div>
                </template>
              </div>
            </SimpleCard>
            <SimpleCard title="報名 / 參與指引">
              <div class="info">
                <a
                  v-if="registrationState.open"
                  class="register"
                  :href="registrationHref"
                >立即報名</a>
                <p v-else class="register-closed">{{ registrationState.message }}</p>
                <p v-if="metadataNotes">{{ metadataNotes }}</p>
                <router-link class="link" to="/contact">聯絡廟方 / 交通資訊 →</router-link>
              </div>
            </SimpleCard>
          </div>

          <div class="sp" />

          <SectionTitle title="活動內容" subtitle="文字說明與注意事項將同步後台設定。" />
          <div class="article">
            <p>{{ summary }}</p>
            <p v-if="metadataNotes">{{ metadataNotes }}</p>
          </div>
        </template>
      </div>
    </section>
  </div>
</template>

<style scoped>
.register {
  display: inline-block;
  padding: 10px 20px;
  border-radius: 999px;
  background: var(--color-primary, #8b2e2e);
  color: #fff;
  font-weight: 600;
  text-decoration: none;
}

.register:hover {
  opacity: 0.9;
}

.register-closed {
  margin: 0;
  font-weight: 600;
  opacity: 0.75;
}

.kv {
  display: grid;
  grid-template-columns: 80px 1fr;
  gap: 10px 12px;
  margin-top: var(--spacing-sm);
}

.k {
  opacity: 0.7;
  font-weight: 700;
}

.v {
  line-height: 1.7;
}

.info {
  display: grid;
  gap: var(--spacing-xs);
  font-size: 14px;
  line-height: 1.7;
}

.event-state {
  padding: var(--spacing-lg);
  text-align: center;
  opacity: 0.8;
  border-radius: var(--radius-lg);
  border: 1px solid color-mix(in srgb, var(--border) 70%, transparent);
}

.event-state.error {
  color: var(--primary);
  border-color: color-mix(in srgb, var(--primary) 40%, transparent);
}
</style>
