export function buildHeroCtas({ brand, copy, limit = 3 }) {
  const assets = brand?.assets ?? {};
  const baseCtas = (assets.ctaButtons ?? []).slice(0, limit);
  if (baseCtas.length >= limit) {
    return baseCtas;
  }

  const brandName = brand?.name || 'Signature feature';
  const homeCopy = copy?.home ?? {};
  const fallbackLabel = (index) =>
    homeCopy[`scene${(index % 4) + 1}Title`] ||
    homeCopy.galleryFallback ||
    homeCopy.eyebrow ||
    `${brandName} ${index + 1}`;
  const fallbackDescription = (index) =>
    homeCopy[`scene${(index % 4) + 1}Body`] ||
    homeCopy.sceneFallback ||
    copy?.home?.body ||
    brand?.description ||
    brand?.tagline ||
    '';

  const seenImages = new Set(baseCtas.map((cta) => cta.image).filter(Boolean));
  const fallback = [];
  const pushCandidate = (candidate) => {
    if (!candidate) return;
    const image = candidate.image || candidate.src;
    if (image && seenImages.has(image)) {
      return;
    }
    if (image) {
      seenImages.add(image);
    }
    const index = fallback.length;
    fallback.push({
      id: candidate.id || `brand-cta-${index}`,
      label: candidate.label || fallbackLabel(index),
      description: candidate.description || fallbackDescription(index),
      image
    });
  };

  const pushFromCollection = (collection) => {
    if (!Array.isArray(collection)) return;
    collection.forEach((item, index) => {
      if (typeof item === 'string') {
        pushCandidate({ id: `brand-image-${index}`, image: item });
      } else {
        pushCandidate(item);
      }
    });
  };

  pushFromCollection(assets.elements);
  pushFromCollection(assets.ritualScenes);
  pushFromCollection(assets.settings);
  pushFromCollection(
    Array.isArray(assets.gallery)
      ? assets.gallery.map((image, index) =>
          typeof image === 'string' ? { id: `gallery-${index}`, image } : image
        )
      : []
  );
  pushFromCollection(assets.pricingShots);

  const combined = [...baseCtas, ...fallback];
  if (!combined.length) {
    return [
      {
        id: 'brand-cta-default',
        label: fallbackLabel(0),
        description: fallbackDescription(0)
      }
    ];
  }

  return combined.slice(0, limit);
}
