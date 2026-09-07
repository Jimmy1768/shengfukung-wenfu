import { categoryLabels, priceList, readinessLabels } from './priceList.js';

const tierSummary = (tier) => ({
  id: tier.id,
  category: 'enterprise_tier',
  categoryLabel: categoryLabels.enterprise_tier,
  icon: tier.icon,
  readiness: 'ready',
  readinessLabel: readinessLabels.ready,
  priceMode: 'setup_plus_monthly',
  setupTWD: tier.setupTWD,
  monthlyTWD: tier.monthlyMinimumTWD,
  monthlyMinimumLabel: tier.monthlyMinimumLabel,
  copy: {
    name: `${tier.tierLabel}: ${tier.title}`,
    summary: tier.summary
  }
});

const tierDetail = (tier) => ({
  ...tier,
  category: 'enterprise_tier',
  categoryLabel: categoryLabels.enterprise_tier,
  readiness: 'ready',
  readinessLabel: readinessLabels.ready,
  priceMode: 'setup_plus_monthly',
  typicalClients: tier.bestFit
});

export const pricingContent = {
  overview: {
    headline: 'SourceGrid Enterprise Pricing',
    subhead:
      'Cumulative website, dashboard, and app packages for companies that need SourceGrid to build and operate their business surfaces.',
    intro:
      'Tier prices are cumulative. Add-ons are grouped by the tier they extend, and monthly care is priced separately from setup.',
    note: priceList.currencyNote
  },
  valueHighlights: priceList.valueHighlights,
  packages: priceList.tiers.map(tierSummary),
  packageDetails: priceList.tiers.map(tierDetail),
  tierAddonGroups: priceList.tierAddonGroups,
  appRelayAddons: priceList.appRelayAddons,
  serviceTiers: priceList.serviceTiers,
  discovery: priceList.discovery,
  addons: priceList.tierAddonGroups.flatMap((group) => group.addons),
  maintenance: priceList.serviceTiers,
  readinessLabels,
  categoryLabels
};

export { categoryLabels, priceList, readinessLabels };
