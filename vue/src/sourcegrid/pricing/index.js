import { categoryLabels, priceList, readinessLabels } from './priceList.js';

const packageSummary = (offering) => ({
  id: offering.id,
  category: offering.category,
  categoryLabel: categoryLabels[offering.category] || offering.category,
  icon: offering.icon,
  readiness: offering.readiness,
  priceMode: offering.priceMode,
  priceLabel: offering.priceLabel,
  setupUSD: offering.setupUSD,
  monthlyUSD: offering.monthlyUSD,
  setupTWD: offering.setupTWD,
  monthlyTWD: offering.monthlyTWD,
  copy: {
    name: offering.title,
    summary: offering.summary
  }
});

const packageDetail = (offering) => ({
  id: offering.id,
  category: offering.category,
  categoryLabel: categoryLabels[offering.category] || offering.category,
  icon: offering.icon,
  readiness: offering.readiness,
  readinessLabel: readinessLabels[offering.readiness] || offering.readiness,
  priceMode: offering.priceMode,
  priceLabel: offering.priceLabel,
  setupUSD: offering.setupUSD,
  monthlyUSD: offering.monthlyUSD,
  setupTWD: offering.setupTWD,
  monthlyTWD: offering.monthlyTWD,
  title: offering.title,
  tagline: offering.tagline,
  summary: offering.summary,
  included: offering.included,
  typicalClients: offering.typicalClients,
  hoverNote: offering.hoverNote
});

export const pricingContent = {
  overview: {
    headline: 'SourceGrid Platform Access',
    subhead:
      'Free funnels, paid marketplace layers, and tenant workflow systems. Clients do not buy a custom app by default; they onboard into a SourceGrid ecosystem.',
    intro: '',
    note: priceList.currencyNote
  },
  valueHighlights: [
    {
      id: 'dojomate-free-funnel',
      title: 'Free Funnel',
      body: 'DojoMate stays free so martial arts adoption can compound.',
      hover:
        'Revenue comes later through Source Combatives, optional productivity tools, and ecosystem services.'
    },
    {
      id: 'templemate-platform',
      title: 'Free Public Site',
      body: 'TempleMate keeps the public website live and charges for operational workflows.',
      hover:
        'If delinquent, registration/business workflows freeze while the public marketing surface remains online.'
    },
    {
      id: 'hostel-hotel-bookings',
      title: 'Vertical Pilots',
      body: 'Hotel, rental, and nursing-home workflows become reusable platform modules.',
      hover:
        'These are realistic near-term builds after Operator-Kit stabilizes, but they should be sold as pilots first.'
    }
  ],
  packages: priceList.offerings.map(packageSummary),
  packageDetails: priceList.offerings.map(packageDetail),
  addons: priceList.addons,
  maintenance: priceList.maintenance,
  readinessLabels,
  categoryLabels
};

export { categoryLabels, priceList, readinessLabels };
