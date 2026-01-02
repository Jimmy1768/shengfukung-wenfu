<script setup>
import PageHero from '@/components/site/PageHero.vue';
import SectionTitle from '@/components/site/SectionTitle.vue';
import SimpleCard from '@/components/site/SimpleCard.vue';
</script>

<template>
  <div>
    <PageHero
      title="參拜 / 服務"
      subtitle="把服務項目做成清楚的 FAQ 結構（避免首頁資訊爆炸）。"
    />

    <section class="section">
      <div class="wrap">
        <SectionTitle title="常見服務（Placeholder）" subtitle="每個服務可以獨立成頁，或先用卡片整理。" />

        <div class="grid">
          <SimpleCard title="點燈（Placeholder）" body="流程、時間、費用、注意事項（Placeholder）。" />
          <SimpleCard title="安太歲（Placeholder）" body="流程、資格、所需資料（Placeholder）。" />
          <SimpleCard title="祈福 / 法會（Placeholder）" body="參加方式、服裝提醒、交通建議（Placeholder）。" />
          <SimpleCard title="求籤說明（Placeholder）" body="如何求籤、解籤方式、注意事項（Placeholder）。" />
        </div>
      </div>
    </section>
  </div>
</template>
