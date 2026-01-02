<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';

import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';

const route = useRoute();

const slug = computed(() => route.params.slug);

const event = computed(() => ({
  title: `活動詳情（${slug.value}）`,
  when: '2026/01/05 09:00',
  where: '本廟主殿',
  fee: '隨喜 / 或固定金額（Placeholder）',
  capacity: '名額 100（Placeholder）',
  summary: '這裡是活動頁的 SEO 內容 / 介紹（Placeholder）。',
}));
</script>

<template>
  <div>
    <PageHero
      :title="event.title"
      :subtitle="event.summary"
      ctaText="我要報名（之後接 OAuth）"
      ctaTo="/events"
    />

    <section class="section">
      <div class="wrap">
        <div class="grid">
          <SimpleCard title="活動資訊">
            <div class="kv">
              <div class="k">時間</div><div class="v">{{ event.when }}</div>
              <div class="k">地點</div><div class="v">{{ event.where }}</div>
              <div class="k">費用</div><div class="v">{{ event.fee }}</div>
              <div class="k">名額</div><div class="v">{{ event.capacity }}</div>
            </div>
          </SimpleCard>

          <SimpleCard title="報名流程（Placeholder）" body="登入 → 填資料 → 確認 → 付款（LINE Pay 之後接）。" />
        </div>

        <div class="sp" />

        <SectionTitle title="活動內容" subtitle="這裡放長文：流程、注意事項、FAQ。" />
        <div class="article">
          <p>（Placeholder）活動說明段落。</p>
          <p>（Placeholder）注意事項段落。</p>
          <p>（Placeholder）FAQ 段落。</p>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.kv {
  display: grid;
  grid-template-columns: 90px 1fr;
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
</style>
