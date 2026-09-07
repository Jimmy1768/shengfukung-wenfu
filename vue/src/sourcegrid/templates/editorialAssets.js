import hotelCollageAnchor from '@/assets/media/hotel/editorial/collage-anchor-suite-vertical.webp';
import hotelCollageOffset from '@/assets/media/hotel/editorial/collage-offset-terrace-frame.webp';
import hotelCollageDetail from '@/assets/media/hotel/editorial/collage-detail-ritual-hands.webp';
import hotelCollageAtmosphere from '@/assets/media/hotel/editorial/collage-atmosphere-light-haze.webp';
import hotelAmbientLinen from '@/assets/media/hotel/editorial/editorial-detail-linen-light.webp';
import hotelAmbientHorizon from '@/assets/media/hotel/editorial/editorial-horizon-sunrise.webp';

import ramenCollageAnchor from '@/assets/media/ramen/editorial/collage-anchor-suite-vertical.webp';
import ramenCollageOffset from '@/assets/media/ramen/editorial/collage-offset-terrace-frame.webp';
import ramenCollageDetail from '@/assets/media/ramen/editorial/collage-detail-ritual-hands.webp';
import ramenCollageAtmosphere from '@/assets/media/ramen/editorial/collage-atmosphere-light-haze.webp';
import ramenAmbientLinen from '@/assets/media/ramen/editorial/editorial-detail-linen-light.webp';
import ramenAmbientHorizon from '@/assets/media/ramen/editorial/editorial-horizon-sunrise.webp';

import clothingCollageAnchor from '@/assets/media/clothing/editorial/collage-anchor-suite-vertical.webp';
import clothingCollageOffset from '@/assets/media/clothing/editorial/collage-offset-terrace-fram.webp';
import clothingCollageDetail from '@/assets/media/clothing/editorial/collage-detail-ritual-hands.webp';
import clothingCollageAtmosphere from '@/assets/media/clothing/editorial/collage-atmosphere-light-haze.webp';
import clothingAmbientLinen from '@/assets/media/clothing/editorial/editorial-detail-linen-light.webp';
import clothingAmbientHorizon from '@/assets/media/clothing/editorial/editorial-horizon-sunrise.webp';

export const editorialAssetSets = {
  hotel: {
    collageAnchor: hotelCollageAnchor,
    collageOffset: hotelCollageOffset,
    collageDetail: hotelCollageDetail,
    collageAtmosphere: hotelCollageAtmosphere,
    ambientLinen: hotelAmbientLinen,
    ambientHorizon: hotelAmbientHorizon
  },
  ramen: {
    collageAnchor: ramenCollageAnchor,
    collageOffset: ramenCollageOffset,
    collageDetail: ramenCollageDetail,
    collageAtmosphere: ramenCollageAtmosphere,
    ambientLinen: ramenAmbientLinen,
    ambientHorizon: ramenAmbientHorizon
  },
  clothing: {
    collageAnchor: clothingCollageAnchor,
    collageOffset: clothingCollageOffset,
    collageDetail: clothingCollageDetail,
    collageAtmosphere: clothingCollageAtmosphere,
    ambientLinen: clothingAmbientLinen,
    ambientHorizon: clothingAmbientHorizon
  }
};

export const getEditorialAssetsForBrand = (brandId) =>
  editorialAssetSets[brandId] ?? editorialAssetSets.hotel;
