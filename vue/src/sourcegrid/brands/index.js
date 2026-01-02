import hotelSuite from '@/assets/media/hotel/hotel_suite_golden.png';
import hotelCourtyard from '@/assets/media/hotel/hotel_courtyard_evening.png';
import hotelPool from '@/assets/media/hotel/hotel_pool_twilight.png';
import hotelLobby from '@/assets/media/hotel/hotel_lobby_natural.png';
import hotelBreakfast from '@/assets/media/hotel/hotel_breakfast_tray.png';
import hotelSpa from '@/assets/media/hotel/hotel_spa_terrace.png';
import hotelBalcony from '@/assets/media/hotel/hotel_balcony_sunrise.png';
import hotelExterior from '@/assets/media/hotel/hotel_exterior_corner.png';
import hotelDetail from '@/assets/media/hotel/hotel_detail_ceramic.png';
import hotelTextureSand from '@/assets/media/hotel/hotel_gradient_sand.png';
import hotelTextureLinen from '@/assets/media/hotel/hotel_texture_linen.png';
import hotelTexturePool from '@/assets/media/hotel/hotel_texture_pool.png';
import hotelTowels from '@/assets/media/hotel/hotel_towels_spa.png';

import ramenHero from '@/assets/media/ramen/ramen_dining_area_glow.png';
import ramenInterior from '@/assets/media/ramen/ramen_interior_minimal.png';
import ramenBowlSteam from '@/assets/media/ramen/ramen_bowl_steam_close.png';
import ramenBowlQuiet from '@/assets/media/ramen/ramen_bowl_quiet_luxury.png';
import ramenBowlCeramic from '@/assets/media/ramen/ramen_bowl_ceramic_detail.png';
import ramenBrothPour from '@/assets/media/ramen/ramen_broth_pour.png';
import ramenChashu from '@/assets/media/ramen/ramen_chashu_close.png';
import ramenChefFinishing from '@/assets/media/ramen/ramen_chef_finishing.png';
import ramenChefService from '@/assets/media/ramen/ramen_chef_service.png';
import ramenAjitama from '@/assets/media/ramen/ramen_ajitama_close.png';
import ramenIngredients from '@/assets/media/ramen/ramen_ingredients_flatlay.png';
import ramenToppings from '@/assets/media/ramen/ramen_toppings_overhead.png';
import ramenTextureWood from '@/assets/media/ramen/ramen_texture_warm_wood.png';
import ramenTextureSoft from '@/assets/media/ramen/ramen_texture_soft_linen.png';
import ramenTextureCeramic from '@/assets/media/ramen/ramen_texture_ceramic_glaze.png';

import clothingHero from '@/assets/media/clothing/clothing_model_backlit.png';
import clothingStudio from '@/assets/media/clothing/clothing_model_studio.png';
import clothingStoreInterior from '@/assets/media/clothing/clothing_store_interior.png';
import clothingFittingArea from '@/assets/media/clothing/clothing_fitting_area.png';
import clothingFlatlay from '@/assets/media/clothing/clothing_flatlay_neutral.png';
import clothingAccessoryDisplay from '@/assets/media/clothing/clothing_accessory_display.png';
import clothingSleeveAdjust from '@/assets/media/clothing/clothing_model_sleeve_adjust.png';
import clothingSheerMotion from '@/assets/media/clothing/clothing_model_sheer_motion.png';
import clothingFoldedStack from '@/assets/media/clothing/clothing_folded_stack.png';
import clothingGradient from '@/assets/media/clothing/clothing_gradient_soft_beige.png';
import clothingTextureLinen from '@/assets/media/clothing/clothing_texture_cream_linen.png';
import clothingTextureStone from '@/assets/media/clothing/clothing_texture_matte_stone.png';
import clothingTextureWoven from '@/assets/media/clothing/clothing_texture_woven_detail.png';
import clothingMannequin from '@/assets/media/clothing/clothing_mannequin_close.png';

import bistroAtmosphereShadowGradient from '@/assets/media/restaurant/bistro_atmosphere_shadow_gradient.png';
import bistroDetailCandleSmoke from '@/assets/media/restaurant/bistro_detail_candle_smoke.png';
import bistroDetailCutlery from '@/assets/media/restaurant/bistro_detail_cutlery.png';
import bistroDetailGlassReflection from '@/assets/media/restaurant/bistro_detail_glass_reflection.png';
import bistroDetailLinen from '@/assets/media/restaurant/bistro_detail_linen.png';
import bistroDetailMenuPaper from '@/assets/media/restaurant/bistro_detail_menu_paper.png';
import bistroDetailWoodSurface from '@/assets/media/restaurant/bistro_detail_wood_surface.png';
import bistroFeatureBarSurface from '@/assets/media/restaurant/bistro_feature_bar_surface.png';
import bistroFeatureCornerBooth from '@/assets/media/restaurant/bistro_feature_corner_booth.png';
import bistroFeatureKitchenPass from '@/assets/media/restaurant/bistro_feature_kitchen_pass.png';
import bistroFeatureTableSetting from '@/assets/media/restaurant/bistro_feature_table_setting.png';
import bistroFeatureWineService from '@/assets/media/restaurant/bistro_feature_wine_service.png';
import bistroHeroBarRitual from '@/assets/media/restaurant/bistro_hero_bar_ritual.png';
import bistroHeroDiningNoir from '@/assets/media/restaurant/bistro_hero_dining_noir.png';
import bistroHeroExteriorNight from '@/assets/media/restaurant/bistro_hero_exterior_night.png';

export const brands = [
  {
    id: 'hotel',
    name: 'Emberlight Boutique Hotel',
    tagline: 'Luminous stays for urban tastemakers.',
    description: 'Luxury urban retreat with spa, courtyard, and seasonal tasting menu.',
    recommendedTemplate: 'lumen-harbor',
    palette: {
      brandAccent: '#f8ab57',
      brandAccentForeground: '#0f172a'
    },
    assets: {
      hero: hotelBalcony,
      secondary: hotelCourtyard,
      heroFeature: hotelSuite,
      gradientBackdrop: hotelTextureSand,
      settings: [
        { id: 'lobby', label: 'Lobby Lounge', image: hotelLobby },
        { id: 'pool', label: 'Infinity Pool', image: hotelPool },
        { id: 'courtyard', label: 'Courtyard', image: hotelCourtyard },
        { id: 'suite', label: 'Skyline Suite', image: hotelSuite }
      ],
      elements: [
        {
          id: 'chefs-salon',
          label: 'Chef’s Salon',
          description: 'Sunrise tasting menus with tableside infusions and seasonal patisserie.',
          image: hotelBreakfast
        },
        {
          id: 'garden-spa',
          label: 'Garden Spa Rituals',
          description: 'Steam, soak, and breathe in the cedar hammam perched above the courtyard.',
          image: hotelSpa
        },
        {
          id: 'wellness-towels',
          label: 'Wellness Atelier',
          description: 'Freshly steeped towels, aromatherapy blends, and on-call spa sommeliers.',
          image: hotelTowels
        },
        {
          id: 'atelier',
          label: 'Handcrafted Detail',
          description: 'Plaster arches, ceramic inlays, and bespoke textiles from local artisans.',
          image: hotelDetail
        }
      ],
      gallery: [hotelSuite, hotelBreakfast, hotelDetail],
      pricingFeature: hotelExterior,
      textures: {
        soft: hotelTextureLinen,
        deep: hotelTexturePool
      }
    },
    highlights: [
      {
        id: 'curated-suites',
        title: 'Curated Suites',
        body: 'Sun-flooded residences framed by sculpted plaster arches and bespoke linens.'
      },
      {
        id: 'garden-spa-rituals',
        title: 'Garden Spa Rituals',
        body: 'Rooftop onsen, private hammam sessions, and in-room wellness sommeliers.'
      },
      {
        id: 'chef-salon',
        title: 'Chef’s Salon',
        body: 'Seasonal tasting menus paired with boutique producers and ceremonial tea.'
      }
    ]
  },
  {
    id: 'ramen',
    name: 'Kintsu Ramen',
    tagline: 'Broth ceremonies for the night market soul.',
    description: 'Smoke-fired broths, vinyl-lit dining rooms, and ceramic craft for ramen devotees.',
    recommendedTemplate: 'saffron-heatwave',
    palette: {
      brandAccent: '#f97316',
      brandAccentForeground: '#0f172a'
    },
    assets: {
      hero: ramenHero,
      secondary: ramenInterior,
      heroFeature: ramenBowlSteam,
      gradientBackdrop: ramenTextureWood,
      ctaButtons: [
        {
          id: 'ajitama-flight',
          label: 'Ajitama Torch',
          description: 'Soft-yolk egg torched with black sugar tare at the counter.',
          image: ramenAjitama
        },
        {
          id: 'midnight-toppings',
          label: 'Midnight Toppings',
          description: 'Shaved negi, furikake crumble, and chili threads for every seating.',
          image: ramenToppings
        },
        {
          id: 'mise-tray',
          label: 'Mise Rituals',
          description: 'Small-format botanicals, tare, and oils plated per guest.',
          image: ramenIngredients
        }
      ],
      ritualScenes: [
        {
          id: 'chef-counter',
          label: 'Chef’s Counter',
          description: 'Counter-only service with vinyl glow and twelve stools.',
          image: ramenChefService
        },
        {
          id: 'broth-lab',
          label: 'Broth Lab',
          description: 'Smoked shio, yuzu shoyu, and embered tantan poured in sequence.',
          image: ramenBrothPour
        },
        {
          id: 'ceramic-atelier',
          label: 'Ceramic Atelier',
          description: 'Studio-fired bowls, matte chopsticks, and brass ladles.',
          image: ramenBowlCeramic
        },
        {
          id: 'lounge',
          label: 'Afterglow Lounge',
          description: 'Low lighting, steam trails, and the hush of late seatings.',
          image: ramenInterior
        }
      ],
      settings: [
        { id: 'chef-counter', label: 'Chef’s Counter', image: ramenChefService },
        { id: 'broth-lab', label: 'Broth Lab', image: ramenBrothPour },
        { id: 'ceramic', label: 'Ceramic Atelier', image: ramenBowlCeramic },
        { id: 'lounge', label: 'Midnight Lounge', image: ramenInterior }
      ],
      elements: [
        {
          id: 'umami-flight',
          label: 'Umami Flight',
          description: 'Progressive tastings of smoked shio, yuzu shoyu, and embered tantan broths.',
          image: ramenBowlQuiet
        },
        {
          id: 'chashu-atelier',
          label: 'Chashu Atelier',
          description: 'Hand-torched collar finished tableside with black sugar tare and sansho ash.',
          image: ramenChashu
        },
        {
          id: 'finishing-school',
          label: 'Finishing School',
          description: 'Chefs finish every bowl beneath cedar light with micro-herb garnishes.',
          image: ramenChefFinishing
        },
        {
          id: 'steam-bowl',
          label: 'Steam Bowl',
          description: 'Signature bowl crowned with chili threads and black garlic oil.',
          image: ramenBowlSteam
        }
      ],
      gallery: [ramenBowlSteam, ramenToppings, ramenChefFinishing],
      pricingFeature: ramenHero,
      pricingHero: ramenBowlSteam,
      pricingShots: [
        {
          id: 'umami-flight',
          label: 'Umami Flight',
          description: 'Five-course tasting spanning smoke, citrus, and embered heat.',
          image: ramenBowlQuiet
        },
        {
          id: 'kiln-fire',
          label: 'Kiln Fired Chashu',
          description: 'Collar torched table-side with sansho ash.',
          image: ramenChashu
        },
        {
          id: 'service-finish',
          label: 'Service Finish',
          description: 'Chefs finish bowls beneath cedar light before plating.',
          image: ramenChefFinishing
        }
      ],
      textures: {
        soft: ramenTextureSoft,
        deep: ramenTextureCeramic,
        grain: ramenTextureWood
      }
    },
    highlights: [
      {
        id: 'broth-ceremony',
        title: 'Broth Ceremony',
        body: '12-hour kombu reductions smoked over binchotan and poured in sequential flights.'
      },
      {
        id: 'ceramic-studio',
        title: 'Ceramic Studio',
        body: 'Custom stoneware from Kyoto kilns with hand-pressed thumb rests for mindful sipping.'
      },
      {
        id: 'vinyl-service',
        title: 'Vinyl Service',
        body: 'Downtempo sets scored to each seating for calm, amber-lit dining rooms.'
      }
    ]
  },
  {
    id: 'clothing',
    name: 'Loom & Light Atelier',
    tagline: 'Modular wardrobes for slow luxury.',
    description: 'Seoul-inspired tailoring studio with private fittings, capsule edits, and tactile styling.',
    recommendedTemplate: 'glass-grid',
    palette: {
      brandAccent: '#d4a373',
      brandAccentForeground: '#0f172a'
    },
    assets: {
      hero: clothingHero,
      secondary: clothingStoreInterior,
      heroFeature: clothingStudio,
      gradientBackdrop: clothingGradient,
      settings: [
        { id: 'fittings', label: 'Private Fittings', image: clothingFittingArea },
        { id: 'flatlay', label: 'Capsule Flatlays', image: clothingFlatlay },
        { id: 'atelier', label: 'Accessory Atelier', image: clothingAccessoryDisplay },
        { id: 'tailoring', label: 'Tailor’s Bench', image: clothingSleeveAdjust }
      ],
      elements: [
        {
          id: 'capsule',
          label: 'Capsule Builds',
          description: 'Seamless edits of 15-piece wardrobes with modular pairings and care rituals.',
          image: clothingFoldedStack
        },
        {
          id: 'casting',
          label: 'Casting Suites',
          description: 'Sun-lit studio sessions with cinematic draping for lookbooks and launches.',
          image: clothingSheerMotion
        },
        {
          id: 'textile-lab',
          label: 'Textile Lab',
          description: 'Material library featuring hand-loomed linen, matte stone, and woven jacquard.',
          image: clothingTextureWoven
        },
        {
          id: 'mannequin',
          label: 'Sculpted Forms',
          description: 'Signature mannequin styling with jewelry, scent stories, and layered textures.',
          image: clothingMannequin
        }
      ],
      gallery: [clothingStudio, clothingAccessoryDisplay, clothingHero],
      pricingFeature: clothingStoreInterior,
      textures: {
        soft: clothingTextureLinen,
        deep: clothingTextureStone
      }
    },
    highlights: [
      {
        id: 'private-atelier',
        title: 'Private Atelier',
        body: 'One-to-one fittings with wardrobe architects, tea service, and live tailoring.'
      },
      {
        id: 'capsule-mapping',
        title: 'Capsule Mapping',
        body: 'Lookbook-grade planning sessions that translate into weekly rotation charts.'
      },
      {
        id: 'tactile-rituals',
        title: 'Tactile Rituals',
        body: 'Fabric care ceremonies featuring cedar steam, silk stones, and minimalist scent.'
      }
    ]
  },
  {
    id: 'nocturne-vale',
    name: 'Nocturne Vale',
    tagline: 'Candlelit tasting parlor for midnight patrons.',
    description: 'Shadow-drenched supper club with sommelier theatrics, smoke-layered flights, and velvet service corridors.',
    recommendedTemplate: 'bistro-noir',
    palette: {
      brandAccent: '#c084fc',
      brandAccentForeground: '#0f172a'
    },
    assets: {
      hero: bistroHeroDiningNoir,
      secondary: bistroHeroExteriorNight,
      heroFeature: bistroHeroBarRitual,
      gradientBackdrop: bistroAtmosphereShadowGradient,
      ritualScenes: [
        {
          id: 'wine-service',
          label: 'Sommelier Ritual',
          description: 'Torch-finished pours and crystal service drifting through violet light.',
          image: bistroFeatureWineService
        },
        {
          id: 'kitchen-pass',
          label: 'Kitchen Pass',
          description: 'Low light cut through steam as chefs send plated courses to candlelit runners.',
          image: bistroFeatureKitchenPass
        },
        {
          id: 'bar-ritual',
          label: 'Bar Ritual',
          description: 'Marble bar glows with amethyst gradients, coupe silhouettes, and perfumed smoke.',
          image: bistroFeatureBarSurface
        },
        {
          id: 'salon-table',
          label: 'Salon Table',
          description: 'Velvet booths, linen drape, and graphite menus anchored by warm brass.',
          image: bistroFeatureCornerBooth
        }
      ],
      settings: [
        { id: 'corner-booth', label: 'Velvet Corner Booths', image: bistroFeatureCornerBooth },
        { id: 'table-setting', label: 'Salon Table Setting', image: bistroFeatureTableSetting },
        { id: 'wine-sculpt', label: 'Wine Service', image: bistroFeatureWineService },
        { id: 'bar-surface', label: 'Obsidian Bar', image: bistroFeatureBarSurface }
      ],
      elements: [
        {
          id: 'shadow-menu',
          label: 'Shadow Menu Atelier',
          description: 'Hand-inked menus layered over textured paper, clipped with brass numbering.',
          image: bistroDetailMenuPaper
        },
        {
          id: 'cutlery',
          label: 'Charcoal Cutlery Sets',
          description: 'Custom matte cutlery resting on obsidian stones beside each course.',
          image: bistroDetailCutlery
        },
        {
          id: 'linen-lab',
          label: 'Linen Lab',
          description: 'Storm-grey linens pressed with tonal piping and stitched monograms.',
          image: bistroDetailLinen
        },
        {
          id: 'candle-smoke',
          label: 'Candle Smoke Ritual',
          description: 'Whispered smoke columns scenting the room between courses.',
          image: bistroDetailCandleSmoke
        }
      ],
      gallery: [
        bistroFeatureBarSurface,
        bistroFeatureCornerBooth,
        bistroFeatureKitchenPass,
        bistroFeatureTableSetting,
        bistroFeatureWineService,
        bistroHeroExteriorNight
      ],
      pricingFeature: bistroFeatureTableSetting,
      pricingShots: [
        {
          id: 'midnight-flight',
          label: 'Midnight Flight',
          description: 'Trio of smoke-layered pours presented with synchronized lighting.',
          image: bistroFeatureWineService
        },
        {
          id: 'chef-line',
          label: 'Chef’s Line',
          description: 'Kitchen pass reveals each course with torchlight and whisper service.',
          image: bistroFeatureKitchenPass
        },
        {
          id: 'velvet-booth',
          label: 'Velvet Booth',
          description: 'Corner seating staged with candle towers and stoneware stemware.',
          image: bistroFeatureCornerBooth
        }
      ],
      textures: {
        soft: bistroDetailLinen,
        deep: bistroDetailWoodSurface,
        grain: bistroDetailGlassReflection
      }
    },
    highlights: [
      {
        id: 'obsidian-menu',
        title: 'Obsidian Menu',
        body: 'Six-course charcoal scripts pairing embered seafood, chilled smoke, and cellar pairings.'
      },
      {
        id: 'sommelier-theater',
        title: 'Sommelier Theater',
        body: 'Synchronized decanting, perfumed plume pours, and tableside story cues each hour.'
      },
      {
        id: 'afterhours-gallery',
        title: 'After Hours Gallery',
        body: 'Guests drift through a rotating corridor of glass, linen, and flicker-lit installations.'
      }
    ]
  }
];

export const defaultBrandId = brands[0].id;
