const toOverrideMap = (input) => {
  if (!input) return {};
  if (Array.isArray(input)) {
    return input.reduce((acc, entry) => {
      if (entry && entry.id) acc[entry.id] = entry;
      return acc;
    }, {});
  }
  if (typeof input === 'object') {
    return input;
  }
  return {};
};

const normalizeOverrideEntry = (entry) => {
  if (!entry) return {};
  if (typeof entry === 'string') return { label: entry };
  return entry;
};

const mergeCollection = (items, overrides) => {
  if (!Array.isArray(items) || !items.length) return items;
  const map = toOverrideMap(overrides);
  if (!Object.keys(map).length) return items;

  return items.map((item) => {
    if (!item || typeof item !== 'object') return item;
    const override = normalizeOverrideEntry(map[item.id]);
    if (!Object.keys(override).length) return item;
    return {
      ...item,
      label: override.label ?? item.label,
      title: override.title ?? item.title,
      name: override.name ?? item.name,
      tagline: override.tagline ?? item.tagline,
      description: override.description ?? item.description,
      body: override.body ?? item.body
    };
  });
};

export const applyBrandCopy = (brand, copyEntry = {}) => {
  if (!brand) return brand;

  const mergedAssets = {
    ...brand.assets,
    settings: mergeCollection(brand.assets?.settings, copyEntry.settings),
    elements: mergeCollection(brand.assets?.elements, copyEntry.elements),
    ritualScenes: mergeCollection(brand.assets?.ritualScenes, copyEntry.ritualScenes),
    ctaButtons: mergeCollection(brand.assets?.ctaButtons, copyEntry.ctaButtons)
  };

  return {
    ...brand,
    name: copyEntry.name ?? brand.name,
    tagline: copyEntry.tagline ?? brand.tagline,
    description: copyEntry.description ?? brand.description,
    assets: mergedAssets,
    highlights: mergeCollection(brand.highlights, copyEntry.highlights)
  };
};

export default applyBrandCopy;
