import { CLASSIC_LAYOUT_ID, createClassicRoute } from './classic/routes.js';

const DEFAULT_LAYOUT = CLASSIC_LAYOUT_ID;

function applyTemplateDataset(templateId) {
  if (typeof document === 'undefined') return;
  document.documentElement.dataset.template = templateId;
}

export function getAvailableLayouts() {
  return [CLASSIC_LAYOUT_ID];
}

export function getActiveLayoutId() {
  return import.meta.env.VITE_TEMPLE_LAYOUT || DEFAULT_LAYOUT;
}

export function resolveSiteLayoutRoute() {
  const layoutId = getActiveLayoutId();

  if (layoutId === CLASSIC_LAYOUT_ID) {
    applyTemplateDataset(CLASSIC_LAYOUT_ID);
    return createClassicRoute();
  }

  if (import.meta.env.DEV) {
    console.warn(`Unknown layout '${layoutId}', falling back to '${DEFAULT_LAYOUT}'.`);
  }
  applyTemplateDataset(CLASSIC_LAYOUT_ID);
  return createClassicRoute();
}
