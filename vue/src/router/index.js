import { createRouter, createWebHistory } from 'vue-router';

import MarketingLanding from '../views/MarketingLanding.vue';
import DemoShowcase from '../views/DemoShowcase.vue';
import project from '@/app/project.js';
import { useTempleContent } from '@/app/siteContent.js';
import { resolveSiteLayoutRoute } from '@/layouts/index.js';

const routes = [
  resolveSiteLayoutRoute(),
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
