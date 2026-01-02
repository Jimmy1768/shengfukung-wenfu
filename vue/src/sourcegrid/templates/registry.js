import LumenHarbor from './LumenHarbor.vue';
import SaffronHeatwave from './SaffronHeatwave.vue';
import GlassGrid from './GlassGrid.vue';
import BistroNoir from './BistroNoir.vue';

export const templateRegistry = [
  {
    id: 'lumen-harbor',
    label: 'Lumen Harbor',
    description: 'Service-forward split layout with editorial gallery cards and menu pricing.',
    component: LumenHarbor
  },
  {
    id: 'saffron-heatwave',
    label: 'Saffron Heatwave',
    description: 'Sensory heatmap hero with animated broth and layered textures.',
    component: SaffronHeatwave
  },
  {
    id: 'glass-grid',
    label: 'Glass Grid',
    description: 'Modern glassmorphic grid with layered neon tiles and parallax scroll.',
    component: GlassGrid
  },
  {
    id: 'bistro-noir',
    label: 'Bistro Noir',
    description: 'Editorial split panels framed by cinematic typography and bold gradients.',
    component: BistroNoir
  }
];

export const defaultTemplateId = 'saffron-heatwave';
