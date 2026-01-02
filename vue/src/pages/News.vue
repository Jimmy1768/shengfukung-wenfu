<script setup>
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';

const posts = [
  { title: '春節開放時間（Placeholder）', date: '2025/12/20', body: '簡短公告內容…' },
  { title: '活動報名提醒（Placeholder）', date: '2025/12/10', body: '簡短公告內容…' },
];
</script>

<template>
  <div>
    <PageHero
      title="最新消息"
      subtitle="短公告即可：時間、重點、聯絡方式。"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle title="公告列表" subtitle="之後可以變成 Rails 的 posts/news resource。" />
        <div class="stack">
          <SimpleCard
            v-for="p in posts"
            :key="p.title"
            :title="p.title"
            :body="`日期：${p.date}｜${p.body}`"
          />
        </div>
      </div>
    </section>
  </div>
</template>
