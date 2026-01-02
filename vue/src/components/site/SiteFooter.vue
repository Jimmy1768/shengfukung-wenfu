<script setup>
import { computed } from 'vue';
import project from '@/app/project.js';
import { useTempleContent } from '@/app/siteContent.js';
import placeholders from '@shared/app_constants/temple_profile_placeholders.json';

const siteContent = useTempleContent();
const contactPlaceholder = placeholders.contact || {};
const contact = computed(() => siteContent.data?.contact || contactPlaceholder);
const brandName = computed(() => siteContent.data?.name || project.name);
const englishName = computed(() => siteContent.data?.englishName || project.englishName);
</script>

<template>
  <footer class="ftr">
    <div class="ftr-inner">
      <div class="cols">
        <div class="col">
          <div class="title">{{ brandName }}</div>
          <div class="muted">地址：{{ contact.addressZh }}</div>
          <div v-if="contact.plusCode" class="muted">Plus Code：{{ contact.plusCode }}</div>
        </div>

        <div class="col">
          <div class="title">快速連結</div>
          <router-link class="link" to="/events">近期活動</router-link>
          <router-link class="link" to="/services">參拜 / 服務</router-link>
          <router-link class="link" to="/contact">交通 / 聯絡</router-link>
        </div>

        <div class="col">
          <div class="title">聯絡方式</div>
          <div class="muted">電話：{{ contact.phone }}</div>
          <a v-if="contact.mapUrl" class="link map" :href="contact.mapUrl" target="_blank" rel="noreferrer">
            查看地圖
          </a>
        </div>
      </div>

      <div class="bottom">
        <div class="muted">© {{ new Date().getFullYear() }} {{ brandName }}</div>
        <div class="muted">{{ englishName }}</div>
      </div>
    </div>
  </footer>
</template>

<style scoped>
.ftr {
  border-top: 1px solid color-mix(in srgb, var(--border) 75%, transparent);
  background: color-mix(in srgb, var(--surface-raised) 98%, transparent);
}

.ftr-inner {
  max-width: var(--layout-max-width);
  margin: 0 auto;
  padding: var(--spacing-lg) var(--spacing-md);
}

.cols {
  display: grid;
  gap: var(--spacing-md);
}

.col .title {
  font-weight: 700;
  margin-bottom: var(--spacing-xs);
}

.muted {
  opacity: 0.75;
  font-size: 14px;
}

.link {
  display: inline-flex;
  align-items: center;
  gap: var(--spacing-xs);
  color: inherit;
  padding: 4px 0;
}

.bottom {
  margin-top: var(--spacing-md);
  padding-top: var(--spacing-sm);
  border-top: 1px solid color-mix(in srgb, var(--border) 75%, transparent);
  display: flex;
  flex-wrap: wrap;
  gap: var(--spacing-sm);
  justify-content: space-between;
  font-size: 14px;
}
</style>
