import { createRouter, createWebHistory } from 'vue-router';

import project from '@/app/project.js';
import { useTempleContent } from '@/app/siteContent.js';
import { resolveSiteLayoutRoute } from '@/layouts/index.js';

const routes = [resolveSiteLayoutRoute()];

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
