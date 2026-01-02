<template>
  <label class="theme-selector">
    <span class="label-text">{{ label }}</span>
    <select :value="modelValue" @change="handleChange">
      <option v-for="option in normalizedOptions" :key="option.value" :value="option.value">
        {{ option.label }}
      </option>
    </select>
    <p class="helper-text">{{ helper }}</p>
  </label>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
  options: {
    type: Array,
    required: true
  },
  modelValue: {
    type: String,
    required: true
  },
  label: {
    type: String,
    default: 'Theme'
  },
  helper: {
    type: String,
    default: ''
  }
});

const emit = defineEmits(['update:modelValue']);

const handleChange = (event) => {
  emit('update:modelValue', event.target.value);
};

const normalizedOptions = computed(() =>
  props.options.map((option) => {
    if (typeof option === 'string') {
      return { value: option, label: option };
    }
    const value = option.value ?? option.label ?? '';
    return {
      value,
      label: option.label ?? value
    };
  })
);
</script>

<style scoped>
.theme-selector {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  font-size: 0.85rem;
  color: var(--text);
  align-self: flex-start;
  width: auto;
  max-width: 100%;
}

.label-text {
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  font-size: 0.75rem;
  color: var(--text-muted);
}

select {
  border-radius: 999px;
  border: 1px solid var(--border);
  background: var(--surface-raised);
  color: var(--text);
  padding: 0.45rem 1rem;
  font-size: 0.95rem;
  min-width: 11rem;
  display: inline-flex;
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;
  background-image: none;
  box-shadow: var(--shadow-soft);
}

select:focus {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

.helper-text {
  font-size: 0.75rem;
  color: var(--text-muted);
}
</style>
