<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';

import SiteHeader from '@/components/site/SiteHeader.vue';
import SiteFooter from '@/components/site/SiteFooter.vue';
import { useTempleContent } from '@/app/siteContent.js';

const SITE_THEME_ID = 'temple-1';

const applySiteTheme = () => {
  if (typeof document === 'undefined') return;
  document.documentElement.dataset.theme = SITE_THEME_ID;
};

applySiteTheme();

const route = useRoute();
const siteContent = useTempleContent();

const activeKey = computed(() => {
  // highlight by top-level segment
  const path = route.path || '/';
  if (path === '/') return 'home';
  const first = path.split('/').filter(Boolean)[0];
  return first || 'home';
});

const isLoading = computed(
  () => siteContent.status === 'loading' || siteContent.status === 'idle'
);
const hasError = computed(() => siteContent.status === 'error');
</script>

<template>
  <div class="site">
    <SiteHeader :activeKey="activeKey" />

    <main class="site-main">
      <div v-if="isLoading" class="loading-state">載入中…</div>
      <div v-else-if="hasError" class="loading-state error">
        資料載入失敗，請稍後再試。
      </div>
      <router-view v-else />
    </main>

    <SiteFooter />
  </div>
</template>

<style scoped>
.site {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.site-main {
  flex: 1;
  min-height: 50vh;
}

.loading-state {
  padding: var(--spacing-lg);
  text-align: center;
  opacity: 0.8;
}

.loading-state.error {
  color: var(--primary);
}
</style>
