import { computed, reactive } from 'vue';
import {
  fetchTempleArchive,
  fetchTempleEvent,
  fetchTempleEvents,
  fetchTempleGatherings,
  fetchTempleNews,
  fetchTempleProfile,
  fetchTempleService,
  fetchTempleServices
} from '@/app/templeApi.js';

const PLACEHOLDER_IMG_PATTERN = /placehold\.co/i;

const state = reactive({
  status: 'idle',
  data: null,
  news: [],
  archive: [],
  events: [],
  gatherings: [],
  services: [],
  eventDetails: {},
  serviceDetails: {},
  error: null
});

export async function loadTempleContent() {
  state.status = 'loading';
  state.error = null;

  try {
    const [profile, news, archive, events, gatherings, services] = await Promise.all([
      fetchTempleProfile(),
      fetchTempleNews({ limit: 10 }),
      fetchTempleArchive(),
      fetchTempleEvents({ limit: 25, status: 'upcoming' }),
      fetchTempleGatherings(),
      fetchTempleServices({ limit: 100 })
    ]);
    state.data = profile;
    state.news = news?.news || [];
    state.archive = archive?.entries || [];
    state.events = events?.events || [];
    state.events.forEach((event) => {
      if (event?.slug) {
        state.eventDetails[event.slug] = event;
      }
    });
    state.gatherings = gatherings?.gatherings || [];
    state.gatherings.forEach((gathering) => {
      if (gathering?.slug) {
        state.eventDetails[gathering.slug] = gathering;
      }
    });
    state.services = services?.services || [];
    state.services.forEach((service) => {
      if (service?.slug) {
        state.serviceDetails[service.slug] = service;
      }
    });
    state.status = 'ready';
  } catch (error) {
    state.status = 'error';
    state.error = error;
    console.error('Temple content load failed', error);
  }
}

export function useTempleContent() {
  return state;
}

export function useTemplePage(kind) {
  return computed(() => {
    if (!state.data?.pages) return null;
    return state.data.pages.find((page) => page.kind === kind) || null;
  });
}

export function useTempleSections(kind) {
  const page = useTemplePage(kind);
  return computed(() => page.value?.sections || []);
}

export function useTempleNews() {
  return computed(() => state.news || []);
}

export function useTempleArchive() {
  return computed(() => state.archive || []);
}

export function useTempleEvents() {
  return computed(() => {
    const events = state.events || [];
    const gatherings = state.gatherings || [];
    const combined = [...events, ...gatherings];
    return combined.sort((a, b) => {
      const aTime = a.starts_on ? new Date(a.starts_on).getTime() : Infinity;
      const bTime = b.starts_on ? new Date(b.starts_on).getTime() : Infinity;
      return aTime - bTime;
    });
  });
}

export function useTempleOfferings() {
  return computed(() => state.events || []);
}

export function useTempleGatherings() {
  return computed(() => state.gatherings || []);
}

export function useTempleServices() {
  return computed(() => state.services || []);
}

export function useTempleEvent(slugRef) {
  return computed(() => {
    const slug =
      typeof slugRef === 'string' ? slugRef : slugRef?.value;
    if (!slug) return null;
    return (
      state.eventDetails[slug] ||
      state.events.find((event) => event.slug === slug) ||
      null
    );
  });
}

export function useHeroImage(tab) {
  return computed(() => {
    const heroImages = state.data?.hero_images || {};
    const tabKey = tab?.toString() || 'home';
    const tabImage = resolveHeroImage(heroImages[tabKey], { allowPlaceholder: tabKey === 'home' });
    if (tabImage) return tabImage;

    return resolveHeroImage(heroImages.home, { allowPlaceholder: true });
  });
}

function resolveHeroImage(value, options = {}) {
  if (typeof value !== 'string' || !value.trim()) {
    return null;
  }

  const { allowPlaceholder = false } = options;
  if (!allowPlaceholder && PLACEHOLDER_IMG_PATTERN.test(value)) {
    return null;
  }

  return value;
}

export async function loadTempleEvent(slug) {
  if (!slug) return null;
  if (state.eventDetails[slug]) {
    return state.eventDetails[slug];
  }

  try {
    const payload = await fetchTempleEvent(slug);
    const event = payload?.event || payload;
    if (event?.slug) {
      state.eventDetails[event.slug] = event;
    }
    return event;
  } catch (error) {
    console.error('Temple event load failed', error);
    throw error;
  }
}

export async function loadTempleService(slug) {
  if (!slug) return null;
  if (state.serviceDetails[slug]) {
    return state.serviceDetails[slug];
  }

  try {
    const payload = await fetchTempleService(slug);
    const service = payload?.service || payload;
    if (service?.slug) {
      state.serviceDetails[service.slug] = service;
    }
    return service;
  } catch (error) {
    console.error('Temple service load failed', error);
    throw error;
  }
}
