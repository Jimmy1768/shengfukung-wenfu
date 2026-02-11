<script setup>
import { onMounted } from 'vue';
import { RouterView } from 'vue-router';
import { loadTempleContent, useTempleContent } from '@/app/siteContent.js';
import { initTheme } from '@/app/theme.js';

const siteContent = useTempleContent();

onMounted(() => {
  initTheme();
  if (siteContent.status === 'idle') {
    loadTempleContent();
  }
});
</script>

<template>
  <div>
    <RouterView />
  </div>
</template>
