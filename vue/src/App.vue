<script setup>
import { onMounted } from 'vue';
import { RouterView } from 'vue-router';
import { loadTempleContent, useTempleContent } from '@/app/siteContent.js';

const siteContent = useTempleContent();

onMounted(() => {
  if (siteContent.status === 'idle') {
    loadTempleContent();
  }
});
</script>

<template>
  <RouterView />
</template>
