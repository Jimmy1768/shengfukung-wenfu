import { computed, reactive } from 'vue';

const state = reactive({
  status: 'idle',
  data: null,
  error: null
});

const DEFAULT_BASE = 'http://localhost:3001';
const DEFAULT_SLUG = import.meta.env.VITE_TEMPLE_SLUG || 'shenfukung-wenfu';

export async function loadTempleContent(slug = DEFAULT_SLUG) {
  state.status = 'loading';
  state.error = null;

  const base =
    import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '') || DEFAULT_BASE;

  try {
    const response = await fetch(`${base}/api/v1/temples/${slug}`);
    if (!response.ok) {
      throw new Error(`Request failed (${response.status})`);
    }
    state.data = await response.json();
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
