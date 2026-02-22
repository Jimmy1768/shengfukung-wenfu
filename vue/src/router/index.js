import { createRouter, createWebHistory } from 'vue-router';

import MarketingLanding from '@/showcase/MarketingLanding.vue';
import DemoShowcase from '@/showcase/DemoShowcase.vue';
import project from '@/app/project.js';
import { useTempleContent } from '@/app/siteContent.js';
import { resolveSiteLayoutRoute } from '@/layouts/index.js';

const routes = [
  resolveSiteLayoutRoute(),
  // Hidden marketing/showcase routes. Keep separate from client layout routes.
  // Do not remove during layout/router refactors unless replacing the showcase feature.
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
  const isShowcaseRoute =
    to?.path === '/marketing' ||
    to?.path === '/marketing/demo' ||
    to?.path === '/demo';
  const showcaseBrand = project.companyName || 'SourceGrid Labs';
  const baseTitle = isShowcaseRoute
    ? showcaseBrand
    : (
      siteContent.data?.name ||
      project.name ||
      project.englishName ||
      '寺廟'
    );
  const title = to?.meta?.title ? `${to.meta.title}｜${baseTitle}` : baseTitle;
  document.title = title;
});

export default router;
