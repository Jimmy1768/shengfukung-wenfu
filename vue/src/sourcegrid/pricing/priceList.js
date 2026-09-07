export const priceList = {
  currencyNote:
    'Enterprise pricing is TWD-first. Tier prices are cumulative package prices, not incremental layer prices.',
  valueHighlights: [
    {
      id: 'tier-1-website',
      title: 'Tier 1',
      body: 'A complete 6-8 page public website for a company that needs a credible online presence.',
      hover:
        'Best when the company needs a clean public surface, contact flow, and managed hosting without login or workflow software.'
    },
    {
      id: 'tier-2-dashboard-console',
      title: 'Tier 2',
      body: 'Tier 1 plus login, guest/admin dashboards, records, and a managed business console.',
      hover:
        'Best when the company needs a real web app surface for staff and customers, not only a marketing site.'
    },
    {
      id: 'tier-3-expo-app',
      title: 'Tier 3',
      body: 'Tier 2 plus an iOS/Android mobile app connected to the same SourceGrid server and account model.',
      hover:
        'Best when the main customer interaction belongs on iOS/Android and app release support is part of the scope.'
    }
  ],
  tiers: [
    {
      id: 'tier-1-website',
      tierLabel: 'Tier 1',
      icon: '1',
      title: '6-8 Page Website',
      tagline: 'Public company site',
      setupTWD: 45000,
      monthlyMinimumTWD: 2500,
      monthlyMinimumLabel: 'Minimal or Standard care',
      dependencyNote: 'Standalone public website package.',
      summary:
        'For companies that need a professional public website, contact path, and managed deployment without login or custom workflow software.',
      included: [
        '6-8 public pages such as home, about, services, pricing, contact, and support pages.',
        'Mobile-first responsive layout for phone and desktop visitors.',
        'Contact form or contact links routed to the client.',
        'Basic SEO metadata, clean page titles, and shareable page structure.',
        'Domain connection support after the client purchases their own domain.',
        'SourceGrid-managed deployment, hosting setup, and baseline backup path.'
      ],
      bestFit: [
        'Local service companies and consultants.',
        'Small companies that need a durable online presence.',
        'Clients that do not yet need login, records, dashboards, or app-store work.'
      ]
    },
    {
      id: 'tier-2-dashboard-console',
      tierLabel: 'Tier 2',
      icon: '2',
      title: 'Login + Guest/Admin Dashboards',
      tagline: 'Website plus business console',
      setupTWD: 180000,
      monthlyMinimumTWD: 8000,
      monthlyMinimumLabel: 'Standard care minimum',
      dependencyNote: 'Includes everything in Tier 1.',
      summary:
        'For companies that need an actual web application surface: customer login, staff dashboard, admin console, records, and managed workflow state.',
      included: [
        'Everything in Tier 1.',
        'Account/login system for approved user roles.',
        'Guest or customer dashboard for the approved workflow.',
        'Admin/staff console for records and operational state.',
        'Basic data model, role review, and permission review.',
        'Approved notification or email flow where needed.',
        'SourceGrid-managed server functionality for the approved workflow.'
      ],
      bestFit: [
        'Companies that need customers or staff to log in.',
        'Service businesses with bookings, registrations, records, or internal workflows.',
        'Clients that need a managed operating surface, not just public pages.'
      ]
    },
    {
      id: 'tier-3-expo-app',
      tierLabel: 'Tier 3',
      icon: '3',
      title: 'iOS/Android Mobile App',
      tagline: 'Website, console, and mobile app',
      setupTWD: 450000,
      monthlyMinimumTWD: 8000,
      monthlyMinimumLabel: 'Standard care minimum',
      dependencyNote: 'Includes everything in Tier 1 and Tier 2.',
      summary:
        'For companies that need a mobile app surface attached to the same SourceGrid server, account model, and managed dashboard.',
      included: [
        'Everything in Tier 1 and Tier 2.',
        'iOS/Android mobile app connected to the same SourceGrid server.',
        'Mobile login flow using the approved account model.',
        'Mobile screens for the approved guest or customer workflow.',
        'Mobile-safe data connection and testing on target devices.',
        'App Store and Google Play release support when approved.',
        'No new backend beyond the approved Tier 2 server unless separately quoted.'
      ],
      bestFit: [
        'Companies whose customers need repeated mobile access.',
        'Products where notifications, mobile access, or app-store presence matter.',
        'Clients ready for higher maintenance and release-management overhead.'
      ]
    }
  ],
  serviceTiers: [
    {
      id: 'minimal-care',
      title: 'Minimal',
      appliesTo: 'Tier 1 only',
      monthlyTWD: 2500,
      summary:
        'Hosting, uptime checks, backups, and critical fixes only. No urgent work expectation.'
    },
    {
      id: 'standard-care',
      title: 'Standard',
      appliesTo: 'Tier 1, Tier 2, Tier 3',
      monthlyTWD: 8000,
      summary:
        'Hosting, monitoring, backups, maintenance, reasonable response, small updates, and normal support. Required for Tier 2+.'
    },
    {
      id: 'emergency-build-mode',
      title: 'Emergency / Build Mode',
      appliesTo: 'Any tier',
      monthlyTWD: 30000,
      summary:
        'Priority/rush work, faster response, active building, overtime, or paused-other-work support.'
    }
  ],
  tierAddonGroups: [
    {
      id: 'tier-1-website-addons',
      title: 'Website Add-Ons',
      appliesTo: 'Tier 1 and above',
      summary:
        'Public-site enhancements that do not require a full login/dashboard system.',
      addons: [
        { id: 'extra-page', title: 'Extra page', setupLabel: 'NT$2,000 / page' },
        {
          id: 'multilingual-version',
          title: 'Multilingual version',
          setupLabel: 'NT$12,000 / language',
          monthlyLabel: 'NT$1,000 / language'
        },
        { id: 'copywriting-rewrite', title: 'Copywriting / rewrite pass', setupTWD: 8000 },
        {
          id: 'photo-image-generation',
          title: 'Photo/image generation or asset cleanup',
          setupTWD: 6000
        },
        { id: 'blog-news-admin', title: 'Blog/news admin surface', setupTWD: 15000, monthlyTWD: 1000 },
        { id: 'advanced-seo', title: 'Advanced SEO pass', setupTWD: 8000 },
        { id: 'analytics-setup', title: 'Analytics setup', setupTWD: 4000 },
        { id: 'extra-contact-form', title: 'Extra contact form', setupTWD: 3000 },
        { id: 'dns-domain-support', title: 'DNS/domain connection support', setupLabel: 'Included' }
      ]
    },
    {
      id: 'tier-2-dashboard-addons',
      title: 'Dashboard / Console Add-Ons',
      appliesTo: 'Tier 2 and Tier 3',
      summary:
        'Business workflow modules that extend the authenticated web app and staff console.',
      addons: [
        { id: 'booking-reservation', title: 'Booking / reservation system', setupTWD: 35000, monthlyTWD: 3000 },
        { id: 'rental-inventory', title: 'Rental inventory system', setupTWD: 35000, monthlyTWD: 3000 },
        { id: 'registration-system', title: 'Registration system', setupTWD: 25000, monthlyTWD: 2000 },
        { id: 'class-program-scheduling', title: 'Class / program scheduling', setupTWD: 30000, monthlyTWD: 3000 },
        { id: 'membership-account-tiers', title: 'Membership / account tiers', setupTWD: 25000, monthlyTWD: 2000 },
        { id: 'payment-rail-integration', title: 'Payment rail integration', setupTWD: 35000, monthlyTWD: 3000 },
        { id: 'data-import', title: 'Data import', setupTWD: 10000 },
        { id: 'extra-user-role', title: 'Extra user role', setupLabel: 'NT$8,000 / role' },
        { id: 'complex-permissions', title: 'Complex permissions', setupTWD: 20000, monthlyTWD: 2000 },
        { id: 'multi-location-support', title: 'Multi-location support', setupTWD: 35000, monthlyTWD: 4000 },
        { id: 'staff-workflow', title: 'Staff workflow', setupTWD: 25000, monthlyTWD: 2000 },
        { id: 'care-dependent-records', title: 'Care/dependent records', setupTWD: 60000, monthlyTWD: 6000 },
        { id: 'third-party-api', title: 'Third-party service integration', setupTWD: 25000, monthlyTWD: 2000 },
        { id: 'reporting-export', title: 'Reporting/export tools', setupTWD: 15000, monthlyTWD: 1000 }
      ]
    },
    {
      id: 'tier-3-app-addons',
      title: 'Tier 3 App-Specific Add-Ons',
      appliesTo: 'Tier 3',
      summary:
        'Mobile-specific features and release work that add app-store, device, or platform risk.',
      addons: [
        { id: 'push-notifications', title: 'Push notifications', setupTWD: 18000, monthlyTWD: 1500 },
        { id: 'offline-mode', title: 'Offline mode', setupTWD: 55000, monthlyTWD: 5000 },
        { id: 'camera-media-upload', title: 'Camera/media upload', setupTWD: 20000, monthlyTWD: 2000 },
        { id: 'map-gps-location', title: 'Map/GPS/location features', setupTWD: 25000, monthlyTWD: 2000 },
        { id: 'mobile-chat', title: 'Mobile chat/messaging', setupTWD: 35000, monthlyTWD: 3000 },
        { id: 'payment-iap-flow', title: 'Payment/IAP flow', setupTWD: 55000, monthlyTWD: 5000 },
        { id: 'app-onboarding', title: 'App-specific onboarding', setupTWD: 15000 },
        {
          id: 'store-compliance-heavy',
          title: 'App Store / Google Play compliance-heavy features',
          setupTWD: 45000,
          monthlyTWD: 4000
        },
        { id: 'device-platform-qa', title: 'Extra device/platform testing', setupTWD: 8000 },
        { id: 'release-management', title: 'Extra release management', setupLabel: 'NT$10,000 / release' }
      ]
    }
  ],
  appRelayAddons: [
    {
      id: 'embedded-website-assistant',
      title: 'Embedded website assistant',
      setupTWD: 25000,
      monthlyLabel: 'NT$3,000 + usage'
    },
    {
      id: 'authenticated-dashboard-assistant',
      title: 'Authenticated dashboard assistant',
      setupTWD: 35000,
      monthlyLabel: 'NT$5,000 + usage'
    },
    {
      id: 'app-assistant',
      title: 'App assistant',
      setupTWD: 40000,
      monthlyLabel: 'NT$5,000 + usage'
    },
    {
      id: 'messenger-assistant',
      title: 'LINE / WhatsApp / Messenger assistant',
      setupLabel: 'NT$35,000 / channel',
      monthlyLabel: 'NT$5,000 / channel + usage'
    },
    {
      id: 'source-material-cleanup',
      title: 'Extra source-material cleanup/import',
      setupTWD: 10000
    },
    {
      id: 'extra-enabled-language',
      title: 'Extra enabled language',
      setupLabel: 'NT$12,000 / language',
      monthlyLabel: 'NT$1,000 / language'
    },
    {
      id: 'higher-runtime-usage',
      title: 'Higher runtime/usage allowance',
      monthlyLabel: 'Quoted'
    }
  ],
  discovery: {
    id: 'discovery-custom-scope',
    title: 'Discovery / Custom Scope',
    setupTWD: 9500,
    summary:
      'Use paid discovery before quoting unclear workflows, unusual data sensitivity, many roles, integrations, migrations, or compliance exposure.'
  }
};

export const readinessLabels = {
  ready: 'Ready',
  case_by_case: 'Case by case'
};

export const categoryLabels = {
  enterprise_tier: 'Enterprise tier',
  tier_addon: 'Tier add-on',
  apprelay_addon: 'AppRelay add-on',
  service_care: 'Monthly care'
};
