import { createRouter, createWebHistory } from 'vue-router';

import MarketingLanding from '../views/MarketingLanding.vue';
import DemoShowcase from '../views/DemoShowcase.vue';
import SiteLayout from '@/layouts/SiteLayout.vue';
import project from '@/app/project.js';
import { useTempleContent } from '@/app/siteContent.js';

import Home from '@/pages/Home.vue';
import About from '@/pages/About.vue';
import Events from '@/pages/Events.vue';
import EventShow from '@/pages/EventShow.vue';
import Archive from '@/pages/Archive.vue';
import News from '@/pages/News.vue';
import Services from '@/pages/Services.vue';
import Contact from '@/pages/Contact.vue';

const routes = [
  {
    path: '/',
    component: SiteLayout,
    children: [
      { path: '', name: 'home', component: Home, meta: { title: '首頁' } },
      { path: 'about', name: 'about', component: About, meta: { title: '關於本廟' } },
      { path: 'events', name: 'events', component: Events, meta: { title: '活動 / 法會' } },
      { path: 'events/:slug', name: 'event', component: EventShow, meta: { title: '活動詳情' } },
      { path: 'archive', name: 'archive', component: Archive, meta: { title: '活動回顧' } },
      { path: 'news', name: 'news', component: News, meta: { title: '最新消息' } },
      { path: 'services', name: 'services', component: Services, meta: { title: '參拜 / 服務' } },
      { path: 'contact', name: 'contact', component: Contact, meta: { title: '聯絡 / 交通' } },
    ],
  },
  {
    path: '/marketing',
    name: 'marketing',
    component: MarketingLanding
  },
  {
    path: '/marketing/demo',
    name: 'marketing-demo',
    component: DemoShowcase
  },
  {
    path: '/demo',
    redirect: '/marketing/demo'
  }
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
});

const siteContent = useTempleContent();

router.afterEach((to) => {
  const baseTitle =
    siteContent.data?.name ||
    project.name ||
    project.englishName ||
    '寺廟';
  const title = to?.meta?.title ? `${to.meta.title}｜${baseTitle}` : baseTitle;
  document.title = title;
});

export default router;
