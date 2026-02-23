<script setup>
import { computed } from 'vue';

const props = defineProps({
  item: { type: Object, required: true }
});

const linkTag = computed(() => (props.item.ctaHref ? 'a' : 'router-link'));
const linkAttrs = computed(() =>
  props.item.ctaHref
    ? { href: props.item.ctaHref }
    : { to: `/events/${props.item.slug}` }
);
</script>

<template>
  <component :is="linkTag" class="card" v-bind="linkAttrs">
    <div class="row">
      <div class="date">
        <div class="m">{{ item.month }}</div>
        <div class="d">{{ item.day }}</div>
      </div>
      <div class="main">
        <div class="t">{{ item.title }}</div>
        <div class="meta">{{ item.when }} · {{ item.where }}</div>
        <div class="desc">{{ item.summary }}</div>
      </div>
    </div>
    <div class="badge" v-if="item.badge">{{ item.badge }}</div>
    <div v-if="item.imageUrl" class="thumb">
      <img :src="item.imageUrl" :alt="item.title || ''" loading="lazy" decoding="async" />
    </div>
  </component>
</template>

<style scoped>
.card {
  display: block;
  text-decoration: none;
  color: inherit;
  border: 1px solid color-mix(in srgb, var(--border) 80%, transparent);
  background: var(--surface-raised);
  border-radius: var(--radius-lg);
  padding: var(--spacing-md);
  transition: border-color 150ms ease, box-shadow 150ms ease;
}

.card:hover {
  border-color: var(--border);
  box-shadow: var(--shadow-soft);
}

.row {
  display: grid;
  grid-template-columns: 56px 1fr;
  gap: 12px;
  align-items: start;
}

.thumb {
  width: 100%;
  height: 144px;
  border-radius: 14px;
  overflow: hidden;
  border: 1px solid color-mix(in srgb, var(--border) 75%, transparent);
  background: color-mix(in srgb, var(--border) 10%, transparent);
  margin-top: 12px;
}

.thumb img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  object-position: center;
  display: block;
}

.date {
  border-radius: 14px;
  padding: var(--spacing-sm) var(--spacing-xs);
  text-align: center;
  background: color-mix(in srgb, var(--border) 20%, transparent);
}

.m { font-size: 12px; opacity: 0.7; font-weight: 700; }
.d { font-size: 20px; font-weight: 900; margin-top: 2px; }

.t { font-weight: 900; letter-spacing: 0.2px; }
.meta { margin-top: 6px; opacity: 0.7; font-size: 13px; }
.desc { margin-top: 8px; opacity: 0.82; line-height: 1.65; }

.badge {
  margin-top: var(--spacing-xs);
  display: inline-block;
  font-size: 12px;
  padding: 6px 10px;
  border-radius: 999px;
  background: color-mix(in srgb, var(--primary) 18%, transparent);
  color: var(--primary);
  font-weight: 700;
}

@media (max-width: 640px) {
  .thumb {
    height: 124px;
  }
}
</style>
