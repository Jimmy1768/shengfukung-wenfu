<script setup>
import { computed, ref, watch } from 'vue';

import project from '@/app/project.js';
import { useTempleContent } from '@/app/siteContent.js';
import { buildAccountLoginUrl } from '@/utils/accountLinks.js';

const props = defineProps({
  activeKey: { type: [String, Object], default: 'home' },
});

const active = computed(() =>
  typeof props.activeKey === 'string' ? props.activeKey : props.activeKey?.value
);

const menuOpen = ref(false);
const toggleMenu = () => {
  menuOpen.value = !menuOpen.value;
};
const closeMenu = () => {
  menuOpen.value = false;
};

watch(active, () => closeMenu());

const navItems = [
  { key: 'home', label: '首頁', to: '/' },
  { key: 'about', label: '關於', to: '/about' },
  { key: 'news', label: '最新消息', to: '/news' },
  { key: 'services', label: '祈福服務', to: '/services' },
  { key: 'events', label: '活動資訊', to: '/events' },
  { key: 'archive', label: '活動回顧', to: '/archive' },
  { key: 'contact', label: '聯絡', to: '/contact' },
];

const siteContent = useTempleContent();
const brandName = computed(() => siteContent.data?.name || project.name);
const brandTagline = computed(
  () => siteContent.data?.tagline || project.tagline || project.englishName
);
const accountLoginUrl = buildAccountLoginUrl();
</script>

<template>
  <header class="hdr">
    <div class="hdr-inner">
      <router-link class="brand" to="/" @click="closeMenu">
        <div class="brand-mark" aria-hidden="true"></div>
        <div class="brand-text">
          <div class="brand-name">{{ brandName }}</div>
          <div class="brand-sub">{{ brandTagline }}</div>
        </div>
      </router-link>

      <button
        class="menu-toggle"
        type="button"
        :aria-expanded="menuOpen"
        aria-controls="primary-nav"
        @click="toggleMenu"
      >
        <span class="menu-icon" aria-hidden="true"></span>
        <span class="menu-label">主選單</span>
      </button>

      <nav
        id="primary-nav"
        class="nav"
        :class="{ 'is-open': menuOpen }"
        aria-label="Primary"
      >
        <router-link
          v-for="item in navItems"
          :key="item.key"
          class="nav-link"
          :class="{ on: active === item.key }"
          :to="item.to"
          @click="closeMenu"
        >
          {{ item.label }}
        </router-link>
      </nav>

      <div class="actions">
        <a class="btn cta" :href="accountLoginUrl">登入 / 報名</a>
      </div>
    </div>
  </header>
</template>

<style scoped>
.hdr {
  position: sticky;
  top: 0;
  z-index: 50;
  backdrop-filter: blur(10px);
  background: color-mix(in srgb, var(--surface-raised) 92%, transparent);
  border-bottom: 1px solid color-mix(in srgb, var(--border) 80%, transparent);
}

.hdr-inner {
  position: relative;
  max-width: var(--layout-max-width);
  margin: 0 auto;
  padding: var(--spacing-sm) var(--spacing-md);
  display: grid;
  grid-template-columns: auto auto;
  gap: var(--spacing-sm);
  align-items: center;
}

.brand {
  display: inline-flex;
  gap: var(--spacing-sm);
  align-items: center;
  color: inherit;
}

.brand-mark {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-md);
  background: linear-gradient(135deg, var(--primary), var(--accent));
  box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.15);
}

.brand-name {
  font-weight: 700;
  letter-spacing: 0.2px;
  line-height: 1.1;
}

.brand-sub {
  font-size: 12px;
  opacity: 0.75;
  margin-top: 2px;
}

.menu-toggle {
  /* 44px is the comfortable minimum for a finger. The toggle is phone-only --
     the desktop block hides it -- so this needs no counterpart there. */
  min-height: 44px;
  justify-self: end;
  border: 1px solid color-mix(in srgb, var(--border) 80%, transparent);
  border-radius: var(--radius-sm);
  padding: calc(var(--spacing-xs) * 2) var(--spacing-sm);
  background: transparent;
  color: inherit;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: var(--spacing-xs);
}

.menu-icon {
  width: 18px;
  height: 2px;
  border-radius: 2px;
  background: currentColor;
  box-shadow: 0 5px 0 currentColor, 0 -5px 0 currentColor;
  display: inline-block;
}

.nav {
  grid-column: 1 / -1;
  display: flex;
  flex-direction: column;
  gap: var(--spacing-xs);
  max-height: 0;
  overflow: hidden;
  opacity: 0;
  transition: max-height 200ms ease, opacity 200ms ease;
  border-top: 1px solid transparent;
}

.nav.is-open {
  padding-top: var(--spacing-sm);
  max-height: 400px;
  opacity: 1;
  border-color: color-mix(in srgb, var(--border) 80%, transparent);
}

.nav-link {
  /* Phone rules. Each link measured 30px -- 14px text at the global 1.6
     line-height, plus 4px of padding top and bottom -- which is under the 44px
     a finger needs. min-height raises the box; flex centres the label inside it
     so the extra height is not all below the text; and because the link is the
     flex item, the whole 44px is the tap target rather than just the text.
     These three are undone in the 900px block: the same links sit inline in the
     desktop header and must not grow. */
  min-height: 44px;
  display: flex;
  align-items: center;
  padding: var(--spacing-xs) var(--spacing-sm);
  border-radius: var(--radius-sm);
  font-size: 14px;
  color: inherit;
  opacity: 0.85;
}

.nav-link.on {
  background: color-mix(in srgb, var(--accent) 25%, transparent);
  color: var(--accent);
  opacity: 1;
  font-weight: 700;
}

.actions {
  display: none;
}

.cta {
  background: var(--primary);
  color: var(--primary-foreground);
  border-radius: var(--radius-md);
  padding: var(--spacing-xs) var(--spacing-sm);
  font-size: 14px;
}

@media (min-width: 900px) {
  .hdr-inner {
    grid-template-columns: auto 1fr auto;
  }

  .menu-toggle {
    display: none;
  }

  .nav {
    grid-column: auto;
    flex-direction: row;
    align-items: center;
    opacity: 1;
    max-height: none;
    padding-top: 0;
    border: 0;
    justify-content: center;
  }

  .nav-link {
    /* Undo the phone tap-target rules. A flex item is blockified, so `block` is
       what these links already computed to here; min-height returns to nothing.
       The desktop header is unchanged. */
    min-height: 0;
    display: block;
    font-size: 15px;
  }

  .actions {
    display: flex;
    justify-content: flex-end;
  }

  .cta {
    padding: calc(var(--spacing-xs) * 2) var(--spacing-md);
  }
}
</style>
