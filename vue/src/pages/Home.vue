<script setup>
import { computed } from 'vue';
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
import EventCard from '@/components/site/EventCard.vue';
import project from '@/app/project.js';
import { useTempleContent, useTempleSections } from '@/app/siteContent.js';

const siteContent = useTempleContent();
const homeSections = useTempleSections('home');

const heroTitle = computed(
  () => siteContent.data?.tagline || project.tagline || project.name
);
const heroSubtitle = computed(
  () =>
    siteContent.data?.hero_copy ||
    `用清楚的方式呈現 ${project.name} 的活動、服務與公告；讓長輩也能快速找到時間、地點、方式。`
);

const eventSection = computed(() =>
  homeSections.value.find((section) => section.section_type === 'event_list')
);
const upcoming = computed(
  () =>
    eventSection.value?.payload?.events || [
      {
        slug: 'new-year-blessing',
        month: 'JAN',
        day: '05',
        title: '新年祈福法會（Placeholder）',
        when: '2026/01/05 09:00',
        where: '本廟主殿',
        summary: '簡短說明文字，之後改成來自 Rails API。',
        badge: '可報名'
      },
      {
        slug: 'lantern-offering',
        month: 'FEB',
        day: '12',
        title: '點燈／祈福服務日（Placeholder）',
        when: '2026/02/12 10:00',
        where: '服務處',
        summary: '用清楚的條列與流程頁面會更適合。',
        badge: '名額有限'
      }
    ]
);
</script>

<template>
  <div>
    <PageHero
      :title="heroTitle"
      :subtitle="heroSubtitle"
      ctaText="查看近期活動"
      ctaTo="/events"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle
          title="近期活動 / 法會"
          subtitle="活動列表公開可見；登入後可報名（之後接 OAuth + Rails）。"
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
          subtitle="簡短更新即可；不要把所有資訊都塞在首頁。"
        />

        <div class="grid2">
          <SimpleCard title="公告（Placeholder）" body="例如：春節期間開放時間、交通提醒、活動報名截止日。">
            <router-link class="link" to="/news">前往最新消息 →</router-link>
          </SimpleCard>

          <SimpleCard title="參拜 / 服務（Placeholder）" body="例如：點燈、安太歲、祈福、求籤說明，使用 FAQ 結構呈現。">
            <router-link class="link" to="/services">前往服務項目 →</router-link>
          </SimpleCard>
        </div>
      </div>
    </section>

    <section class="section">
      <div class="wrap">
        <SectionTitle
          title="來訪資訊"
          subtitle="把『怎麼來』『停車』『開放時間』放在最容易找到的地方。"
        />

        <div class="grid2">
          <SimpleCard title="地址 / 開放時間" body="地址、開放時間、電話（Placeholder）。" />
          <SimpleCard title="交通方式 / 停車" body="捷運 / 公車 / 停車場資訊（Placeholder）。" />
        </div>

        <div class="more">
          <router-link class="link" to="/contact">查看交通與聯絡 →</router-link>
        </div>
      </div>
    </section>
  </div>
</template>
