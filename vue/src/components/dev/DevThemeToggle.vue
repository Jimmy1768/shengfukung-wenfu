<script setup>
import { ref } from 'vue';
import { availableThemes, getActiveThemeKey, setThemeKey } from '@/app/theme.js';

const themes = availableThemes().filter((theme) => theme.id.startsWith('temple-'));
const selected = ref(getActiveThemeKey());

function handleSelect(id) {
  selected.value = id;
  setThemeKey(id);
}
</script>

<template>
  <div class="dev-theme-toggle">
    <p>Theme preview</p>
    <div class="dev-theme-options">
      <button
        v-for="theme in themes"
        :key="theme.id"
        type="button"
        class="dev-theme-button"
        :class="{ active: theme.id === selected }"
        @click="handleSelect(theme.id)"
      >
        {{ theme.label }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.dev-theme-toggle {
  position: fixed;
  bottom: 20px;
  right: 20px;
  background: rgba(255, 255, 255, 0.9);
  border-radius: 16px;
  padding: 12px 16px;
  border: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 15px 35px rgba(0, 0, 0, 0.15);
  font-size: 13px;
  z-index: 90;
}

.dev-theme-toggle p {
  margin: 0 0 4px;
  text-transform: uppercase;
  letter-spacing: 0.2em;
  font-size: 11px;
  opacity: 0.7;
}

.dev-theme-options {
  display: flex;
  gap: 6px;
}

.dev-theme-button {
  border: 1px solid rgba(0, 0, 0, 0.2);
  background: #fff;
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 12px;
  cursor: pointer;
}

.dev-theme-button.active {
  background: #d39b39;
  color: #fff;
  border-color: transparent;
}
</style>
