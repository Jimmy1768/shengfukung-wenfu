import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import './styles/global.css';
import { defaultThemeId, themes } from './theme/themes';
import { readPersistedTheme } from './utils/themePersistence';

const persistedTheme = readPersistedTheme();
const initialTheme =
  persistedTheme && themes[persistedTheme] ? persistedTheme : defaultThemeId;
document.documentElement.dataset.theme =
  document.documentElement.dataset.theme || initialTheme;

createApp(App).use(router).mount('#app');
