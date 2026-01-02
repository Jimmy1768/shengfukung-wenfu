<script setup>
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';

const past = [
  { title: '中元普渡（Placeholder）', date: '2025/08/20', slug: 'ghost-festival-2025' },
  { title: '安太歲說明會（Placeholder）', date: '2025/02/03', slug: 'taisui-2025' },
];
</script>

<template>
  <div>
    <PageHero
      title="活動回顧"
      subtitle="過往活動做成『可被搜尋 / 可被分享』的文章型頁面（SEO + slug）。"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle title="過往活動" subtitle="之後可加圖片相簿（S3 + ActiveStorage）。" />
        <div class="stack">
          <SimpleCard v-for="p in past" :key="p.slug" :title="p.title" :body="`日期：${p.date}`">
            <router-link class="link" :to="`/events/${p.slug}`">查看頁面 →</router-link>
          </SimpleCard>
        </div>
      </div>
    </section>
  </div>
</template>
