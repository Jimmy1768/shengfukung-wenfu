<script setup>
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
</script>

<template>
  <div>
    <PageHero
      title="關於本廟"
      subtitle="把歷史、主祀神明、參拜禮儀，用清楚的段落呈現（Placeholder）。"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle title="本廟簡介" subtitle="短、清楚；詳細內容可放在下方卡片或段落。" />
        <div class="stack">
          <SimpleCard title="沿革（Placeholder）" body="例如：創建年代、地方故事、重要里程碑。" />
          <SimpleCard title="主祀 / 配祀（Placeholder）" body="例如：主神、陪祀神祇、簡短介紹與參拜重點。" />
          <SimpleCard title="參拜禮儀（Placeholder）" body="例如：入廟動線、禁忌提醒、拍照注意事項。" />
        </div>
      </div>
    </section>
  </div>
</template>
