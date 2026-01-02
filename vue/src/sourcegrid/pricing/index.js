export const pricingContent = {
  overview: {
    headline: 'SourceGrid Labs Packages',
    subhead: 'Fixed-price websites, business systems, and mobile apps built for small companies that want clear deliverables.',
    intro: '',
    note: 'All packages are fixed-price. Your cost does not increase if implementation requires extra technical work on our side.'
  },
  valueHighlights: [
    {
      id: 'small-website',
      title: 'Small Website',
      body: '6–8 pages, mobile-friendly, contact form, basic admin.',
      hover:
        'Perfect when you need a credible online front door without custom systems. Includes a clean marketing site, SEO setup, and basic CMS.'
    },
    {
      id: 'business-system',
      title: 'Business System',
      body: 'Website plus one online system module with login + dashboard.',
      hover:
        'Great for boutique hospitality or rentals needing guest + staff portals with bookings, dashboards, and payments handled in one place.'
    },
    {
      id: 'mobile-suite',
      title: 'Mobile App Suite',
      body: 'iOS and Android app plus backend system and website.',
      hover:
        'Branded iOS/Android app, backend, and web experience so customers interact via mobile while staff run the same data in the admin.'
    }
  ],
  packages: [
    {
      id: 'small-website',
      icon: '🌐',
      priceUSD: 4000,
      priceTWD: 126000,
      copy: {
        name: 'Small Website',
        summary: '6–8 pages, mobile-friendly, contact form, basic admin.'
      }
    },
    {
      id: 'business-system',
      icon: '⚙️',
      priceUSD: 15000,
      priceTWD: 472000,
      copy: {
        name: 'Business System',
        summary: 'Website plus online system (login, dashboard, one core module).'
      }
    },
    {
      id: 'mobile-suite',
      icon: '📱',
      priceUSD: 30000,
      priceTWD: 944000,
      copy: {
        name: 'Mobile App Suite',
        summary: 'iOS and Android app, backend system, and website.'
      }
    }
  ],
  packageDetails: [
    {
      id: 'small-website',
      icon: '🌐',
      title: 'Small Website',
      tagline: 'Typical scope',
      priceUSD: 4000,
      priceTWD: 126000,
      summary:
        'A clean, professional website for small businesses that want a credible online presence and a simple way for customers to get in touch.',
      included: [
        '6–8 page website (home, about, services, pricing, contact, optional blog/news).',
        'Mobile-friendly design.',
        'Contact form that sends enquiries to your email.',
        'Basic SEO setup (titles, descriptions, clean URLs).',
        'Admin login to edit text and images.',
        'Hosting setup and deployment.'
      ],
      typicalClients: [
        'Cafés, restaurants, and retail shops.',
        'Consultants, coaches, and tutors.',
        'Local services such as repair, cleaning, or personal care.'
      ],
      hoverNote: 'Ideal when you just need a credible online front door with no custom systems.'
    },
    {
      id: 'business-system',
      icon: '⚙️',
      title: 'Business System',
      tagline: 'Website + online system',
      priceUSD: 15000,
      priceTWD: 472000,
      summary:
        'For businesses that need more than a website—an online system that supports bookings, rentals, or simple internal workflows so staff and customers can work through one platform.',
      included: [
        'Everything in the Small Website package.',
        'Customer login area.',
        'Staff dashboard to review and manage activity.',
        'One core system module (booking, rental, or workflow tool).',
        'Online payment handling for major cards and supported local methods.',
        'Automatic email confirmations and basic notifications.',
        'Simple data export to spreadsheets (CSV/Excel).'
      ],
      typicalClients: [
        'Small hotels and hostels.',
        'Rental shops for cars, bikes, or equipment.',
        'Clinics, salons, or providers that rely on scheduled appointments.'
      ],
      hoverNote: 'Perfect for boutique hospitality or rentals that need guests and staff inside the same portal.'
    },
    {
      id: 'mobile-suite',
      icon: '📱',
      title: 'Mobile App Suite',
      tagline: 'App + backend + website',
      priceUSD: 30000,
      priceTWD: 944000,
      summary:
        'For businesses that want their own branded mobile app on iOS and Android, connected to a reliable backend system and website.',
      included: [
        'Everything in the Business System package.',
        'Branded mobile app for iOS and Android (single codebase).',
        'Customer login and profile management in the app.',
        'Push notifications for key events (bookings, updates, reminders).',
        'In-app booking, ordering, or other selected core actions.',
        'App Store and Google Play submission handling.'
      ],
      typicalClients: [
        'Delivery or logistics services.',
        'Loyalty or membership-based businesses.',
        'Organisations that want customers to interact primarily via mobile.'
      ],
      hoverNote: 'Best when you need branded apps plus the backend and website to keep everything in sync.'
    }
  ],
  addons: [
    { id: 'online-booking', priceUSD: 6000, priceTWD: 189000 },
    { id: 'rental-system', priceUSD: 5000, priceTWD: 157000 },
    { id: 'payment-integration', priceUSD: 1000, priceTWD: 31000 },
    { id: 'email-automations', priceUSD: 800, priceTWD: 25000 },
    { id: 'real-time-chat', priceUSD: 2000, priceTWD: 63000 },
    { id: 'multi-language', priceUSD: 1000, priceTWD: 31000 },
    { id: 'forum-system', priceUSD: 4000, priceTWD: 126000 }
  ],
  maintenance: [
    { id: 'basic', priceUSD: 200, priceTWD: 6000 },
    { id: 'standard', priceUSD: 500, priceTWD: 16000 },
    { id: 'premium', priceUSD: 1500, priceTWD: 47000 }
  ]
};
