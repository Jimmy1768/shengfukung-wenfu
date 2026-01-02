<script setup>
import { computed } from 'vue';

const props = defineProps({
  open: { type: Boolean, default: false },
  copy: { type: Object, default: () => ({}) },
  contactForm: { type: Object, required: true },
  formState: { type: String, default: 'idle' },
  formMessage: { type: String, default: '' },
  formError: { type: String, default: '' },
  submitButtonLabel: { type: String, default: 'Send' }
});

const emit = defineEmits(['close', 'submit']);

const isSending = computed(() => props.formState === 'sending');
</script>

<template>
  <Teleport to="body">
    <transition name="contact-drawer-fade">
      <div
        v-if="open"
        class="contact-drawer-overlay"
        role="dialog"
        aria-modal="true"
        @click.self="emit('close')"
      >
        <div class="contact-drawer-panel">
          <button
            type="button"
            class="contact-drawer-close"
            aria-label="Close contact form"
            @click="emit('close')"
          >
            ×
          </button>

          <header class="contact-drawer-header">
            <p class="contact-drawer-eyebrow">{{ copy?.heading }}</p>
            <p class="contact-drawer-description">{{ copy?.description }}</p>
          </header>

          <div class="contact-drawer-body">
            <form class="contact-drawer-form" @submit="emit('submit', $event)">
              <label class="contact-field">
                <span>{{ copy?.nameLabel }}</span>
                <input
                  v-model="contactForm.name"
                  type="text"
                  :placeholder="copy?.namePlaceholder"
                  required
                />
              </label>
              <label class="contact-field">
                <span>{{ copy?.emailLabel }}</span>
                <input
                  v-model="contactForm.email"
                  type="email"
                  :placeholder="copy?.emailPlaceholder"
                  autocomplete="email"
                  required
                />
              </label>
              <label class="contact-field">
                <span>{{ copy?.messageLabel }}</span>
                <textarea
                  v-model="contactForm.message"
                  rows="4"
                  :placeholder="copy?.messagePlaceholder"
                  required
                ></textarea>
              </label>

              <div class="contact-form-actions">
                <button type="submit" :disabled="isSending">
                  <span>{{ submitButtonLabel }}</span>
                </button>
              </div>

              <p v-if="formMessage" class="contact-form-success">{{ formMessage }}</p>
              <p v-else-if="formError" class="contact-form-error">{{ formError }}</p>
            </form>
          </div>
        </div>
      </div>
    </transition>
  </Teleport>
</template>

<style scoped>
.contact-drawer-overlay {
  position: fixed;
  inset: 0;
  background: rgba(2, 6, 23, 0.72);
  backdrop-filter: blur(8px);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  padding: 1.5rem;
}

.contact-drawer-panel {
  position: relative;
  width: min(960px, 100%);
  border-radius: var(--radiusLg);
  border: 1px solid rgba(148, 163, 184, 0.25);
  background: rgba(15, 23, 42, 0.92);
  color: #f8fafc;
  box-shadow:
    0 30px 60px rgba(2, 6, 23, 0.65),
    0 0 0 1px rgba(255, 255, 255, 0.05);
  padding: clamp(1.5rem, 4vw, 2.5rem);
}

.contact-drawer-close {
  position: absolute;
  top: 1rem;
  right: 1rem;
  border: none;
  background: transparent;
  color: inherit;
  font-size: 1.5rem;
  cursor: pointer;
  transition: opacity 200ms ease;
}

.contact-drawer-close:hover {
  opacity: 0.75;
}

.contact-drawer-header {
  display: grid;
  gap: 0.4rem;
  margin-bottom: 1.5rem;
}

.contact-drawer-eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  font-size: 0.78rem;
  opacity: 0.8;
}

.contact-drawer-description {
  margin: 0;
  font-size: 1rem;
  color: rgba(248, 250, 252, 0.85);
}

.contact-drawer-body {
  display: flex;
  flex-direction: column;
  gap: clamp(1.25rem, 3vw, 2.25rem);
}

.contact-drawer-form {
  display: grid;
  gap: 0.85rem;
}

.contact-field {
  display: grid;
  gap: 0.35rem;
  font-size: 0.9rem;
}

.contact-field span {
  text-transform: uppercase;
  letter-spacing: 0.16em;
  font-size: 0.72rem;
  color: rgba(248, 250, 252, 0.75);
}

.contact-field input,
.contact-field textarea,
.contact-field select {
  border-radius: var(--radiusMd);
  border: 1px solid rgba(148, 163, 184, 0.35);
  background: rgba(2, 6, 23, 0.65);
  color: inherit;
  padding: 0.75rem 0.9rem;
  font: inherit;
  resize: none;
}

.contact-field textarea {
  min-height: 140px;
}

.contact-form-actions {
  display: flex;
  justify-content: flex-start;
  margin-top: 0.25rem;
}

.contact-form-actions button {
  border-radius: 999px;
  border: 1px solid rgba(248, 250, 252, 0.55);
  padding: 0.65rem 1.6rem;
  background: rgba(248, 250, 252, 0.1);
  color: inherit;
  font-weight: 600;
  cursor: pointer;
  transition: transform 200ms ease, opacity 200ms ease;
}

.contact-form-actions button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.contact-form-success,
.contact-form-error {
  margin: 0;
  font-size: 0.9rem;
}

.contact-form-success {
  color: #a7f3d0;
}

.contact-form-error {
  color: #fecdd3;
}

@media (max-width: 640px) {
  .contact-drawer-overlay {
    padding: 0.5rem;
  }

  .contact-drawer-panel {
    padding: 1.5rem 1rem;
  }
}

.contact-drawer-fade-enter-active,
.contact-drawer-fade-leave-active {
  transition: opacity 200ms ease;
}

.contact-drawer-fade-enter-from,
.contact-drawer-fade-leave-to {
  opacity: 0;
}
</style>
