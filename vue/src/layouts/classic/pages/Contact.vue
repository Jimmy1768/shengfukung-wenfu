<script setup>
import { computed, onMounted, ref } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import { useHeroImage, useTempleContent } from '@/app/siteContent.js';

const siteContent = useTempleContent();
// No placeholder fallbacks. These used to resolve to the admin-facing strings
// in the shared placeholder JSON, which meant a visitor was told to "至後台
// 「Temple Profile」更新" while the fetch was in flight, and permanently for any
// section a temple had left empty. Empty objects render nothing, and every line
// below is guarded so a label never appears without its value.
const contact = computed(() => siteContent.data?.contact || {});
const serviceTimes = computed(() => siteContent.data?.service_times || {});
const visitInfo = computed(() => siteContent.data?.visit_info || {});
// The Director's copy, restored. 032 dropped it because the string it was
// attached to carried a "（… Placeholder）" suffix, and removing the suffix
// would have meant deciding that the half in front of it was real copy rather
// than scaffolding. It was real copy: it describes the page to a visitor and
// says nothing to an admin. The suffix and the ${project.name} interpolation
// are what is gone, not the sentence.
const DEFAULT_HERO_SUBTITLE = '地址、地圖、開放時間、停車與大眾運輸';

const heroSubtitle = computed(
  () => siteContent.data?.service_times?.notes || DEFAULT_HERO_SUBTITLE
);

const hasContactDetails = computed(() =>
  Boolean(contact.value.phone || contact.value.addressZh || contact.value.plusCode || contact.value.addressEn)
);
const hasSchedule = computed(() =>
  Boolean(serviceTimes.value.weekday || serviceTimes.value.weekend || serviceTimes.value.notes)
);
const heroImage = useHeroImage('contact');

const isMobile = ref(false);

onMounted(() => {
  isMobile.value = /Mobi|Android|iPhone|iPad|iPod|Android/i.test(
    window.navigator.userAgent
  );
});

const mapLink = computed(() => contact.value?.mapUrl);

const directionsUrl = computed(() => {
  const lat = contact.value?.latitude;
  const lng = contact.value?.longitude;
  const address = contact.value?.addressZh || contact.value?.addressEn;
  if (lat && lng) {
    return `https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}`;
  }
  if (address) {
    return `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(
      address
    )}`;
  }
  return null;
});

const showDirectionsLink = computed(
  () => isMobile.value && Boolean(directionsUrl.value)
);
</script>

<template>
  <div>
    <PageHero
      title="聯絡 / 交通"
      :subtitle="heroSubtitle"
      :image-url="heroImage"
    />

    <section class="section">
      <div class="wrap">
        <div class="grid contact-grid">
          <SimpleCard v-if="hasContactDetails" title="聯絡資訊">
            <div class="info">
              <div v-if="contact.phone">電話：{{ contact.phone }}</div>
              <div v-if="contact.addressZh">地址：{{ contact.addressZh }}</div>
              <div v-if="contact.plusCode">Plus Code：{{ contact.plusCode }}</div>
              <template v-if="contact.addressEn">
                <div class="info-divider" aria-hidden="true" />
                <div class="info-block">
                  <p class="info-label">英文地址</p>
                  <p>{{ contact.addressEn }}</p>
                </div>
              </template>
              <div class="map-links" v-if="mapLink">
                <a class="map-link" :href="mapLink" target="_blank" rel="noreferrer">
                  在 Google 地圖開啟
                </a>
                <a
                  v-if="showDirectionsLink"
                  class="map-link map-link--secondary"
                  :href="directionsUrl"
                  target="_blank"
                  rel="noreferrer"
                >
                  啟動導航（Google Maps）
                </a>
              </div>
            </div>
          </SimpleCard>
          <SimpleCard v-if="hasSchedule" title="開放時間">
            <div class="info schedule-info">
              <div v-if="serviceTimes.weekday" class="schedule-row">
                <div class="schedule-label">平日</div>
                <div class="schedule-value">{{ serviceTimes.weekday }}</div>
              </div>
              <div v-if="serviceTimes.weekend" class="schedule-row">
                <div class="schedule-label">假日 / 特殊日</div>
                <div class="schedule-value">{{ serviceTimes.weekend }}</div>
              </div>
              <div v-if="serviceTimes.notes" class="schedule-row">
                <div class="schedule-label">備註</div>
                <div class="schedule-value">{{ serviceTimes.notes }}</div>
              </div>
            </div>
          </SimpleCard>
        </div>

        <div class="sp" />

        <template v-if="visitInfo.transportation || visitInfo.parking">
          <SectionTitle title="交通 / 停車" subtitle="在後台可隨時更新資訊，方便信眾掌握動線。" />
          <div class="grid">
            <SimpleCard v-if="visitInfo.transportation" title="交通方式">
              <div class="info">
                <p>{{ visitInfo.transportation }}</p>
              </div>
            </SimpleCard>

            <SimpleCard v-if="visitInfo.parking" title="停車 / 提醒">
              <div class="info">
                <p>{{ visitInfo.parking }}</p>
              </div>
            </SimpleCard>
          </div>
        </template>
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

.map-link {
  color: var(--primary);
  font-weight: 700;
}

.map-link--secondary {
  color: var(--text);
  font-weight: 600;
}

.contact-grid {
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: var(--spacing-lg);
}

.info-divider {
  width: 100%;
  height: 1px;
  background: var(--border);
  margin: var(--spacing-sm) 0;
}

.info-block {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-xs);
}

.info-label {
  font-size: 12px;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--text-muted);
}

.map-links {
  display: flex;
  flex-wrap: wrap;
  gap: var(--spacing-sm);
  align-items: center;
}

.schedule-info {
  gap: var(--spacing-md);
}

.schedule-row {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-xs);
}

.schedule-label {
  font-weight: 700;
  font-size: 13px;
  letter-spacing: 0.02em;
  color: var(--text-muted);
}

.schedule-value {
  font-size: 15px;
}
</style>
