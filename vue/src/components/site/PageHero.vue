<script setup>
defineProps({
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  ctaText: { type: String, default: '' },
  ctaTo: { type: String, default: '' },
});
</script>

<template>
  <section class="hero">
    <div class="inner">
      <div class="copy">
        <h1 class="h1">{{ title }}</h1>
        <p v-if="subtitle" class="sub">{{ subtitle }}</p>

        <router-link v-if="ctaText && ctaTo" class="cta" :to="ctaTo">{{ ctaText }}</router-link>
      </div>

      <div class="art" aria-hidden="true">
        <!-- Placeholder for hero image later -->
        <div class="art-box"></div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.hero {
  background: linear-gradient(
    180deg,
    color-mix(in srgb, var(--surface-raised) 95%, transparent),
    color-mix(in srgb, var(--surface-muted) 85%, transparent)
  );
  border-bottom: 1px solid color-mix(in srgb, var(--border) 70%, transparent);
}

.inner {
  max-width: var(--layout-max-width);
  margin: 0 auto;
  padding: var(--spacing-lg) var(--spacing-md);
  display: grid;
  gap: 16px;
  grid-template-columns: 1fr;
  align-items: center;
}

.h1 {
  font-size: 30px;
  margin: 0;
  letter-spacing: 0.2px;
}

.sub {
  margin: 10px 0 0;
  opacity: 0.78;
  line-height: 1.7;
}

.cta {
  display: inline-block;
  margin-top: var(--spacing-sm);
  text-decoration: none;
  color: var(--primary-foreground);
  background: var(--primary);
  padding: calc(var(--spacing-xs) * 3) var(--spacing-md);
  border-radius: var(--radius-md);
  font-weight: 650;
}

.art-box {
  width: 100%;
  height: 180px;
  border-radius: var(--radius-lg);
  background:
    radial-gradient(circle at 20% 30%, color-mix(in srgb, var(--accent) 20%, transparent), transparent 45%),
    radial-gradient(circle at 70% 30%, color-mix(in srgb, var(--primary) 18%, transparent), transparent 45%),
    linear-gradient(135deg, color-mix(in srgb, var(--border) 24%, transparent), transparent);
  border: 1px solid color-mix(in srgb, var(--border) 70%, transparent);
}

@media (min-width: 900px) {
  .inner { grid-template-columns: 1.1fr 0.9fr; }
  .art-box { height: 240px; }
}
</style>
