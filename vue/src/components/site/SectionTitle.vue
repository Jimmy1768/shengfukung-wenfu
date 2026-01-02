<script setup>
defineProps({
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
});
</script>

<template>
  <div class="wrap">
    <div class="title">{{ title }}</div>
    <div v-if="subtitle" class="sub">{{ subtitle }}</div>
  </div>
</template>

<style scoped>
.wrap { margin: 0 0 var(--spacing-sm); }
.title { font-weight: 800; font-size: 18px; }
.sub { opacity: 0.75; margin-top: var(--spacing-xs); line-height: 1.7; }
</style>
