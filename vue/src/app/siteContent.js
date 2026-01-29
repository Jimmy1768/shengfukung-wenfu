import { computed, reactive } from 'vue';
import {
  fetchTempleArchive,
  fetchTempleEvent,
  fetchTempleEvents,
  fetchTempleNews,
  fetchTempleProfile
} from '@/app/templeApi.js';

const state = reactive({
  status: 'idle',
  data: null,
  news: [],
  archive: [],
  events: [],
  eventDetails: {},
  error: null
});

export async function loadTempleContent() {
  state.status = 'loading';
  state.error = null;

  try {
    const [profile, news, archive, events] = await Promise.all([
      fetchTempleProfile(),
      fetchTempleNews({ limit: 10 }),
      fetchTempleArchive(),
      fetchTempleEvents({ limit: 25, status: 'upcoming' })
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
  return computed(() => state.events || []);
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
    return (
      heroImages[tab] ||
      heroImages.home ||
      state.data?.primary_image_url ||
      null
    );
  });
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
