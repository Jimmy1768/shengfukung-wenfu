<script setup>
import { onMounted } from 'vue';
import { RouterView } from 'vue-router';
import { loadTempleContent, useTempleContent } from '@/app/siteContent.js';
import { initTheme } from '@/app/theme.js';
import DevThemeToggle from '@/components/dev/DevThemeToggle.vue';

const siteContent = useTempleContent();
const isDev = import.meta.env.DEV;

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
    <DevThemeToggle v-if="isDev" />
  </div>
</template>
