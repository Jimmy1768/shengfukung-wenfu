<script setup>
defineProps({
  title: { type: String, required: true },
  body: { type: String, default: '' },
});
</script>

<template>
  <div class="card">
    <div class="t">{{ title }}</div>
    <div v-if="body" class="b">{{ body }}</div>
    <slot />
  </div>
</template>

<style scoped>
.card {
  border: 1px solid color-mix(in srgb, var(--border) 80%, transparent);
  background: var(--surface-raised);
  border-radius: var(--radius-lg);
  padding: var(--spacing-md);
  box-shadow: var(--shadow-soft);
}
.t { font-weight: 800; }
.b { opacity: 0.78; line-height: 1.7; margin-top: var(--spacing-xs); }
</style>
