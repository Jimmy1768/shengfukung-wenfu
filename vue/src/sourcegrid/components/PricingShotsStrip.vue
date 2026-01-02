<script setup>
import { computed } from 'vue';

const props = defineProps({
  shots: { type: Array, default: () => [] },
  copy: { type: Object, default: () => ({}) }
});

const visibleShots = computed(() => props.shots.slice(0, 3));
</script>

<template>
  <section v-if="visibleShots.length" class="ps-gallery">
    <article
      v-for="(shot, index) in visibleShots"
      :key="shot.id || index"
      class="ps-shot"
      :style="shot.image ? { backgroundImage: `url(${shot.image})` } : undefined"
    >
      <div class="ps-overlay" />
      <div class="ps-label">
        <p class="ps-eyebrow">{{ copy?.shotEyebrow || 'Service angle' }}</p>
        <p>
          {{ shot.label || copy?.shotFallback || 'Signature delivery' }}
        </p>
      </div>
    </article>
  </section>
</template>

<style scoped>
.ps-gallery {
  margin-top: clamp(1.5rem, 3vw, 2.25rem);
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 0.6rem;
}

.ps-shot {
  position: relative;
  min-height: 150px;
  border-radius: 14px;
  background-size: cover;
  background-position: center;
  overflow: hidden;
  box-shadow:
    0 12px 30px rgba(0, 0, 0, 0.85),
    0 0 0 1px rgba(15, 23, 42, 0.9);
}

.ps-overlay {
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at 0% 0%, rgba(15, 23, 42, 0.96), transparent 55%);
}

.ps-label {
  position: absolute;
  left: 0.8rem;
  right: 0.8rem;
  bottom: 0.7rem;
  font-size: 0.78rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: rgba(248, 250, 252, 0.92);
  display: grid;
  gap: 0.25rem;
}

.ps-eyebrow {
  margin: 0;
  opacity: 0.8;
}

.ps-label p {
  margin: 0;
}

@media (max-width: 980px) {
  .ps-gallery {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
