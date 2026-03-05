import hotelCollageAnchor from '@/assets/media/hotel/editorial/collage-anchor-suite-vertical.png';
import hotelCollageOffset from '@/assets/media/hotel/editorial/collage-offset-terrace-frame.png';
import hotelCollageDetail from '@/assets/media/hotel/editorial/collage-detail-ritual-hands.png';
import hotelCollageAtmosphere from '@/assets/media/hotel/editorial/collage-atmosphere-light-haze.png';
import hotelAmbientLinen from '@/assets/media/hotel/editorial/editorial-detail-linen-light.png';
import hotelAmbientHorizon from '@/assets/media/hotel/editorial/editorial-horizon-sunrise.png';

import ramenCollageAnchor from '@/assets/media/ramen/editorial/collage-anchor-suite-vertical.png';
import ramenCollageOffset from '@/assets/media/ramen/editorial/collage-offset-terrace-frame.png';
import ramenCollageDetail from '@/assets/media/ramen/editorial/collage-detail-ritual-hands.png';
import ramenCollageAtmosphere from '@/assets/media/ramen/editorial/collage-atmosphere-light-haze.png';
import ramenAmbientLinen from '@/assets/media/ramen/editorial/editorial-detail-linen-light.png';
import ramenAmbientHorizon from '@/assets/media/ramen/editorial/editorial-horizon-sunrise.png';

import clothingCollageAnchor from '@/assets/media/clothing/editorial/collage-anchor-suite-vertical.png';
import clothingCollageOffset from '@/assets/media/clothing/editorial/collage-offset-terrace-fram.png';
import clothingCollageDetail from '@/assets/media/clothing/editorial/collage-detail-ritual-hands.png';
import clothingCollageAtmosphere from '@/assets/media/clothing/editorial/collage-atmosphere-light-haze.png';
import clothingAmbientLinen from '@/assets/media/clothing/editorial/editorial-detail-linen-light.png';
import clothingAmbientHorizon from '@/assets/media/clothing/editorial/editorial-horizon-sunrise.png';

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
