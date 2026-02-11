<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import EventCard from '@/components/site/EventCard.vue';
import {
  useHeroImage,
  useTempleContent,
  useTempleOfferings,
  useTempleGatherings
} from '@/app/siteContent.js';
import { formatEventCard, statusLabel } from '@/utils/events.js';

const heroImage = useHeroImage('events');
const siteContent = useTempleContent();
const offeringsSource = useTempleOfferings();
const gatheringsSource = useTempleGatherings();

const defaultLocation = computed(
  () => siteContent.data?.contact?.addressZh || '本廟'
);

const sortByStart = (list = []) =>
  [...list].sort((a, b) => {
    const aTime = a.starts_on ? new Date(a.starts_on).getTime() : Infinity;
    const bTime = b.starts_on ? new Date(b.starts_on).getTime() : Infinity;
    return aTime - bTime;
  });

const offerings = computed(() => {
  if (!offeringsSource.value?.length) return [];
  return sortByStart(offeringsSource.value).map((event) =>
    formatEventCard(event, {
      defaultLocation: defaultLocation.value,
      registrationAction: 'event'
    })
  );
});

const gatherings = computed(() => {
  if (!gatheringsSource.value?.length) return [];
  return sortByStart(gatheringsSource.value).map((event) =>
    formatEventCard(event, {
      defaultLocation: defaultLocation.value,
      registrationAction: 'gathering'
    })
  );
});

const hasOfferings = computed(() => offerings.value.length > 0);
const hasGatherings = computed(() => gatherings.value.length > 0);
const pageEmpty = computed(() => !hasOfferings.value && !hasGatherings.value);

const offeringsHint = computed(() => {
  if (!hasOfferings.value) {
    return statusLabel('upcoming');
  }
  return `共有 ${offerings.value.length} 檔法會供品進行中或即將開始。`;
});

const gatheringsHint = computed(() => {
  if (!hasGatherings.value) {
    return '社群活動未開放報名，可直接洽詢服務台。';
  }
  return `共有 ${gatherings.value.length} 場社群活動開放報名或即將舉辦。`;
});
</script>

<template>
  <div>
    <PageHero
      title="活動資訊"
      subtitle="線上瀏覽法會與社群聚會的時間、名額與地點，登入後即可填寫報名表。"
      :image-url="heroImage"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle
          title="法會供品"
          subtitle="依照開放時段整理的供奉項目，方便提前預約或了解流程。"
        />
        <div v-if="hasOfferings" class="grid">
          <EventCard v-for="event in offerings" :key="event.slug" :item="event" />
        </div>
        <div v-else class="empty">
          目前沒有開放的法會供品，歡迎追蹤最新公告或洽詢廟方。
        </div>

        <div class="hint">
          法會供品進度：{{ offeringsHint }}
        </div>
      </div>
    </section>

    <section class="section alt">
      <div class="wrap">
        <SectionTitle
          title="社群活動"
          subtitle="串連社區的聚會、講座或祈福活動，和法會供品一樣可在此報名。"
        />
        <div v-if="hasGatherings" class="grid">
          <EventCard v-for="event in gatherings" :key="event.slug" :item="event" />
        </div>
        <div v-else class="empty">
          目前沒有公布的社群活動，歡迎關注官方訊息或直接洽詢。
        </div>

        <div class="hint">
          社群活動進度：{{ gatheringsHint }}
        </div>
      </div>
    </section>

    <section v-if="pageEmpty" class="section">
      <div class="wrap">
        <div class="empty">
          目前尚未公布活動資訊，可直接電話洽詢或稍後回來查看。
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
