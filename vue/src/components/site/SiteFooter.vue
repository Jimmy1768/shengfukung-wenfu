<script setup>
import { computed, reactive, ref } from 'vue';
import { useRoute } from 'vue-router';
import project from '@/app/project.js';
import { useTempleContent } from '@/app/siteContent.js';
import { submitTempleContactRequest } from '@/app/templeApi.js';
import ContactDrawer from '@/components/ContactDrawer.vue';
import placeholders from '@shared/app_constants/temple_profile_placeholders.json';

const siteContent = useTempleContent();
const route = useRoute();
const contactPlaceholder = placeholders.contact || {};
const contact = computed(() => siteContent.data?.contact || contactPlaceholder);
const brandName = computed(() => siteContent.data?.name || project.name);
const englishName = computed(() => siteContent.data?.englishName || project.englishName);
const isContactOpen = ref(false);
const formState = ref('idle');
const formMessage = ref('');
const formError = ref('');
const footerSuccessMessage = ref('');
const contactForm = reactive({
  name: '',
  email: '',
  subject: '',
  message: '',
  website: ''
});

const contactModalCopy = computed(() => {
  const isZh = resolvedLocale.value === 'zh-TW';
  return {
    heading: isZh ? 'Email 聯絡' : 'Email Us',
    description: isZh
      ? `傳送訊息給 ${brandName.value}，寺方會在可回覆時以 Email 聯繫您。`
      : `Send a question to ${brandName.value}. Temple staff will reply by email when available.`,
    nameLabel: isZh ? '姓名' : 'Name',
    namePlaceholder: isZh ? '您的姓名' : 'Your name',
    emailLabel: 'Email',
    emailPlaceholder: isZh ? '您的 Email' : 'you@example.com',
    subjectLabel: isZh ? '主旨' : 'Subject',
    subjectPlaceholder: isZh ? '想詢問什麼呢？' : 'How can we help?',
    messageLabel: isZh ? '訊息內容' : 'Message',
    messagePlaceholder: isZh ? '請輸入您的問題或需求。' : 'Please share your question or request.',
    submitLabel: formState.value === 'sending'
      ? (isZh ? '送出中…' : 'Sending…')
      : (isZh ? '送出訊息' : 'Send message')
  };
});

const footerCopy = computed(() => {
  const isZh = resolvedLocale.value === 'zh-TW';
  return {
    quickLinksTitle: isZh ? '快速連結' : 'Quick links',
    contactTitle: isZh ? '聯絡方式' : 'Contact',
    phoneLabel: isZh ? '電話' : 'Phone',
    emailUsLabel: isZh ? 'Email 聯絡' : 'Email Us',
    mapLabel: isZh ? '查看地圖' : 'View map',
    sentConfirmation: isZh ? '已送出訊息，寺方將以 Email 與您聯繫。' : 'Message sent. Temple staff will reply by email.',
    links: [
      { key: 'events', to: '/events', label: isZh ? '活動資訊' : 'Events' },
      { key: 'services', to: '/services', label: isZh ? '祈福服務' : 'Services' },
      { key: 'contact', to: '/contact', label: isZh ? '交通 / 聯絡' : 'Contact' }
    ]
  };
});

const resolvedLocale = computed(() => 'zh-TW');

const visibleQuickLinks = computed(() => {
  const currentPath = route.path || '/';
  return footerCopy.value.links.filter((item) => item.to !== currentPath);
});

function openContactModal() {
  footerSuccessMessage.value = '';
  formError.value = '';
  formMessage.value = '';
  formState.value = 'idle';
  isContactOpen.value = true;
}

function closeContactModal() {
  isContactOpen.value = false;
}

async function submitContact(event) {
  event?.preventDefault();
  formError.value = '';
  formMessage.value = '';
  formState.value = 'sending';

  try {
    const payload = await submitTempleContactRequest({
      name: contactForm.name,
      email: contactForm.email,
      subject: contactForm.subject,
      message: contactForm.message,
      website: contactForm.website
    });

    formState.value = 'success';
    formMessage.value = payload?.message || 'Your message has been sent.';
    footerSuccessMessage.value = footerCopy.value.sentConfirmation;
    contactForm.subject = '';
    contactForm.message = '';
    contactForm.website = '';
    closeContactModal();
  } catch (error) {
    formState.value = 'error';
    formError.value = error?.message || 'We could not send your message right now.';
  }
}
</script>

<template>
  <footer class="ftr">
    <div class="ftr-inner">
      <div class="cols">
        <div class="col">
          <div class="title">{{ brandName }}</div>
          <div class="muted">地址：{{ contact.addressZh }}</div>
          <div v-if="contact.plusCode" class="muted">Plus Code：{{ contact.plusCode }}</div>
          <div class="link-stack info-links">
            <router-link class="link contact-link" to="/contact">
              查看交通與聯絡 →
            </router-link>
            <a v-if="contact.mapUrl" class="link map" :href="contact.mapUrl" target="_blank" rel="noreferrer">
              {{ footerCopy.mapLabel }}
            </a>
          </div>
        </div>

        <div class="col">
          <div class="title">{{ footerCopy.quickLinksTitle }}</div>
          <div class="link-stack">
            <router-link
              v-for="item in visibleQuickLinks"
              :key="item.key"
              class="link"
              :to="item.to"
            >
              {{ item.label }}
            </router-link>
          </div>
        </div>

        <div class="col">
          <div class="title">{{ footerCopy.contactTitle }}</div>
          <div class="muted">{{ footerCopy.phoneLabel }}：{{ contact.phone }}</div>
          <div class="link-stack contact-links">
            <button type="button" class="link email-us-link" @click="openContactModal">{{ footerCopy.emailUsLabel }}</button>
          </div>
          <p v-if="footerSuccessMessage" class="footer-contact-success">{{ footerSuccessMessage }}</p>
        </div>
      </div>

      <div class="bottom">
        <div class="muted">© {{ new Date().getFullYear() }} {{ brandName }}</div>
        <div class="muted">{{ englishName }}</div>
      </div>
    </div>
  </footer>

  <ContactDrawer
    :open="isContactOpen"
    :copy="contactModalCopy"
    :contact-form="contactForm"
    :form-state="formState"
    :form-message="formMessage"
    :form-error="formError"
    :submit-button-label="contactModalCopy.submitLabel"
    @close="closeContactModal"
    @submit="submitContact"
  />
</template>

<style scoped>
.ftr {
  border-top: 1px solid color-mix(in srgb, var(--border) 75%, transparent);
  background: color-mix(in srgb, var(--surface-raised) 98%, transparent);
}

.ftr-inner {
  max-width: var(--layout-max-width);
  margin: 0 auto;
  padding: var(--spacing-lg) var(--spacing-md);
}

.cols {
  display: grid;
  gap: var(--spacing-md);
  grid-template-columns: 1fr;
}

.col .title {
  font-weight: 700;
  margin-bottom: 0.4rem;
}

.muted {
  opacity: 0.75;
  font-size: 14px;
}

.link {
  display: inline-flex;
  align-items: center;
  gap: var(--spacing-xs);
  color: inherit;
  padding: 0.25rem 0;
  line-height: 1.25;
}

.link-stack {
  display: grid;
  gap: 0;
  justify-items: start;
}

.info-links,
.contact-links {
  margin-top: 0.25rem;
}

.email-us-link {
  border: none;
  background: transparent;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
  text-decoration: underline;
  text-underline-offset: 0.12em;
}

.contact-link {
  font-weight: 700;
}

.footer-contact-success {
  margin: 0.35rem 0 0;
  font-size: 13px;
  color: color-mix(in srgb, #0f766e 85%, var(--text));
}

.bottom {
  margin-top: var(--spacing-md);
  padding-top: var(--spacing-sm);
  border-top: 1px solid color-mix(in srgb, var(--border) 75%, transparent);
  display: flex;
  flex-wrap: wrap;
  gap: var(--spacing-sm);
  justify-content: space-between;
  font-size: 14px;
}

@media (min-width: 768px) {
  .cols {
    grid-template-columns: 1.2fr 0.8fr 0.8fr;
    align-items: flex-start;
  }
}
</style>
